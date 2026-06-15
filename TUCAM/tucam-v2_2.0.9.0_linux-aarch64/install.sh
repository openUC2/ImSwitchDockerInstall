#!/usr/bin/env bash
# Install TUCam v2 from release tarball (libraries + config + headers + examples).
#
# Library policy:
#   - Only libTUCam.so.1.0.0 is installed as a regular file; .so / .so.1 are symlinks.
#   - libudev comes from the system package libudev1 (never bundled).
#
# Usage: sudo ./install.sh
# Optional: DESTDIR=/tmp/stage ./install.sh  (packaging verification)
set -euo pipefail

PKG_NAME="tucam-v2"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTDIR="${DESTDIR:-}"
MANIFEST_DIR="${DESTDIR}/var/lib/${PKG_NAME}"
MANIFEST="${MANIFEST_DIR}/install.manifest"
INCLUDE_REL="usr/include/tucam"
EXAMPLES_REL="usr/share/${PKG_NAME}/examples"
TUCAM_SONAME_REAL="libTUCam.so.1.0.0"

if [[ "$(id -u)" -ne 0 && -z "${DESTDIR}" ]]; then
    echo "ERROR: run as root: sudo $0" >&2
    exit 1
fi

pick_lib_dir() {
    if [[ "$(uname -m 2>/dev/null || echo unknown)" == "aarch64" ]]; then
        if [[ -d "${DESTDIR}/usr/lib/aarch64-linux-gnu" ]] || [[ -z "${DESTDIR}" && -d /usr/lib/aarch64-linux-gnu ]]; then
            echo "usr/lib/aarch64-linux-gnu"
            return
        fi
    fi
    echo "usr/lib"
}

LIB_REL="$(pick_lib_dir)"
LIB_ABS="${DESTDIR}/${LIB_REL}"
INCLUDE_ABS="${DESTDIR}/${INCLUDE_REL}"

log() { echo "==> $*"; }
warn() { echo "WARN: $*" >&2; }

install_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "${dst}")"
    install -m 0644 "${src}" "${dst}"
    echo "${dst}" >>"${MANIFEST}"
}

install_exec() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "${dst}")"
    install -m 0755 "${src}" "${dst}"
    echo "${dst}" >>"${MANIFEST}"
}

manifest_remove_path() {
    local path="$1"
    [[ -f "${MANIFEST}" ]] || return 0
    local tmp
    tmp="$(mktemp)"
    grep -Fxv "${path}" "${MANIFEST}" >"${tmp}" 2>/dev/null || true
    mv "${tmp}" "${MANIFEST}"
}

# Remove mistaken legacy copies (bundled libudev, flat libTUCam under /lib or /usr/lib).
remove_legacy_library_copies() {
    local dir
    for dir in \
        "${DESTDIR}/lib" \
        "${DESTDIR}/usr/lib" \
        ; do
        [[ -d "${dir}" ]] || continue
        shopt -s nullglob
        local f
        for f in \
            "${dir}"/libudev.so* \
            "${dir}"/libTUCam.so* \
            ; do
            [[ -e "${f}" ]] || continue
            log "Remove legacy library copy: ${f}"
            rm -f "${f}"
            manifest_remove_path "${f}"
        done
        shopt -u nullglob
    done
}

install_tucam_libraries() {
    local src_real="${ROOT}/lib/${TUCAM_SONAME_REAL}"
    if [[ ! -f "${src_real}" ]]; then
        echo "ERROR: missing ${src_real} in release package" >&2
        exit 1
    fi
    if [[ -e "${ROOT}/lib/libTUCam.so.1" ]] && [[ ! -L "${ROOT}/lib/libTUCam.so.1" ]]; then
        echo "ERROR: package lib/libTUCam.so.1 must be a symlink, not a regular file" >&2
        exit 1
    fi

    mkdir -p "${LIB_ABS}"
    shopt -s nullglob
    local f
    for f in "${LIB_ABS}"/libTUCam.so*; do
        rm -f "${f}"
        manifest_remove_path "${f}"
    done
    shopt -u nullglob

    install_exec "${src_real}" "${LIB_ABS}/${TUCAM_SONAME_REAL}"
    (cd "${LIB_ABS}" && ln -sf "${TUCAM_SONAME_REAL}" libTUCam.so.1.0)
    echo "${LIB_ABS}/libTUCam.so.1.0" >>"${MANIFEST}"
    (cd "${LIB_ABS}" && ln -sf "${TUCAM_SONAME_REAL}" libTUCam.so.1)
    echo "${LIB_ABS}/libTUCam.so.1" >>"${MANIFEST}"
    (cd "${LIB_ABS}" && ln -sf libTUCam.so.1 libTUCam.so)
    echo "${LIB_ABS}/libTUCam.so" >>"${MANIFEST}"

    shopt -s nullglob
    for f in "${ROOT}/lib"/lib*_gcc49_v3_2.so*; do
        [[ -e "${f}" ]] || continue
        local base="$(basename "${f}")"
        if [[ -L "${f}" ]]; then
            (cd "${LIB_ABS}" && ln -sf "$(readlink "${f}")" "${base}")
        else
            install_exec "${f}" "${LIB_ABS}/${base}"
        fi
        echo "${LIB_ABS}/${base}" >>"${MANIFEST}"
    done
    shopt -u nullglob
}

verify_tucam_library_layout() {
    local real="${LIB_ABS}/${TUCAM_SONAME_REAL}"
    if [[ ! -f "${real}" ]]; then
        echo "ERROR: ${real} not installed" >&2
        exit 1
    fi
    local link
    for link in libTUCam.so.1.0 libTUCam.so.1 libTUCam.so; do
        if [[ ! -L "${LIB_ABS}/${link}" ]]; then
            echo "ERROR: ${LIB_ABS}/${link} must be a symbolic link" >&2
            exit 1
        fi
    done
    if [[ -e "${LIB_ABS}/libTUCam.so.1" ]] && [[ ! -L "${LIB_ABS}/libTUCam.so.1" ]]; then
        echo "ERROR: ${LIB_ABS}/libTUCam.so.1 must not be a regular file" >&2
        exit 1
    fi
}

ensure_system_libudev() {
    if [[ -n "${DESTDIR}" ]]; then
        return 0
    fi
    local helper="${ROOT}/ensure-libudev1.sh"
    if [[ ! -f "${helper}" ]]; then
        echo "ERROR: missing ${helper}" >&2
        exit 1
    fi
    # shellcheck source=ensure-libudev1.sh
    export TUCAM_ENSURE_LIBUDEV_SOURCED=1
    # shellcheck disable=SC1090
    . "${helper}"
    ensure_libudev1
}

log "Installing ${PKG_NAME} from ${ROOT}"
mkdir -p "${MANIFEST_DIR}"
: >"${MANIFEST}"

if [[ -z "${DESTDIR}" ]]; then
    ensure_system_libudev
fi

if [[ ! -d "${ROOT}/lib" ]]; then
    echo "ERROR: ${ROOT}/lib not found" >&2
    exit 1
fi

remove_legacy_library_copies
install_tucam_libraries
verify_tucam_library_layout

# Public API headers
if [[ -d "${ROOT}/include/tucam" ]]; then
    mkdir -p "${INCLUDE_ABS}"
    for f in "${ROOT}/include/tucam"/*.h; do
        [[ -f "${f}" ]] || continue
        install_file "${f}" "${INCLUDE_ABS}/$(basename "${f}")"
    done
fi

install_file "${ROOT}/etc/tucam/tuusb.conf" "${DESTDIR}/etc/tucam/tuusb.conf"
install_file "${ROOT}/etc/udev/rules.d/50-tuusb.rules" "${DESTDIR}/etc/udev/rules.d/50-tuusb.rules"

if [[ -d "${ROOT}/examples" ]]; then
    for exdir in "${ROOT}/examples"/*; do
        [[ -d "${exdir}" ]] || continue
        name="$(basename "${exdir}")"
        dest_base="${DESTDIR}/${EXAMPLES_REL}/${name}"
        for rel in README.md Makefile main.cpp; do
            if [[ -f "${exdir}/${rel}" ]]; then
                install_file "${exdir}/${rel}" "${dest_base}/${rel}"
            fi
        done
        if [[ -f "${exdir}/${name}" ]]; then
            install_exec "${exdir}/${name}" "${dest_base}/${name}"
        fi
    done
fi

if [[ -z "${DESTDIR}" ]]; then
    if command -v udevadm >/dev/null 2>&1; then
        log "Reload udev rules"
        udevadm control --reload-rules
        udevadm trigger
    fi
    if command -v ldconfig >/dev/null 2>&1; then
        ldconfig
    fi
fi

log "Done. Manifest: ${MANIFEST}"
log "Libraries: ${LIB_ABS} (${TUCAM_SONAME_REAL} + symlinks; libudev from system libudev1)"
log "Headers:   ${INCLUDE_ABS}"
log "Examples:  ${DESTDIR}/${EXAMPLES_REL}/"

# install tucam-v2_2.0.9.0_linux-aarch64.deb  in ROOT
# 1. make executable in ROOT 
chmod +x "${ROOT}/tucam-v2_2.0.9.0_linux-aarch64.deb"
# 2. copy to /tmp
cp "${ROOT}/tucam-v2_2.0.9.0_linux-aarch64.deb" /tmp/   
sudo dpkg -i /tmp/tucam-v2_2.0.9.0_linux-aarch64.deb
rm -f /tmp/tucam-v2_2.0.9.0_linux-aarch64.deb