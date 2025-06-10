#!/usr/bin/env python3
"""
Simple test script to list available cameras using VmbPy (VimbaX API).
This is a migration from the old VimbaPython to the new VimbaX API.
"""

import sys
try:
    import vmbpy
except ImportError:
    print("ERROR: VmbPy not installed. Please install VmbPy first.")
    print("Install with: pip install vmbpy")
    sys.exit(1)

def main():
    """List all available cameras using VmbPy."""
    print("VmbPy - Listing available cameras...")
    
    try:
        # Get VmbSystem instance (singleton)
        vmb = vmbpy.VmbSystem.get_instance()
        
        # Enter context (this initializes the VmbC API)
        with vmb:
            print("VmbSystem initialized successfully")
            
            # Get all available cameras
            cameras = vmb.get_all_cameras()
            
            if not cameras:
                print("No cameras found.")
                return 0
            
            print(f"Found {len(cameras)} camera(s):")
            
            for i, camera in enumerate(cameras):
                print(f"\n--- Camera {i+1} ---")
                print(f"ID: {camera.get_id()}")
                print(f"Name: {camera.get_name()}")
                print(f"Model: {camera.get_model()}")
                print(f"Serial: {camera.get_serial()}")
                print(f"Interface ID: {camera.get_parent_interface_id()}")
                
                # Try to get some basic information
                try:
                    with camera:
                        # Try to access some basic features
                        try:
                            width = camera.get_feature_by_name('Width')
                            height = camera.get_feature_by_name('Height')
                            print(f"Resolution: {width.get()} x {height.get()}")
                        except Exception as e:
                            print(f"Could not read resolution: {e}")
                            
                        try:
                            pixel_format = camera.get_feature_by_name('PixelFormat')
                            print(f"Pixel Format: {pixel_format.get()}")
                        except Exception as e:
                            print(f"Could not read pixel format: {e}")
                            
                except Exception as e:
                    print(f"Could not access camera: {e}")
                    
        return 0
        
    except Exception as e:
        print(f"ERROR: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())