#!/usr/bin/env bash
#
# install_kiosk.sh -- Chromium kiosk for ImSwitch on Raspberry Pi (Pi 4 / Pi 5, Bookworm / Trixie)
#
# Boots straight into a fullscreen Chromium showing the ImSwitch web UI that is
# served by Docker.  While the container is still starting (30-60 s) a local
# "loading" page is shown; the session script polls the server and switches over
# as soon as it answers.
#
# Usage:
#   sudo ./install_kiosk.sh [install]   install + enable + start the kiosk
#   sudo ./install_kiosk.sh disable     no Chromium on next boot (console login instead)
#   sudo ./install_kiosk.sh enable      re-enable the kiosk
#   sudo ./install_kiosk.sh status      show what is going on
#   sudo ./install_kiosk.sh uninstall   remove everything this script installed
#
# Install-time overrides (become the defaults in /etc/default/kiosk):
#   KIOSK_USER=pi PORT=8001 SCALE=0.7 ROTATE=auto TARGET_URL=... sudo ./install_kiosk.sh
#
# After installation everything is configured in /etc/default/kiosk -- edit that
# file and `sudo systemctl restart kiosk` instead of re-running the installer.
#
set -euo pipefail
shopt -s nullglob

KIOSK_USER="${KIOSK_USER:-pi}"
PORT="${PORT:-80}"
SCALE="${SCALE:-1.0}"
ROTATE="${ROTATE:-auto}"
TARGET_URL="${TARGET_URL:-http://127.0.0.1:${PORT}/imswitch/ui/index.html#/mobile}"
PING_URL="${PING_URL:-${TARGET_URL}}"

UNIT_FILE="/etc/systemd/system/kiosk.service"
DEFAULTS="/etc/default/kiosk"
PREPARE_SH="/usr/local/bin/kiosk-prepare.sh"
SESSION_SH="/usr/local/bin/kiosk-session.sh"
KIOSKCTL="/usr/local/bin/kioskctl"
SHARE_DIR="/usr/local/share/kiosk"
XORG_CONF="/etc/X11/xorg.conf.d/99-kiosk-kms.conf"
STATE_DIR="/var/lib/kiosk"
DISABLE_FLAG="/etc/kiosk.disabled"
BOOT_DISABLE_FLAG="/boot/firmware/kiosk.disabled"

log(){ echo "[kiosk] $*"; }
die(){ echo "[kiosk] ERROR: $*" >&2; exit 1; }
need_root(){ [[ $EUID -eq 0 ]] || die "run with sudo"; }

# ---------------------------------------------------------------- subcommands

do_status() {
  local en ac
  en="$(systemctl is-enabled kiosk.service 2>/dev/null || true)"; en="${en:-not-installed}"
  ac="$(systemctl is-active  kiosk.service 2>/dev/null || true)"; ac="${ac:-unknown}"
  echo "kiosk.service : ${en} / ${ac}"
  [[ -e "$DISABLE_FLAG" ]]      && echo "disable flag  : $DISABLE_FLAG present"      || true
  [[ -e "$BOOT_DISABLE_FLAG" ]] && echo "disable flag  : $BOOT_DISABLE_FLAG present" || true
  echo "getty@tty1    : $(systemctl is-enabled getty@tty1.service 2>/dev/null || true)"
  if [[ -f "$DEFAULTS" ]]; then echo "--- $DEFAULTS ---"; grep -vE '^\s*(#|$)' "$DEFAULTS" || true; fi
  local url code
  url="$(. "$DEFAULTS" 2>/dev/null; echo "${PING_URL:-}")"
  url="${url:-$PING_URL}"
  if [[ -n "$url" ]]; then
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 4 "$url" 2>/dev/null)" || true
    echo "server probe  : ${url} -> HTTP ${code:-000}"
  fi
}

do_disable() {
  need_root
  install -d -m 0755 "$STATE_DIR"
  touch "$DISABLE_FLAG"
  systemctl stop kiosk.service 2>/dev/null || true
  systemctl disable kiosk.service 2>/dev/null || true
  # give the console back
  systemctl unmask getty@tty1.service 2>/dev/null || true
  systemctl enable --now getty@tty1.service 2>/dev/null || true
  log "kiosk disabled -- Chromium will NOT start on boot. Re-enable with:"
  log "  sudo kioskctl enable"
}

do_enable() {
  need_root
  rm -f "$DISABLE_FLAG" "$BOOT_DISABLE_FLAG"
  systemctl disable --now getty@tty1.service 2>/dev/null || true
  systemctl mask getty@tty1.service 2>/dev/null || true
  touch "$STATE_DIR/masked-getty" 2>/dev/null || true
  systemctl unmask kiosk.service 2>/dev/null || true
  systemctl enable kiosk.service
  systemctl reset-failed kiosk.service 2>/dev/null || true
  systemctl restart kiosk.service
  log "kiosk enabled and started"
}

do_uninstall() {
  need_root
  systemctl stop kiosk.service 2>/dev/null || true
  systemctl disable kiosk.service 2>/dev/null || true
  rm -f "$UNIT_FILE" "$PREPARE_SH" "$SESSION_SH" "$KIOSKCTL" "$XORG_CONF" "$DISABLE_FLAG" "$BOOT_DISABLE_FLAG"
  rm -f /etc/X11/xorg.conf.d/99-kiosk-touch.conf
  rm -rf "$SHARE_DIR" "$STATE_DIR"
  systemctl daemon-reload
  systemctl unmask getty@tty1.service 2>/dev/null || true
  systemctl enable --now getty@tty1.service 2>/dev/null || true
  log "kiosk removed ($DEFAULTS kept -- delete it manually if you want)"
}

# ------------------------------------------------------------------- install

do_install() {
  need_root
  id -u "$KIOSK_USER" >/dev/null 2>&1 || die "user '$KIOSK_USER' does not exist"

  log "Installing packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update

  # Chromium is called 'chromium' on Raspberry Pi OS Bookworm/Trixie and
  # 'chromium-browser' on older images. Pick whichever actually exists --
  # asking for both makes apt fail and install nothing at all.
  local CHROME_PKG=""
  if apt-cache show chromium >/dev/null 2>&1; then
    CHROME_PKG="chromium"
  elif apt-cache show chromium-browser >/dev/null 2>&1; then
    CHROME_PKG="chromium-browser"
  fi
  [[ -n "$CHROME_PKG" ]] || die "no chromium package available in apt"
  log "  chromium package: $CHROME_PKG"

  # These must succeed -- no '|| true' masking a broken install.
  apt-get install -y --no-install-recommends \
    xserver-xorg xserver-xorg-core xinit x11-xserver-utils \
    xserver-xorg-input-libinput \
    openbox unclutter curl "$CHROME_PKG"

  # Nice to have, not fatal if missing.
  apt-get install -y --no-install-recommends libinput-tools xinput evtest || true
  # Legacy fbdev drivers make Xorg pick the wrong device on Pi 4/5.
  apt-get purge -y xserver-xorg-video-fbdev xserver-xorg-video-fbturbo 2>/dev/null || true

  local CHROME_BIN=""
  if command -v chromium >/dev/null 2>&1; then
    CHROME_BIN="$(command -v chromium)"
  elif command -v chromium-browser >/dev/null 2>&1; then
    CHROME_BIN="$(command -v chromium-browser)"
  fi
  [[ -n "$CHROME_BIN" ]] || die "chromium binary not found after install"

  # Xorg must be allowed to start from a systemd unit rather than a login shell.
  install -d -m 0755 /etc/X11
  cat >/etc/X11/Xwrapper.config <<'EOF'
allowed_users=anybody
needs_root_rights=yes
EOF

  # DRM / input access for the kiosk user.
  usermod -aG tty,video,render,input "$KIOSK_USER" || true

  install -d -m 0755 "$SHARE_DIR" "$STATE_DIR" /etc/X11/xorg.conf.d

  # ---------------------------------------------------------- /etc/default/kiosk
  if [[ -f "$DEFAULTS" ]]; then
    log "Keeping existing $DEFAULTS"
  else
    log "Writing $DEFAULTS"
    cat >"$DEFAULTS" <<EOF
# Configuration for the ImSwitch Chromium kiosk (kiosk.service).
# Edit, then:  sudo systemctl restart kiosk

# Page to show once the server answers.
TARGET_URL="${TARGET_URL}"

# URL that is polled to decide "the server is up". Any HTTP response counts.
PING_URL="${PING_URL}"

# Chromium zoom. 1.0 = native. Lower = more content on a high-DPI panel.
SCALE="${SCALE}"

# Screen/touch rotation: auto | normal | left | right | inverted
#   auto = leave landscape panels alone, turn portrait panels (e.g. the
#          Raspberry Pi Touch Display 2, native 720x1280) into landscape.
ROTATE="${ROTATE}"

# Chromium binary.
CHROME_BIN="${CHROME_BIN}"

# Restart the browser if the server stays unreachable this many seconds (0 = off).
WATCHDOG_TIMEOUT="60"

# Extra flags appended to the Chromium command line.
EXTRA_CHROME_FLAGS=""
EOF
  fi

  # ------------------------------------------------------------ prepare script
  log "Writing $PREPARE_SH"
  cat >"$PREPARE_SH" <<'EOF'
#!/usr/bin/env bash
# Runs as root before Xorg starts: find the display GPU, write the Xorg config,
# render the loading page and make sure we own tty1.
set -euo pipefail
shopt -s nullglob

XORG_CONF="/etc/X11/xorg.conf.d/99-kiosk-kms.conf"
LOADING_HTML="/usr/local/share/kiosk/loading.html"
PING_URL=""
# shellcheck disable=SC1091
[[ -f /etc/default/kiosk ]] && . /etc/default/kiosk || true

log(){ echo "[kiosk-prepare] $*" >&2; }

# A card is usable for display only if it exposes connectors. On a Pi 5
# /dev/dri/card0 is the render-only v3d node -- picking it makes Xorg fail.
# pick_display_card [strict]
#   strict -> only return a card that has a *connected* connector
pick_display_card() {
  local strict="${1:-}" card n dir best="" fallback=""
  for card in /sys/class/drm/card[0-9]*; do
    [[ -e "$card/device" ]] || continue
    n="${card##*/card}"; [[ "$n" =~ ^[0-9]+$ ]] || continue
    [[ -e "/dev/dri/card$n" ]] || continue
    for dir in /sys/class/drm/card${n}-*; do
      [[ -f "$dir/status" ]] || continue
      case "$(basename "$dir")" in *Writeback*) continue;; esac
      fallback="${fallback:-/dev/dri/card$n}"
      if [[ "$(cat "$dir/status" 2>/dev/null)" == "connected" ]]; then
        log "connected connector: $(basename "$dir")"
        best="/dev/dri/card$n"; break 2
      fi
    done
  done
  [[ -n "$best" ]] && { echo "$best"; return 0; }
  [[ "$strict" == "strict" ]] && return 1
  [[ -n "$fallback" ]] && { echo "$fallback"; return 0; }
  return 1
}

/usr/bin/udevadm settle --timeout=30 || true

# Prefer a card that has a genuinely connected connector -- a DSI panel such as
# the Raspberry Pi Touch Display 2 can need a few seconds to be probed. After
# ~15 s accept any card that at least has connectors (never the render-only
# v3d node, which is /dev/dri/card0 on a Pi 5).
KMSDEV=""
for _ in $(seq 1 30); do
  if KMSDEV="$(pick_display_card strict)"; then break; fi
  sleep 0.5
done
if [[ -z "$KMSDEV" ]]; then
  log "no connected connector yet -- falling back to first display-capable card"
  KMSDEV="$(pick_display_card || true)"
fi
[[ -n "$KMSDEV" ]] || { log "no display-capable DRM device found"; exit 1; }
log "using $KMSDEV"

# Which connector actually carries the picture -- needed for the panel geometry.
CONN=""
for _d in /sys/class/drm/card*-*; do
  [[ -f "$_d/status" ]] || continue
  case "$(basename "$_d")" in *Writeback*) continue;; esac
  if [[ "$(cat "$_d/status" 2>/dev/null)" == "connected" ]]; then CONN="$_d"; break; fi
done

# ------------------------------------------------------------- touch panel
# The touch controller of the Touch Display 2 sits on the panel's I2C bus and
# only answers once the panel itself is powered. At boot the kernel frequently
# probes it first and it fails with -EREMOTEIO ("I2C communication failure:
# -121"); as that is not -EPROBE_DEFER the kernel never retries, so the
# touchscreen is simply absent -- no event node, no X device, no touch at all.
# We run after the panel is confirmed connected, so binding here succeeds.
rebind_touch() {
  local drv dev name
  for drv in /sys/bus/i2c/drivers/Goodix-TS /sys/bus/i2c/drivers/edt_ft5x06 \
             /sys/bus/i2c/drivers/ilitek_ts_i2c; do
    [[ -w "$drv/bind" ]] || continue
    for dev in /sys/bus/i2c/devices/*; do
      if [[ -e "$dev/driver" ]]; then continue; fi   # already bound
      name="$(cat "$dev/name" 2>/dev/null || true)"
      case "$name" in
        gt911|gt9271|GDIX*|ft5406|ft5x06|edt-ft5x06|ili251x|ILI*) ;;
        *) continue ;;
      esac
      if echo "${dev##*/}" > "$drv/bind" 2>/dev/null; then
        log "rebound touch controller ${dev##*/} ($name) -> ${drv##*/}"
      fi
    done
  done
  return 0
}
for _ in 1 2 3; do
  rebind_touch
  if grep -qi 'touchscreen' /proc/bus/input/devices 2>/dev/null; then break; fi
  sleep 1
done

# --------------------------------------------------------- touch rotation
# Applied by the X server itself when the device is added, so a touchscreen
# that only appears later (a slow probe, or the rebind above) still gets the
# correct mapping. The session script additionally sets it through xinput for
# devices that are already present.
TOUCH_CONF="/etc/X11/xorg.conf.d/99-kiosk-touch.conf"
ROT="${ROTATE:-auto}"
if [[ "$ROT" == "auto" ]]; then
  ROT="normal"
  if [[ -n "$CONN" ]]; then
    _mode="$(head -n1 "$CONN/modes" 2>/dev/null || true)"
    _w="${_mode%x*}"; _h="${_mode#*x}"
    if [[ "$_w" =~ ^[0-9]+$ && "$_h" =~ ^[0-9]+$ && "$_h" -gt "$_w" ]]; then ROT="right"; fi
  fi
fi
case "$ROT" in
  right)    MTX="0 1 0 -1 0 1 0 0 1" ;;
  left)     MTX="0 -1 1 1 0 0 0 0 1" ;;
  inverted) MTX="-1 0 1 0 -1 1 0 0 1" ;;
  *)        MTX="1 0 0 0 1 0 0 0 1" ;;
esac
log "touch rotation: $ROT (panel ${_mode:-?}, connector $(basename "${CONN:-none}"))"
cat >"$TOUCH_CONF" <<TEOF
Section "InputClass"
  Identifier "kiosk touch rotation"
  MatchIsTouchscreen "on"
  MatchDevicePath "/dev/input/event*"
  Option "TransformationMatrix" "${MTX}"
EndSection
TEOF

cat >"$XORG_CONF" <<XEOF
Section "Device"
  Identifier "KMS"
  Driver "modesetting"
  Option "PrimaryGPU" "true"
  Option "kmsdev" "${KMSDEV}"
EndSection
XEOF

# Loading page: purely local, no network calls (the session script does the
# polling), so it can never be blocked by browser network policy.
install -d -m 0755 "$(dirname "$LOADING_HTML")"
cat >"$LOADING_HTML" <<XEOF
<!doctype html><html><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Starting…</title>
<style>
html,body{height:100%;margin:0;background:#0b0d10;color:#e6e6e6;font-family:system-ui,Segoe UI,Roboto,Arial}
.wrap{height:100%;display:flex;align-items:center;justify-content:center}
.card{width:min(760px,92vw);padding:28px;border-radius:16px;background:#12161c}
.bar{height:12px;border-radius:999px;background:#0b0d10;overflow:hidden;border:1px solid rgba(255,255,255,.08)}
.fill{height:100%;width:40%;border-radius:999px;background:#e6e6e6;opacity:.85;animation:slide 1.1s ease-in-out infinite}
@keyframes slide{0%{transform:translateX(-120%)}100%{transform:translateX(320%)}}
.meta{font-size:13px;opacity:.55;margin-top:14px;font-variant-numeric:tabular-nums}
.hint{font-size:13px;opacity:0;margin-top:8px;color:#ffb27a;transition:opacity .4s}
</style></head><body>
<div class="wrap"><div class="card">
<div style="font-size:18px;margin-bottom:10px;">Starting…</div>
<div style="font-size:14px;opacity:.7;margin-bottom:14px;">Waiting for the openUC2 Microscope</div>
<div class="bar"><div class="fill"></div></div>
<div class="meta"><span id="t">0</span>s &nbsp;·&nbsp; ${PING_URL:-}</div>
<div class="hint" id="h">Still waiting. Check the Docker container:
<code>docker ps</code> / <code>journalctl -u kiosk -f</code></div>
</div></div>
<script>
let s=0;setInterval(()=>{s++;document.getElementById('t').textContent=s;
if(s>120)document.getElementById('h').style.opacity=1;},1000);
</script></body></html>
XEOF

# Make sure the kiosk lands on tty1.
for _ in $(seq 1 40); do
  /usr/bin/chvt 1 2>/dev/null || true
  [ "$(fgconsole 2>/dev/null)" = "1" ] && break
  sleep 0.25
done
exit 0
EOF
  chmod 0755 "$PREPARE_SH"

  # ------------------------------------------------------------ session script
  log "Writing $SESSION_SH"
  cat >"$SESSION_SH" <<'EOF'
#!/usr/bin/env bash
# Runs inside the X session as the kiosk user.
set -uo pipefail

TARGET_URL="http://127.0.0.1:80/"
PING_URL=""
SCALE="1.0"
ROTATE="auto"
CHROME_BIN="chromium"
WATCHDOG_TIMEOUT="60"
EXTRA_CHROME_FLAGS=""
[[ -f /etc/default/kiosk ]] && . /etc/default/kiosk
PING_URL="${PING_URL:-$TARGET_URL}"
LOADING_HTML="/usr/local/share/kiosk/loading.html"

log(){ echo "[kiosk-session] $*"; }

# ---- screen hygiene -------------------------------------------------------
xset s off; xset -dpms; xset s noblank
openbox --sm-disable &>/dev/null &
unclutter -idle 0.1 -root &>/dev/null &

# ---- rotation (Touch Display 2 is natively portrait 720x1280) --------------
apply_rotation() {
  local out geo w h rot="$ROTATE"
  out="$(xrandr --query 2>/dev/null | awk '/ connected/{print $1; exit}')" || return 0
  [[ -n "$out" ]] || return 0
  geo="$(xrandr --query 2>/dev/null | awk -v o="$out" '$1==o{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+x[0-9]+\+/){split($i,a,"+");print a[1];exit}}')"
  w="${geo%x*}"; h="${geo#*x}"
  if [[ "$rot" == "auto" ]]; then
    if [[ -n "$w" && -n "$h" && "$h" -gt "$w" ]]; then rot="right"; else rot="normal"; fi
  fi
  log "output=$out geometry=${geo:-?} rotate=$rot"
  xrandr --output "$out" --rotate "$rot" 2>/dev/null || return 0

  local m
  case "$rot" in
    normal)   m="1 0 0 0 1 0 0 0 1" ;;
    right)    m="0 1 0 -1 0 1 0 0 1" ;;
    left)     m="0 -1 1 1 0 0 0 0 1" ;;
    inverted) m="-1 0 1 0 -1 1 0 0 1" ;;
    *) return 0 ;;
  esac
  # Remap touch coordinates onto the rotated screen.
  #
  # Match by device ID, never by name: a touch panel can register as both a
  # pointer and a keyboard (the Goodix panel of the Touch Display 2 does), and
  # `xinput set-prop <name>` then refuses to act on the ambiguous name. Pick
  # touchscreens out by the "libinput Calibration Matrix" property rather than
  # grepping names, so no controller has to be known up front.
  #
  # Runs in the background: the panel is frequently not registered with X yet
  # when the session starts, and waiting for it must not delay the browser.
  command -v xinput >/dev/null 2>&1 || return 0
  ( id=""; n=0
    for _ in $(seq 1 60); do
      n=0
      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        xinput list-props "$id" 2>/dev/null | grep -q 'libinput Calibration Matrix' || continue
        n=$((n+1))
        if xinput set-prop "$id" "Coordinate Transformation Matrix" $m; then
          log "touch matrix ($rot) applied to id=$id '$(xinput list --name-only "$id" 2>/dev/null)'"
        else
          log "WARNING: failed to set touch matrix on id=$id"
        fi
      done < <(xinput list 2>/dev/null | sed -n 's/.*id=\([0-9]\+\)[[:space:]]*\[slave *pointer.*/\1/p')
      [[ "$n" -gt 0 ]] && break
      sleep 0.5
    done
    [[ "$n" -eq 0 ]] && log "no touchscreen found -- touch matrix not applied"
    true
  ) &
}
apply_rotation

# ---- is the ImSwitch server answering? ------------------------------------
server_up() {
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$PING_URL" 2>/dev/null)" || code="000"
  [[ -n "$code" && "$code" != "000" ]]
}

CHROME_COMMON=(
  --no-first-run --no-default-browser-check
  --noerrdialogs --disable-infobars
  --disable-session-crashed-bubble --disable-features=TranslateUI
  --check-for-update-interval=31536000
  --password-store=basic
  --force-device-scale-factor="${SCALE}"
  --touch-events=enabled
  --overscroll-history-navigation=0
  --enable-smooth-scrolling
  --enable-features=OverlayScrollbar,TouchpadAndWheelScrollLatching,ImpulseScrollAnimations
  --disk-cache-dir=/tmp/kiosk-cache
)
# shellcheck disable=SC2206
[[ -n "$EXTRA_CHROME_FLAGS" ]] && CHROME_COMMON+=($EXTRA_CHROME_FLAGS)

rm -rf /tmp/kiosk-profile /tmp/kiosk-loader-profile

# ---- phase 1: loading screen while Docker/ImSwitch comes up ---------------
if ! server_up; then
  log "server not up yet -- showing loading page"
  "$CHROME_BIN" --kiosk "file://${LOADING_HTML}" \
      --user-data-dir=/tmp/kiosk-loader-profile "${CHROME_COMMON[@]}" &>/dev/null &
  LOADER_PID=$!
  while ! server_up; do
    kill -0 "$LOADER_PID" 2>/dev/null || break
    sleep 1
  done
  log "server responded -- switching to ${TARGET_URL}"
  kill "$LOADER_PID" 2>/dev/null || true
  wait "$LOADER_PID" 2>/dev/null || true
fi

# ---- phase 2: the real UI --------------------------------------------------
"$CHROME_BIN" --kiosk "${TARGET_URL}" \
    --user-data-dir=/tmp/kiosk-profile "${CHROME_COMMON[@]}" &
CHROME_PID=$!

# ---- watchdog: if the server disappears for good, bounce the session ------
if [[ "${WATCHDOG_TIMEOUT:-0}" -gt 0 ]]; then
  ( down=0
    while kill -0 "$CHROME_PID" 2>/dev/null; do
      if server_up; then down=0; else down=$((down+5)); fi
      if [[ "$down" -ge "$WATCHDOG_TIMEOUT" ]]; then
        echo "[kiosk-session] server down for ${down}s -- restarting session"
        kill "$CHROME_PID" 2>/dev/null || true
        break
      fi
      sleep 5
    done ) &
fi

wait "$CHROME_PID"
EOF
  chmod 0755 "$SESSION_SH"

  # ---------------------------------------------------------------- kioskctl
  # Self-contained copy so enable/disable keep working even if the git
  # checkout this was run from is moved or deleted.
  log "Writing $KIOSKCTL"
  local SELF; SELF="$(readlink -f "$0")"
  if [[ "$SELF" != "$KIOSKCTL" ]]; then
    install -m 0755 "$SELF" "$KIOSKCTL"
  fi

  # ------------------------------------------------------------- systemd unit
  log "Writing $UNIT_FILE"
  cat >"$UNIT_FILE" <<EOF
[Unit]
Description=ImSwitch Chromium Kiosk
Documentation=file://${DEFAULTS}
After=multi-user.target systemd-logind.service systemd-user-sessions.service systemd-udev-settle.service docker.service
Wants=systemd-udev-settle.service
Conflicts=getty@tty1.service
# Two independent kill switches. Either file present -> unit is skipped
# cleanly at boot (no restart loop, no Chromium).
ConditionPathExists=!${DISABLE_FLAG}
ConditionPathExists=!${BOOT_DISABLE_FLAG}
StartLimitIntervalSec=0

[Service]
Type=simple
User=${KIOSK_USER}
PAMName=login
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal
EnvironmentFile=-${DEFAULTS}
Environment=HOME=/home/${KIOSK_USER}
Environment=DISPLAY=:0
ExecStartPre=+${PREPARE_SH}
ExecStart=/usr/bin/xinit ${SESSION_SH} -- :0 vt1 -keeptty -nolisten tcp
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  do_enable

  log ""
  log "Done."
  log "  URL        : ${TARGET_URL}"
  log "  config     : ${DEFAULTS}"
  log "  disable    : sudo kioskctl disable      (or: touch ${BOOT_DISABLE_FLAG})"
  log "  enable     : sudo kioskctl enable"
  log "  status     : kioskctl status"
  log "  logs       : journalctl -u kiosk -f"
  log "  Xorg log   : /home/${KIOSK_USER}/.local/share/xorg/Xorg.0.log"
}

# ---------------------------------------------------------------------- main

case "${1:-install}" in
  install)             do_install ;;
  enable)              do_enable ;;
  disable|off)         do_disable ;;
  status)              do_status ;;
  uninstall|remove)    do_uninstall ;;
  restart)             need_root; systemctl restart kiosk.service ;;
  logs)                journalctl -u kiosk -f ;;
  -h|--help|help)      sed -n '3,22p' "$0" | sed 's/^# \?//' ;;
  *) die "unknown command '$1' (install|enable|disable|status|restart|logs|uninstall)" ;;
esac
