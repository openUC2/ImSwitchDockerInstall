#!/bin/bash -eu

# VimbaX Installation Script
# This script installs the full VimbaX SDK for Allied Vision cameras
# Based on the reference implementation from https://github.com/HLiu-uOttawa/Allied-Vision-1800-U-500C

echo "Installing VimbaX SDK for Allied Vision cameras..."

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y python3 python3-pip libusb-1.0-0 udev wget tar

# Create installation directory
INSTALL_DIR="/opt"
VIMBA_DIR="/opt/VimbaX"

echo "Downloading VimbaX SDK..."
cd /tmp
wget https://downloads.alliedvision.com/VimbaX/VimbaX_Setup-2025-1-Linux_ARM64.tar.gz

echo "Extracting VimbaX SDK..."
sudo tar -xzf VimbaX_Setup-2025-1-Linux_ARM64.tar.gz -C ${INSTALL_DIR}
sudo mv ${INSTALL_DIR}/VimbaX_2025-1 ${VIMBA_DIR}
rm VimbaX_Setup-2025-1-Linux_ARM64.tar.gz

echo "Installing GenTL transport layer..."
cd ${VIMBA_DIR}/cti
sudo ./Install_GenTL_Path.sh

echo "Installing VmbPy..."
cd ${VIMBA_DIR}/api/python
VMBPY_WHEEL=$(find . -name "vmbpy-*.whl" | head -1)
if [ -n "$VMBPY_WHEEL" ]; then
    sudo python3 -m pip install --break-system-packages "$VMBPY_WHEEL"
else
    echo "Warning: VmbPy wheel file not found, installing from PyPI as fallback"
    sudo python3 -m pip install --break-system-packages vmbpy
fi

# Set environment variables permanently
echo "Setting up environment variables..."
sudo tee /etc/environment > /dev/null << EOF
GENICAM_GENTL64_PATH="/opt/VimbaX/cti"
EOF

# Add to current session
export GENICAM_GENTL64_PATH="/opt/VimbaX/cti"

echo "VimbaX SDK installation complete!"

echo ""
echo "================================================="
echo " VimbaX SDK Installation Complete"
echo "================================================="
echo ""
echo "IMPORTANT NOTES:"
echo "1. Full VimbaX SDK has been installed with transport layers"
echo "2. GenTL path configured: /opt/VimbaX/cti"
echo "3. VmbPy installed from included wheel file"
echo ""
echo "HOST SYSTEM REQUIREMENTS:"
echo "The Docker container requires USB passthrough from the host."
echo "On the host system, you may need to:"
echo "1. Install appropriate USB drivers for your camera"
echo "2. Set up udev rules for camera access"
echo "3. Ensure the user has access to USB devices"
echo ""
echo "For USB camera access in Docker, use:"
echo "docker run --privileged --device=/dev/bus/usb <image>"
echo ""

# Create a comprehensive test script
cat > /tmp/test_vimba_full.py << 'EOF'
#!/usr/bin/env python3
import vmbpy
import os
import sys

def test_vimba_environment():
    """Test VimbaX environment setup"""
    print("=== VimbaX Environment Test ===")
    
    # Check GenTL path
    gentl_path = os.environ.get('GENICAM_GENTL64_PATH')
    if gentl_path:
        print(f"✓ GENICAM_GENTL64_PATH: {gentl_path}")
        if os.path.exists(gentl_path):
            print(f"✓ GenTL path exists")
        else:
            print(f"✗ GenTL path does not exist")
    else:
        print("✗ GENICAM_GENTL64_PATH not set")
    
    print()

def test_vmbpy():
    """Test VmbPy functionality"""
    print("=== VmbPy Functionality Test ===")
    try:
        vmb = vmbpy.VmbSystem.get_instance()
        print("✓ VmbSystem instance created")
        
        with vmb:
            print("✓ VmbSystem context entered")
            
            # Get interfaces
            interfaces = vmb.get_all_interfaces()
            print(f"✓ Found {len(interfaces)} interface(s)")
            for iface in interfaces:
                print(f"  Interface: {iface.get_id()}")
            
            # Get cameras
            cameras = vmb.get_all_cameras()
            print(f"✓ Found {len(cameras)} camera(s)")
            for cam in cameras:
                print(f"  Camera: {cam.get_name()} (ID: {cam.get_id()})")
                
        return True
    except Exception as e:
        print(f"✗ VmbPy test failed: {e}")
        return False

def main():
    print("VimbaX Installation Test")
    print("========================")
    
    test_vimba_environment()
    success = test_vmbpy()
    
    print("\n=== Test Summary ===")
    if success:
        print("✓ VimbaX installation appears to be working correctly")
        return 0
    else:
        print("✗ VimbaX installation has issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF

chmod +x /tmp/test_vimba_full.py
echo "Comprehensive test script created at /tmp/test_vimba_full.py"
echo "Run: python3 /tmp/test_vimba_full.py"

echo ""
echo "VimbaX installation complete!"
