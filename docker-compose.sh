#!/bin/bash
# Docker Compose helper script that sets the correct architecture
# Usage: ./docker-compose.sh [docker-compose arguments]

# Auto-detect architecture
ARCH=$(uname -m | sed 's/aarch64/arm64/; s/x86_64/amd64/')

# Export as environment variable for docker-compose
export ARCH

# Run docker-compose with the architecture environment variable
docker-compose "$@"