#!/bin/bash
# Quick script to install vcpkg dependencies
# Usage: ./scripts/install-deps.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

if ! command -v vcpkg &> /dev/null; then
    echo "Error: vcpkg not found"
    echo ""
    echo "Please install vcpkg:"
    echo "  git clone https://github.com/Microsoft/vcpkg.git ~/vcpkg"
    echo "  ~/vcpkg/bootstrap-vcpkg.sh"
    echo ""
    echo "Then add to your shell profile (~/.zshrc or ~/.bash_profile):"
    echo "  export VCPKG_ROOT=\$HOME/vcpkg"
    echo "  export PATH=\"\$VCPKG_ROOT:\$PATH\""
    exit 1
fi

echo "Installing vcpkg dependencies..."
vcpkg install --triplet=universal-osx --overlay-triplets=./triplets

echo ""
echo "✓ Dependencies installed successfully!"
echo ""
echo "Verify universal binaries:"
echo "  lipo -info vcpkg_installed/universal-osx/lib/libFLAC.a"
echo ""
echo "Build the project:"
echo "  ./scripts/build-with-vcpkg.sh"
