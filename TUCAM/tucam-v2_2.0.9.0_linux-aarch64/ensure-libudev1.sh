#!/bin/sh
# Ensure libudev.so.1 is available via system libudev1 (never bundled with tucam-v2).
# Sourced by install.sh or run from deb postinst.
# Exit 0 if OK; exit 1 with message if missing and cannot install.
set -e

log() { echo "==> $*"; }
err() { echo "ERROR: $*" >&2; }

libdir_udev_present() {
    if command -v ldconfig >/dev/null 2>&1; then
        if ldconfig -p 2>/dev/null | grep -q 'libudev\.so\.1'; then
            return 0
        fi
    fi
    for p in \
        /lib/aarch64-linux-gnu/libudev.so.1 \
        /usr/lib/aarch64-linux-gnu/libudev.so.1 \
        /lib/arm-linux-gnueabihf/libudev.so.1 \
        /usr/lib/arm-linux-gnueabihf/libudev.so.1 \
        /lib/x86_64-linux-gnu/libudev.so.1 \
        /usr/lib/x86_64-linux-gnu/libudev.so.1 \
        /lib/libudev.so.1 \
        /usr/lib/libudev.so.1
    do
        if [ -e "$p" ]; then
            return 0
        fi
    done
    return 1
}

dpkg_libudev_installed() {
    dpkg -s libudev1 >/dev/null 2>&1
}

try_apt_install_libudev1() {
    if ! command -v apt-get >/dev/null 2>&1; then
        return 1
    fi
    log "Installing system package libudev1 (apt)..."
    export DEBIAN_FRONTEND=noninteractive
    if apt-get install -y --no-install-recommends libudev1; then
        return 0
    fi
    return 1
}

ensure_libudev1() {
    if libdir_udev_present; then
        log "libudev.so.1 OK (system libudev1)"
        return 0
    fi

    if dpkg_libudev_installed; then
        log "libudev1 package installed; refreshing ldconfig..."
        if command -v ldconfig >/dev/null 2>&1; then
            ldconfig
        fi
        if libdir_udev_present; then
            return 0
        fi
    fi

    if try_apt_install_libudev1; then
        if command -v ldconfig >/dev/null 2>&1; then
            ldconfig
        fi
        if libdir_udev_present; then
            log "libudev1 installed via apt"
            return 0
        fi
    fi

    err "libudev.so.1 is required but not found."
    err "  - Online:  sudo apt install libudev1"
    err "  - Offline: install libudev1_*.deb for your OS/arch first, then re-run install."
    err "  - Verify:  ldconfig -p | grep libudev"
    return 1
}

# When executed directly (deb postinst), not only sourced.
if [ "${1:-}" = "--run" ] || [ "$(basename "$0" 2>/dev/null)" = "ensure-libudev1.sh" ] && [ -z "${TUCAM_ENSURE_LIBUDEV_SOURCED:-}" ]; then
    ensure_libudev1
fi
