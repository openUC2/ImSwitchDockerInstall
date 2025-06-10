#!/bin/bash -eu

# VimbaX Installation Script
# This script installs VmbPy (VimbaX Python API) instead of the legacy VimbaPython
# VimbaX is the successor to the legacy Vimba SDK

echo "Installing VimbaX (VmbPy) for Allied Vision cameras..."

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y python3 python3-pip libusb-1.0-0 udev wget

# Install VmbPy from PyPI - this includes the VmbC libraries
# We install with numpy and opencv extras for better integration
echo "Installing VmbPy from PyPI..."
sudo python3 -m pip install --break-system-packages vmbpy[numpy,opencv]

echo "VmbPy installation complete!"

# Note: VmbPy includes the VmbC libraries, but does NOT include transport layers
# For production use, you should install the full VimbaX SDK to get:
# - USB Transport Layer (for USB cameras)
# - GigE Transport Layer (for Gigabit Ethernet cameras)
# - Device drivers and udev rules

echo ""
echo "================================================="
echo " VmbPy (VimbaX Python API) Installation Complete"
echo "================================================="
echo ""
echo "IMPORTANT NOTES:"
echo "1. VmbPy has been installed with VmbC libraries included"
echo "2. For USB cameras: Install full VimbaX SDK for transport layers"
echo "3. For GigE cameras: Install full VimbaX SDK for transport layers"
echo ""
echo "To install full VimbaX SDK (recommended for production):"
echo "1. Download VimbaX SDK from:"
echo "   https://www.alliedvision.com/en/products/software.html"
echo "2. Extract and run the installer according to documentation"
echo ""
echo "Test your installation:"
echo "python3 -c \"import vmbpy; print('VmbPy installed successfully')\""
echo ""

# Create a simple test script
cat > /tmp/test_vmbpy.py << 'EOF'
#!/usr/bin/env python3
import vmbpy

def test_vmbpy():
    try:
        vmb = vmbpy.VmbSystem.get_instance()
        with vmb:
            cameras = vmb.get_all_cameras()
            print(f"VmbPy working! Found {len(cameras)} camera(s)")
            for cam in cameras:
                print(f"  Camera: {cam.get_name()} (ID: {cam.get_id()})")
        return True
    except Exception as e:
        print(f"VmbPy test failed: {e}")
        return False

if __name__ == "__main__":
    test_vmbpy()
EOF

chmod +x /tmp/test_vmbpy.py
echo "Test script created at /tmp/test_vmbpy.py"
echo "Run: python3 /tmp/test_vmbpy.py"

echo ""
echo "VimbaX installation complete!"
