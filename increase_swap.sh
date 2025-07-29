#!/usr/bin/env bash
# enlarge-swap.sh  — grow the Raspberry Pi swapfile (dphys-swapfile)

set -euo pipefail
SIZE_MB="${1:-2048}"          # default 2 GiB; run: sudo ./enlarge-swap.sh 3072  for 3 GiB

need_root() { [ "$(id -u)" -eq 0 ] && return; echo "Run as root: sudo $0 $*"; exit 1; }
need_root "$@"

echo "▶︎ ensuring dphys-swapfile is present"
if ! command -v dphys-swapfile >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y dphys-swapfile
fi

echo "▶︎ turning off current swap"
systemctl stop dphys-swapfile 2>/dev/null || true
dphys-swapfile swapoff        2>/dev/null || true

echo "▶︎ setting CONF_SWAPSIZE=$SIZE_MB"
conf=/etc/dphys-swapfile
if grep -q '^CONF_SWAPSIZE=' "$conf"; then
  sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$SIZE_MB/" "$conf"
else
  echo "CONF_SWAPSIZE=$SIZE_MB" >> "$conf"
fi

echo "▶︎ regenerating swapfile"
dphys-swapfile setup
systemctl start dphys-swapfile

echo "▶︎ done:"
free -h
swapon --show
