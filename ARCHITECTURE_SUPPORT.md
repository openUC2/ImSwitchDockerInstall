# Multi-Architecture Support

This repository now supports both ARM64 (aarch64) and AMD64 (x86_64) architectures automatically.

## Supported Architectures

- **ARM64** (aarch64): Raspberry Pi and other ARM-based systems
- **AMD64** (x86_64): Intel/AMD x86 64-bit systems

## Architecture Detection

All scripts use the following command to auto-detect architecture:
```bash
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/')
```

This maps:
- `aarch64` → `arm64` (for Docker image naming)
- `x86_64` → `amd64` (for Docker image naming)

## Docker Images

The following Docker image is used:
- Universal: `ghcr.io/openuc2/imswitch-noqt:latest`

## Camera Drivers

### HIK/MVS Driver
The HIK driver installation now supports both architectures:

- **ARM64**: `MVS-3.0.1_aarch64_20241128.deb`
- **AMD64**: `MVS-3.0.1_x86_64_20241128.deb`

Sample paths:
- **ARM64**: `/opt/MVS/Samples/aarch64/Python/`
- **AMD64**: `/opt/MVS/Samples/64/Python/`

### Files Modified

1. **install_hikdriver.sh** - Auto-detects architecture for HIK driver
2. **install_autostart.sh** - Uses architecture-specific Docker images
3. **pull_and_run.sh** - Auto-detects architecture for Docker pull
4. **compose.yaml** - Uses environment variable for architecture
5. **create_desktopicons.sh** - Scripts detect architecture
6. **install_all_pigen.sh** - Multiple architecture adaptations
7. **.github/workflows/main.yml** - GitHub Actions workflow updated
8. **README.md** - Updated with architecture support information
9. **HIK/dockerfile** - Multi-architecture Docker build support

## Usage Examples

### Docker Compose
```bash
# Auto-detect and set architecture
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/') docker-compose up -d
```

### Manual Docker Run
```bash
# Auto-detect architecture
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/')
sudo docker run -it --rm -p 8001:8001 -p 8002:8002 -p 8888:8888 \
  -e HEADLESS=1 -e HTTP_PORT=8001 \
  --privileged ghcr.io/openuc2/imswitch-noqt:latest
```

### HIK Driver Installation
```bash
# The install_hikdriver.sh script now automatically:
# 1. Detects system architecture
# 2. Downloads appropriate .deb file
# 3. Uses correct sample path
./install_hikdriver.sh
```

## Backwards Compatibility

All existing ARM64-specific references have been replaced with architecture-aware versions. The changes are backwards compatible and will default to ARM64 behavior if architecture detection fails.