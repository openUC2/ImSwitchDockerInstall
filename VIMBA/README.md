Allied Vision Alvium USB camera Dockerfile example (VimbaX)
===========================================================

This Docker example uses the **full VimbaX SDK** with **VmbPy** (the modern Python API), which is the successor to the legacy Vimba SDK and VimbaPython.

Based on the reference implementation from: https://github.com/HLiu-uOttawa/Allied-Vision-1800-U-500C

## VimbaX vs Legacy Vimba

- **VimbaX** is Allied Vision's latest SDK, fully GenICam compliant
- **VmbPy** is the new Python API that replaces VimbaPython
- Provides better performance, modern Python features, and improved reliability
- Full SDK includes transport layers (USB, GigE) and proper device drivers

## Requirements

### Host System Driver Installation

**IMPORTANT**: For USB cameras to work with Docker, you need to install VimbaX drivers on the host system.

1. **Download VimbaX SDK for your host architecture**:
   - ARM64 (Jetson, ARM Linux): [VimbaX_Setup-2025-1-Linux_ARM64.tar.gz](https://downloads.alliedvision.com/VimbaX/VimbaX_Setup-2025-1-Linux_ARM64.tar.gz)
   - x86_64 (Intel/AMD): Download from [alliedvision.com](https://www.alliedvision.com/en/products/software.html)

2. **Install on host system**:
   ```bash
   # Extract the SDK
   tar -xzf VimbaX_Setup-2025-1-Linux_ARM64.tar.gz
   cd VimbaX_2025-1
   
   # Install USB transport layer (required for USB cameras)
   cd VimbaUSBTL
   sudo ./Install.sh
   
   # Install udev rules
   sudo cp ../Tools/VimbaUSBTL/99-vimba.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

3. **Verify host installation**:
   ```bash
   # Check if camera is detected
   lsusb | grep -i allied
   # Should show something like: Bus 002 Device 003: ID 1ab2:0001 Allied Vision Technologies
   ```

### For Docker Usage
The Docker container includes the full VimbaX SDK with transport layers and VmbPy.

## Docker

```sh
cd VIMBA
sudo docker build -t alvium:vimbax .
```

#### Minimal working example
```sh
# USB passthrough is required for camera access
sudo docker run --init --privileged --device=/dev/bus/usb alvium:vimbax
# This runs the list_cameras.py script by default
```

#### Run with custom script
```sh
sudo docker run --init --privileged --device=/dev/bus/usb alvium:vimbax python your_script.py
```
                  
#### Interactive session
```sh
$ sudo docker run --init -it \
                  --privileged \
                  --device=/dev/bus/usb \
                  --entrypoint="/bin/bash" \
                  --rm \
                  alvium:vimbax
```

## USB Camera Detection

To check if your camera is properly detected:

1. **On host system**:
   ```bash
   lsusb
   # Look for Allied Vision device, e.g.:
   # Bus 002 Device 003: ID 1ab2:0001 Allied Vision Technologies
   ```

2. **In Docker container**:
   ```bash
   python3 /opt/vimba/list_cameras.py
   ```

## Usage Example

The included `list_cameras.py` shows how to use VmbPy with the full SDK:

```python
import vmbpy
import os

# VimbaX environment should be configured
print(f"GenTL path: {os.environ.get('GENICAM_GENTL64_PATH', 'Not set')}")

vmb = vmbpy.VmbSystem.get_instance()
with vmb:
    # List all interfaces (USB, GigE, etc.)
    interfaces = vmb.get_all_interfaces()
    print(f"Found {len(interfaces)} interface(s)")
    
    # List all cameras
    cams = vmb.get_all_cameras()
    print(f"Found {len(cams)} camera(s)")
    for cam in cams:
        print(f"Camera: {cam.get_name()} (ID: {cam.get_id()})")
```

## Architecture Support

This implementation supports:
- **ARM64** (Jetson devices, ARM-based systems)
- **x86_64** (Intel/AMD systems)

The Dockerfile automatically downloads the ARM64 version. For x86_64, update the download URL in the Dockerfile.

## Troubleshooting

### Common Issues

1. **"No cameras found"**:
   - Ensure VimbaX drivers are installed on host system
   - Check USB connection and device detection with `lsusb`
   - Verify Docker has USB device access (`--device=/dev/bus/usb`)

2. **Permission errors**:
   - Use `--privileged` flag with Docker
   - Check udev rules are installed on host

3. **Transport layer not found**:
   - Verify `GENICAM_GENTL64_PATH` is set correctly
   - Check that `/opt/VimbaX/cti` exists in container

## Migration from VimbaPython

If you have existing code using VimbaPython, note that VmbPy has some API differences:

- Import `vmbpy` instead of `vimba`
- Use `VmbSystem.get_instance()` instead of the old Vimba instance
- Context managers are required for proper resource management
- Feature access methods have changed

See the migration guide in the VimbaX SDK documentation for complete details.