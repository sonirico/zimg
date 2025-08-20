PROJECT_NAME := zimg
DOCKERFILE := Dockerfile
ZIG_VERSION ?= zig14
ZIG := $(ZIG_VERSION)

.PHONY: help build build-run fmt version

help:
	@echo "Usage: make [target] [ZIG_VERSION=zigXX]"
	@echo "Variables:"
	@echo "  ZIG_VERSION - Zig version to use (default: zig14)"
	@echo "    Examples: make build ZIG_VERSION=zig15"
	@echo "              make test ZIG_VERSION=zig"
	@echo ""
	@echo "Available targets:"
	@echo "  version     - Show configured Zig version"
	@echo "  fmt         - Format source code ($(ZIG) fmt)"
	@echo "  build       - Compile project locally ($(ZIG) build)"
	@echo "  build-run   - Compile and run project locally ($(ZIG) build run)"

version:
	@echo "Current configuration:"
	@echo "  ZIG_VERSION: $(ZIG_VERSION)"
	@echo "  ZIG: $(ZIG)"
	@echo ""
	@$(ZIG) version

build:
	@echo "🔨 Compiling with $(ZIG)..."
	$(ZIG) build

fmt:
	@echo "📝 Formatting with $(ZIG)..."
	$(ZIG) fmt ./**/*.zig

build-run:
	@echo "🚀 Running with $(ZIG)..."
	$(ZIG) build run
