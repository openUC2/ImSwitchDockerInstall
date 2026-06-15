#!/usr/bin/env bash
# Uninstall TUCam v2 installed via packaging/install.sh (uses install.manifest).
# Usage: sudo ./uninstall.sh
set -euo pipefail

PKG_NAME="tucam-v2"
DESTDIR="${DESTDIR:-}"
MANIFEST="${DESTDIR}/var/lib/${PKG_NAME}/install.manifest"

if [[ "$(id -u)" -ne 0 && -z "${DESTDIR}" ]]; then
    echo "ERROR: run as root: sudo $0" >&2
    exit 1
fi

if [[ ! -f "${MANIFEST}" ]]; then
    echo "ERROR: manifest not found: ${MANIFEST}" >&2
    echo "Nothing to uninstall (or installed via .deb: use apt remove tucam-v2)." >&2
    exit 1
fi

log() { echo "==> $*"; }

log "Removing files listed in ${MANIFEST}"
while IFS= read -r path || [[ -n "${path}" ]]; do
    [[ -z "${path}" ]] && continue
    if [[ -e "${path}" || -L "${path}" ]]; then
        rm -f "${path}"
        echo "  removed ${path}"
    fi
done <"${MANIFEST}"

rm -f "${MANIFEST}"
rmdir "${DESTDIR}/var/lib/${PKG_NAME}" 2>/dev/null || true

if [[ -z "${DESTDIR}" ]]; then
    if command -v udevadm >/dev/null 2>&1; then
        udevadm control --reload-rules
        udevadm trigger
    fi
    if command -v ldconfig >/dev/null 2>&1; then
        ldconfig
    fi
fi

log "Uninstall complete."
