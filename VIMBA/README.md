Allied Vision Alvium USB camera Dockerfile example (VimbaX)
===========================================================

This Docker example uses **VimbaX SDK** with **VmbPy** (the modern Python API), which is the successor to the legacy Vimba SDK and VimbaPython.

## VimbaX vs Legacy Vimba

- **VimbaX** is Allied Vision's latest SDK, fully GenICam compliant
- **VmbPy** is the new Python API that replaces VimbaPython
- Provides better performance, modern Python features, and improved reliability
- VmbPy can be installed directly from PyPI

## Requirements

### For Docker Usage
No additional requirements - VmbPy is installed automatically in the container.

### For Host System Installation
If you want to use Allied Vision cameras on your host system, you need to install the transport layers and device drivers. This can be done by:

1. **Option 1: Install full VimbaX SDK** (Recommended)
   - Download VimbaX SDK from [alliedvision.com/en/products/software.html](https://www.alliedvision.com/en/products/software.html)
   - This includes all transport layers (USB, GigE) and device drivers

2. **Option 2: Manual installation** (for specific transport layers only)
   - Install only the required transport layers from the VimbaX SDK
   - Set appropriate environment variables (see install_vimba.sh)

## Docker

```sh
cd VIMBA
sudo docker build -t alvium:vimbax .
```

#### Minimal working example
```sh
sudo docker run --init --privileged --rm alvium:vimbax
# This runs the list_cameras.py script by default
```

#### Run with custom script
```sh
sudo docker run --init --privileged --rm alvium:vimbax python your_script.py
```
                  
#### Interactive session
```sh
$ sudo docker run --init -it \
                  --privileged -v /dev/bus/usb:/dev/bus/usb \
                  --entrypoint="/bin/bash" \
                  --rm \
                  alvium:vimbax
```

## Usage Example

The included `list_cameras.py` shows how to use VmbPy:

```python
import vmbpy

vmb = vmbpy.VmbSystem.get_instance()
with vmb:
    cams = vmb.get_all_cameras()
    for cam in cams:
        print(cam)
```

## Migration from VimbaPython

If you have existing code using VimbaPython, note that VmbPy has some API differences:

- Import `vmbpy` instead of `vimba`
- Use `VmbSystem.get_instance()` instead of the old Vimba instance
- Context managers are required for proper resource management
- Feature access methods have changed

See the migration guide in the VimbaX SDK documentation for complete details.