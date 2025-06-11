#!/usr/bin/env python3
"""
VimbaX Camera List Example

This script demonstrates how to list Allied Vision cameras using VmbPy (VimbaX Python API).
Based on the reference implementation and VimbaX examples.
"""

import vmbpy
import os
import sys


def print_environment_info():
    """Print VimbaX environment information"""
    print("=== VimbaX Environment ===")
    gentl_path = os.environ.get('GENICAM_GENTL64_PATH')
    if gentl_path:
        print(f"GenTL Path: {gentl_path}")
        if os.path.exists(gentl_path):
            print("✓ GenTL path exists")
        else:
            print("✗ GenTL path does not exist")
    else:
        print("✗ GENICAM_GENTL64_PATH not set")
    print()


def list_interfaces(vmb_system):
    """List all available transport layer interfaces"""
    print("=== Transport Layer Interfaces ===")
    try:
        interfaces = vmb_system.get_all_interfaces()
        print(f"Found {len(interfaces)} interface(s):")
        
        for idx, interface in enumerate(interfaces):
            print(f"  [{idx}] Interface ID: {interface.get_id()}")
            try:
                interface_type = interface.get_type()
                print(f"      Type: {interface_type}")
            except:
                print(f"      Type: Unknown")
        
        if not interfaces:
            print("  No interfaces found - check transport layer installation")
        
    except Exception as e:
        print(f"Error listing interfaces: {e}")
    print()


def main():
    """Main function to demonstrate VimbaX camera listing"""
    print("//////////////////////////////////")
    print("/// VmbPy List Cameras Example ///")
    print("//////////////////////////////////")
    print()
    
    # Print environment information
    print_environment_info()
    
    try:
        # Get VmbSystem instance
        vmb = vmbpy.VmbSystem.get_instance()
        print("✓ VmbSystem instance created")
        
        # Enter VmbSystem context
        with vmb:
            print("✓ VmbSystem context entered")
            print()
            
            # List interfaces first
            list_interfaces(vmb)
            
            # Get all available cameras
            cameras = vmb.get_all_cameras()
            
            print(f"Cameras found: {len(cameras)}")
            
            if not cameras:
                print("No cameras found.")
                print("Possible reasons:")
                print("- No Allied Vision cameras connected")
                print("- Camera drivers not installed on host system")
                print("- USB permissions issue")
                print("- Transport layer not properly configured")
                return 0
            
            for i, camera in enumerate(cameras):
                print(f"/// Camera Name   : {camera.get_name()}")
                print(f"/// Model Name    : {camera.get_model()}")
                print(f"/// Camera ID     : {camera.get_id()}")
                
                try:
                    serial = camera.get_serial()
                    print(f"/// Serial Number : {serial}")
                except:
                    print(f"/// Serial Number : N/A")
                
                try:
                    interface_id = camera.get_parent_interface_id()
                    print(f"/// Interface ID  : {interface_id}")
                except:
                    print(f"/// Interface ID  : Unknown")
                
                # Try to get some basic information
                try:
                    with camera:
                        try:
                            width = camera.get_feature_by_name('Width')
                            height = camera.get_feature_by_name('Height')
                            print(f"/// Resolution    : {width.get()} x {height.get()}")
                        except Exception as e:
                            print(f"/// Resolution    : Could not read ({e})")
                            
                        try:
                            pixel_format = camera.get_feature_by_name('PixelFormat')
                            print(f"/// Pixel Format  : {pixel_format.get()}")
                        except Exception as e:
                            print(f"/// Pixel Format  : Could not read ({e})")
                            
                except Exception as e:
                    print(f"/// Access Error  : {e}")
                
                print()  # Empty line between cameras
                    
            print("=== Test Complete ===")
            
    except Exception as e:
        print(f"✗ VmbSystem error: {e}")
        print("\nTroubleshooting:")
        print("1. Ensure VimbaX drivers are installed on host system")
        print("2. Check that camera is connected and detected by host (lsusb)")
        print("3. Verify Docker has USB device access (--device=/dev/bus/usb)")
        print("4. Check that GENICAM_GENTL64_PATH is set correctly")
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())