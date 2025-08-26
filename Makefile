PROJECT_NAME := zimg
DOCKERFILE := Dockerfile
ZIG_VERSION ?= zig151
ZIG := zig

# Build configuration
OPTIMIZE ?= ReleaseFast
TARGET ?= native
STRIP ?= true
STATIC ?= false
CPU ?= baseline

# Build flags
BUILD_FLAGS := -Doptimize=$(OPTIMIZE) -Dcpu=$(CPU) -Dstrip=$(STRIP)
ifeq ($(STATIC),true)
BUILD_FLAGS += -Dtarget=$(TARGET)-linux-musl
else
BUILD_FLAGS += -Dtarget=$(TARGET)
endif

.PHONY: help build build-run fmt version install debug release

help:
	@echo "Usage: make [target] [VAR=value]"
	@echo ""
	@echo "Variables:"
	@echo "  ZIG_VERSION - Zig version to use (default: zig14)"
	@echo "  OPTIMIZE    - Optimization level (default: ReleaseFast)"
	@echo "                Options: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall"
	@echo "  TARGET      - Target triple (default: native)"
	@echo "  STRIP       - Strip debug symbols (default: true)"
	@echo "  STATIC      - Build static binary (default: true)"
	@echo "  CPU         - CPU features (default: baseline)"
	@echo ""
	@echo "Examples:"
	@echo "  make build OPTIMIZE=Debug STATIC=false"
	@echo "  make build TARGET=x86_64-linux-gnu STRIP=false"
	@echo "  make release"
	@echo ""
	@echo "Available targets:"
	@echo "  version     - Show configured Zig version and build flags"
	@echo "  fmt         - Format source code"
	@echo "  build       - Compile project with configured flags"
	@echo "  debug       - Compile debug build (OPTIMIZE=Debug STRIP=false)"
	@echo "  release     - Compile optimized release build"
	@echo "  build-run   - Compile and run project"
	@echo "  install     - Compile and install project"

version:
	@echo "Current configuration:"
	@echo "  ZIG_VERSION: $(ZIG_VERSION)"
	@echo "  ZIG: $(ZIG)"
	@echo "  OPTIMIZE: $(OPTIMIZE)"
	@echo "  TARGET: $(TARGET)"
	@echo "  STRIP: $(STRIP)"
	@echo "  STATIC: $(STATIC)"
	@echo "  CPU: $(CPU)"
	@echo "  BUILD_FLAGS: $(BUILD_FLAGS)"
	@echo ""
	@$(ZIG) version

build:
	@echo "🔨 Compiling with $(ZIG) [$(OPTIMIZE)]..."
	@echo "Flags: $(BUILD_FLAGS)"
	$(ZIG) build $(BUILD_FLAGS)

debug:
	@echo "🐛 Building debug version..."
	$(MAKE) build OPTIMIZE=Debug STRIP=false STATIC=false

release:
	@echo "🚀 Building optimized release..."
	$(MAKE) build OPTIMIZE=ReleaseFast STRIP=true STATIC=true

fmt:
	@echo "📝 Formatting with $(ZIG)..."
	$(ZIG) fmt ./**/*.zig

build-run:
	@echo "🚀 Running with $(ZIG)..."
	$(ZIG) build run $(BUILD_FLAGS)

install: build
	@echo "🔧 Installing with $(ZIG)..."
	sudo $(ZIG) build install --prefix /usr/local $(BUILD_FLAGS)