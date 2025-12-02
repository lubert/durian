# Custom vcpkg triplet for macOS universal binaries (arm64 + x86_64)
# Based on arm64-osx.cmake with multi-architecture support

set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)

# This is the key: build for both architectures in one pass
set(VCPKG_OSX_ARCHITECTURES "arm64;x86_64")

# Set minimum macOS version (matches your project's deployment target)
set(VCPKG_OSX_DEPLOYMENT_TARGET "10.13")
