TUCam v2 — Linux aarch64 release
================================

Package:  tucam-v2
Version:  2.0.9.0
Arch:     aarch64 (Raspberry Pi / arm64 Linux)

Contents
--------
  lib/                    libTUCam.so.1.0.0 (file) + libTUCam.so.1 / .so (symlinks)
                          Installed to /usr/lib/aarch64-linux-gnu/
  etc/tucam/              tuusb.conf (Cypress USB enumeration)
  etc/udev/...            50-tuusb.rules (MODE 0666; reload on install)
  include/tucam/          TUCamApi.h, TUDefine.h
  examples/               save_image
  install.sh / uninstall.sh

Dependencies (target system) — required
-----------------------------------------
  libudev1                Runtime USB (system library; NOT bundled in this package)

  install.sh checks for libudev.so.1 before installing:
    - Already present (typical Raspberry Pi OS): continues
    - Missing + apt + network: runs apt-get install -y libudev1
    - Missing + offline: stops with error (install libudev1_*.deb manually first)

Optional: g++ (rebuild examples from source)

Library layout (release policy)
-----------------------------
  - Only one real file: libTUCam.so.1.0.0
  - libTUCam.so.1 and libTUCam.so are symbolic links
  - Do NOT copy libudev into /lib or /usr/lib; use libudev1 from apt

If you previously installed an old SDK that copied libudev.so* or libTUCam.so*
into /lib or /usr/lib, run install.sh again (it removes those legacy paths) or
remove them manually, then: sudo ldconfig

Install from tarball
--------------------
  tar -xzf tucam-v2_2.0.9.0_linux-aarch64.tar.gz
  cd tucam-v2_2.0.9.0_linux-aarch64
  sudo ./install.sh
  (install.sh runs ensure-libudev1.sh: detect / apt / fail offline)

Uninstall (tarball install only)
--------------------------------
  sudo ./uninstall.sh

Install from .deb
-----------------
  sudo dpkg -i tucam-v2_2.0.9.0-1_arm64.deb
  (Depends: libudev1; postinst also runs ensure-libudev1.sh)
  sudo apt remove tucam-v2

Verify
------
  ls -l /usr/lib/aarch64-linux-gnu/libTUCam.so*
  # libTUCam.so.1 -> libTUCam.so.1.0.0 , only .1.0.0 is a regular file
  ldconfig -p | grep libTUCam
  ldconfig -p | grep libudev
  ls -l /etc/tucam/tuusb.conf
  ls -l /etc/udev/rules.d/50-tuusb.rules

USB access without sudo
-----------------------
  50-tuusb.rules sets MODE 0666. After install, replug the camera or run:
  sudo udevadm control --reload-rules && sudo udevadm trigger
  Adding users to group "users" is usually not required with current rules.

Run save_image example
----------------------
  /usr/share/tucam-v2/examples/save_image/save_image

  cd /usr/share/tucam-v2/examples/save_image && make && ./save_image

Build notes (developers)
------------------------
  Cross-build SDK:     scripts/rpi-cross-env/build-v2-rpi.sh
  Cross-build example: examples/save_image — make -f Makefile.cross
  Pack release:        scripts/rpi-cross-env/pack-v2-rpi.sh
