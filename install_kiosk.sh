#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

KIOSK_USER="${KIOSK_USER:-pi}"
PORT="${PORT:-8001}"
SCALE="${SCALE:-0.7}"
TARGET_URL="${TARGET_URL:-http://127.0.0.1:${PORT}/}"
PING_URL="${PING_URL:-http://127.0.0.1:${PORT}/}"

XORG_CONF="/etc/X11/xorg.conf.d/99-kiosk-kms.conf"
UNIT_FILE="/etc/systemd/system/kiosk.service"
SESSION_SH="/usr/local/bin/kiosk-session.sh"
LOADING_HTML="/usr/local/share/kiosk/loading.html"

log(){ echo "[kiosk] $*"; }

pick_connected_card() {
  local f st dir card
  # look at ALL connectors, not only HDMI
  for f in /sys/class/drm/card*-*/status; do
    [[ -f "$f" ]] || continue
    st="$(cat "$f" 2>/dev/null || true)"
    [[ "$st" == "connected" ]] || continue
    dir="$(basename "$(dirname "$f")")"   
    if [[ "$dir" =~ ^card([0-9]+)- ]]; then
      card="/dev/dri/card${BASH_REMATCH[1]}"
      echo "$card|$dir"
      return 0
    fi
  done
  # fallback
  [[ -e /dev/dri/card0 ]] && echo "/dev/dri/card0|fallback-card0" && return 0
  [[ -e /dev/dri/card1 ]] && echo "/dev/dri/card1|fallback-card1" && return 0
  return 1
}

[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
id -u "$KIOSK_USER" >/dev/null 2>&1 || { log "User $KIOSK_USER missing"; exit 1; }

log "Ensure base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  xserver-xorg xinit openbox x11-xserver-utils unclutter curl \
  xserver-xorg-input-libinput libinput-tools xinput evtest \
  chromium chromium-browser || true

# avoid fbdev fallback weirdness
apt-get purge -y xserver-xorg-video-fbdev xserver-xorg-video-fbturbo || true

CHOICE="$(pick_connected_card)"
KMSDEV="${CHOICE%%|*}"
CONN="${CHOICE##*|}"
log "Using display connector: ${CONN}  ->  ${KMSDEV}"

mkdir -p /etc/X11/xorg.conf.d
cat >"$XORG_CONF" <<EOF
Section "Device"
  Identifier "KMS"
  Driver "modesetting"
  Option "PrimaryGPU" "true"
  Option "kmsdev" "${KMSDEV}"
EndSection
EOF

# keep tty1 free for X
systemctl disable --now getty@tty1.service 2>/dev/null || true
systemctl mask getty@tty1.service 2>/dev/null || true

# minimal local loading page (redirects when server ready)
install -d -m 0755 /usr/local/share/kiosk
cat >"$LOADING_HTML" <<HTML
<!doctype html><html><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Loading…</title>
<style>
html,body{height:100%;margin:0;background:#0b0d10;color:#e6e6e6;font-family:system-ui,Segoe UI,Roboto,Arial}
.wrap{height:100%;display:flex;align-items:center;justify-content:center}
.card{width:min(760px,92vw);padding:28px;border-radius:16px;background:#12161c}
.bar{height:12px;border-radius:999px;background:#0b0d10;overflow:hidden;border:1px solid rgba(255,255,255,.08)}
.fill{height:100%;width:40%;border-radius:999px;background:#e6e6e6;opacity:.85;animation:slide 1.1s ease-in-out infinite}
@keyframes slide{0%{transform:translateX(-120%)}100%{transform:translateX(320%)}}
code{opacity:.8}
</style></head><body>
<div class="wrap"><div class="card">
<div style="font-size:18px;margin-bottom:10px;">Starting…</div>
<div style="font-size:14px;opacity:.7;margin-bottom:14px;">Waiting for the openUC2 Microscope</div>
<div class="bar"><div class="fill"></div></div>
</div></div>
<script>
const pingUrl="${PING_URL}";
const go="${TARGET_URL}";
async function ping(){ try{ await fetch(pingUrl,{mode:"no-cors",cache:"no-store"}); location.href=go; }
catch(e){ setTimeout(ping,300); } }
ping();
</script></body></html>
HTML

# chromium command
CHROME_BIN=""
command -v chromium >/dev/null 2>&1 && CHROME_BIN="chromium"
[[ -z "$CHROME_BIN" ]] && command -v chromium-browser >/dev/null 2>&1 && CHROME_BIN="chromium-browser"
[[ -n "$CHROME_BIN" ]] || { log "chromium not found"; exit 1; }

cat >"$SESSION_SH" <<SH
#!/usr/bin/env bash
set -euo pipefail
xset s off
xset -dpms
xset s noblank
openbox-session &>/dev/null &
unclutter -idle 0.1 -root &
exec ${CHROME_BIN} \\
  --kiosk "file://${LOADING_HTML}" \\
  --no-first-run --no-default-browser-check \\
  --noerrdialogs --disable-infobars \\
  --force-device-scale-factor=${SCALE} \\
  --touch-events=enabled \\
  --enable-smooth-scrolling \\
  --enable-features=OverlayScrollbar,TouchpadAndWheelScrollLatching,ImpulseScrollAnimations \\
  --user-data-dir=/tmp/chrome-profile \\
  --disk-cache-dir=/tmp/chrome-cache
SH
chmod +x "$SESSION_SH"

DRM_DEVICE_UNIT="dev-dri-$(basename "$KMSDEV").device"

cat >"$UNIT_FILE" <<UNIT
[Unit]
Description=Chromium Kiosk (${PING_URL})
After=multi-user.target systemd-udev-settle.service systemd-logind.service ${DRM_DEVICE_UNIT}
Wants=systemd-udev-settle.service
Requires=${DRM_DEVICE_UNIT}
Conflicts=getty@tty1.service
StartLimitIntervalSec=0

[Service]
Type=simple
User=${KIOSK_USER}
PAMName=login
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal
Environment=HOME=/home/${KIOSK_USER}
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/${KIOSK_USER}/.Xauthority

PermissionsStartOnly=true
ExecStartPre=/usr/bin/udevadm settle --timeout=30
ExecStartPre=/bin/sh -c 'for i in \$(seq 1 80); do /usr/bin/chvt 1 || true; [ "\$(fgconsole 2>/dev/null)" = "1" ] && exit 0; sleep 0.25; done; exit 0'
ExecStartPre=/bin/sh -c 'for i in \$(seq 1 120); do [ -e ${KMSDEV} ] && break; sleep 0.25; done; exit 0'
ExecStart=/usr/bin/xinit ${SESSION_SH} -- :0 -nolisten tcp vt1 -keeptty
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable kiosk.service
systemctl reset-failed kiosk.service 2>/dev/null || true
systemctl restart kiosk.service

log "Done. If still black, check:"
log "  tail -200 /home/${KIOSK_USER}/.local/share/xorg/Xorg.0.log"
