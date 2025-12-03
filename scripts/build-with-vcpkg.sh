#!/bin/bash
set -e

# Build script for Durian using vcpkg dependencies
# This script installs vcpkg dependencies and builds the project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "================================================"
echo "Building Durian with vcpkg dependencies"
echo "================================================"
echo ""

# Check if vcpkg is available
if ! command -v vcpkg &> /dev/null; then
    echo "Error: vcpkg not found in PATH"
    echo "Please install vcpkg and set VCPKG_ROOT"
    exit 1
fi

echo "✓ vcpkg found: $(vcpkg --version | head -1)"
echo ""

# Install dependencies using universal triplet
echo "Step 1: Installing vcpkg dependencies..."
echo "----------------------------------------"
vcpkg install --triplet=universal-osx --overlay-triplets=./triplets

echo ""
echo "Step 2: Verifying universal binaries..."
echo "----------------------------------------"
if [ -f "vcpkg_installed/universal-osx/lib/libFLAC.a" ]; then
    echo "Checking libFLAC.a:"
    lipo -info vcpkg_installed/universal-osx/lib/libFLAC.a
    echo "✓ Universal binaries installed successfully"
else
    echo "Error: Universal binaries not found"
    exit 1
fi

echo ""
echo "Step 3: Building Xcode project..."
echo "----------------------------------------"

# Build configuration (Debug or Release)
CONFIGURATION="${1:-Release}"

xcodebuild \
    -project Durian.xcodeproj \
    -target Durian \
    -configuration "$CONFIGURATION" \
    clean build \
    HEADER_SEARCH_PATHS="vcpkg_installed/universal-osx/include extern/include" \
    LIBRARY_SEARCH_PATHS="vcpkg_installed/universal-osx/lib extern/lib" \
    OTHER_LDFLAGS="-lFLAC -logg -lvorbis -lvorbisenc -lvorbisfile -lsamplerate -lsndfile -ltag -ltag_c -lz -lopus" \
    2>&1 | grep -v xcpretty || true

echo ""
echo "Step 4: Verifying output..."
echo "----------------------------------------"
APP_BUNDLE="build/$CONFIGURATION/Durian.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/Durian"

if [ ! -f "$APP_BINARY" ]; then
    echo "Error: Build failed - binary not found"
    exit 1
fi

echo "Binary info:"
file "$APP_BINARY"
echo ""
echo "Architectures:"
lipo -info "$APP_BINARY"
echo ""
echo "Code signature:"
codesign -dv "$APP_BUNDLE" 2>&1 | head -3
echo ""
echo "✓ Build successful!"
echo ""
echo "Output: $APP_BUNDLE"

echo ""
echo "================================================"
echo "Build complete!"
echo "================================================"
