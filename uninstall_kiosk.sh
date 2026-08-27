#!/usr/bin/env bash
# Remove the Chromium kiosk installed by install_kiosk.sh and give tty1 back
# to a normal console login.
#
# To only switch it off (keeping everything installed) use instead:
#   sudo kioskctl disable
set -euo pipefail
exec "$(dirname "$(readlink -f "$0")")/install_kiosk.sh" uninstall
