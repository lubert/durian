# Makefile for Durian audio player
# Manages vcpkg dependencies and Xcode builds

.PHONY: all deps verify build clean rebuild run help debug release lint

# Default configuration
CONFIGURATION ?= Release
PROJECT := Durian.xcodeproj
TARGET := Durian
VCPKG_TRIPLET := universal-osx
APP_BUNDLE := build/$(CONFIGURATION)/Durian.app

# Colors for output
COLOR_RESET := \033[0m
COLOR_BLUE := \033[34m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m

all: deps build

help:
	@echo "$(COLOR_BLUE)Durian Build System$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Available targets:$(COLOR_RESET)"
	@echo "  make deps       - Install/update vcpkg dependencies"
	@echo "  make verify     - Verify vcpkg dependencies are installed"
	@echo "  make build      - Build the project (incremental)"
	@echo "  make rebuild    - Clean and build the project"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make run        - Build and run the application"
	@echo "  make debug      - Build debug configuration"
	@echo "  make release    - Build release configuration (default)"
	@echo "  make lint       - Format all Objective-C source files"
	@echo "  make all        - Install deps and build (default)"
	@echo ""
	@echo "$(COLOR_GREEN)Examples:$(COLOR_RESET)"
	@echo "  make              # Install deps and build release"
	@echo "  make debug        # Build debug configuration"
	@echo "  make clean build  # Clean rebuild"

deps:
	@echo "$(COLOR_BLUE)Installing vcpkg dependencies...$(COLOR_RESET)"
	@if ! command -v vcpkg >/dev/null 2>&1; then \
		echo "$(COLOR_YELLOW)Error: vcpkg not found in PATH$(COLOR_RESET)"; \
		echo "Please install vcpkg and set VCPKG_ROOT"; \
		exit 1; \
	fi
	@echo "✓ vcpkg found: $$(vcpkg --version | head -1)"
	vcpkg install --triplet=$(VCPKG_TRIPLET) --overlay-triplets=./triplets

verify:
	@echo "$(COLOR_BLUE)Verifying vcpkg dependencies...$(COLOR_RESET)"
	@if [ -f "vcpkg_installed/$(VCPKG_TRIPLET)/lib/libFLAC.a" ]; then \
		echo "✓ Dependencies installed"; \
		echo ""; \
		echo "Checking libFLAC.a:"; \
		lipo -info vcpkg_installed/$(VCPKG_TRIPLET)/lib/libFLAC.a; \
	else \
		echo "$(COLOR_YELLOW)Error: Dependencies not found$(COLOR_RESET)"; \
		echo "Run 'make deps' to install them"; \
		exit 1; \
	fi

build:
	@echo "$(COLOR_BLUE)Building $(TARGET) ($(CONFIGURATION))...$(COLOR_RESET)"
	xcodebuild \
		-project $(PROJECT) \
		-target $(TARGET) \
		-configuration $(CONFIGURATION) \
		build
	@echo ""
	@echo "$(COLOR_GREEN)✓ Build successful!$(COLOR_RESET)"
	@echo "Output: $(APP_BUNDLE)"

rebuild: clean build

clean:
	@echo "$(COLOR_BLUE)Cleaning build artifacts...$(COLOR_RESET)"
	xcodebuild \
		-project $(PROJECT) \
		-target $(TARGET) \
		-configuration $(CONFIGURATION) \
		clean
	@echo "$(COLOR_GREEN)✓ Clean complete$(COLOR_RESET)"

run: build
	@echo "$(COLOR_BLUE)Running $(TARGET)...$(COLOR_RESET)"
	open $(APP_BUNDLE)

debug:
	@$(MAKE) build CONFIGURATION=Debug

release:
	@$(MAKE) build CONFIGURATION=Release

lint:
	@echo "$(COLOR_BLUE)Formatting Objective-C source files with clang-format (WebKit style)...$(COLOR_RESET)"
	@if ! command -v clang-format >/dev/null 2>&1; then \
		echo "$(COLOR_YELLOW)Error: clang-format not found in PATH$(COLOR_RESET)"; \
		exit 1; \
	fi
	@echo "✓ clang-format found: $$(clang-format --version | head -1)"
	@FILES=$$(find . -name "*.m" -o -name "*.mm" -o -name "*.h" | grep -v vcpkg | grep -v build); \
	COUNT=$$(echo "$$FILES" | wc -l | tr -d ' '); \
	echo "Formatting $$COUNT files..."; \
	echo "$$FILES" | xargs clang-format -i -style=WebKit
	@echo "$(COLOR_GREEN)✓ Formatting complete!$(COLOR_RESET)"

# Info targets for debugging
info:
	@echo "Project:       $(PROJECT)"
	@echo "Target:        $(TARGET)"
	@echo "Configuration: $(CONFIGURATION)"
	@echo "App Bundle:    $(APP_BUNDLE)"
	@echo "Triplet:       $(VCPKG_TRIPLET)"

# Check if app exists
check:
	@if [ -d "$(APP_BUNDLE)" ]; then \
		echo "$(COLOR_GREEN)✓ App bundle exists$(COLOR_RESET)"; \
		echo ""; \
		echo "Binary info:"; \
		file $(APP_BUNDLE)/Contents/MacOS/$(TARGET); \
		echo ""; \
		echo "Architectures:"; \
		lipo -info $(APP_BUNDLE)/Contents/MacOS/$(TARGET); \
		echo ""; \
		echo "Code signature:"; \
		codesign -dv $(APP_BUNDLE) 2>&1 | head -3; \
	else \
		echo "$(COLOR_YELLOW)App bundle not found at: $(APP_BUNDLE)$(COLOR_RESET)"; \
		exit 1; \
	fi
