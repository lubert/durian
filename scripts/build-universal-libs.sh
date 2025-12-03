#!/bin/bash
set -e

# Script to build universal (arm64 + x86_64) static libraries from vcpkg
# This script installs both triplets and combines them with lipo

echo "Building universal libraries from vcpkg..."

# Libraries to combine
LIBS=(
    "libFLAC"
    "libFLAC++"
    "libogg"
    "libvorbis"
    "libvorbisenc"
    "libvorbisfile"
    "libsamplerate"
    "libsndfile"
    "libtag"
    "libtag_c"
)

# Create output directory
mkdir -p extern/lib

# Build for arm64
echo "Installing arm64 dependencies..."
vcpkg install --triplet=arm64-osx

# Copy arm64 libs to temp location
echo "Saving arm64 libraries..."
mkdir -p /tmp/vcpkg-arm64
cp vcpkg_installed/arm64-osx/lib/*.a /tmp/vcpkg-arm64/ 2>/dev/null || true
cp vcpkg_installed/arm64-osx/debug/lib/*.a /tmp/vcpkg-arm64/ 2>/dev/null || true

# Build for x64
echo "Installing x64 dependencies..."
vcpkg install --triplet=x64-osx

# Create universal binaries
echo "Creating universal binaries..."
for lib in "${LIBS[@]}"; do
    ARM64_LIB="/tmp/vcpkg-arm64/${lib}.a"
    X64_LIB="vcpkg_installed/x64-osx/lib/${lib}.a"
    OUTPUT_LIB="extern/lib/${lib}.a"

    if [ -f "$ARM64_LIB" ] && [ -f "$X64_LIB" ]; then
        echo "  Creating universal $lib.a..."
        lipo -create "$ARM64_LIB" "$X64_LIB" -output "$OUTPUT_LIB"
        lipo -info "$OUTPUT_LIB"
    else
        echo "  Skipping $lib (not found in both architectures)"
    fi
done

# Restore arm64 for local development
echo "Restoring arm64 for local development..."
vcpkg install --triplet=arm64-osx

# Cleanup
rm -rf /tmp/vcpkg-arm64

echo "Done! Universal libraries created in extern/lib/"
