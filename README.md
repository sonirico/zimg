# zimg

[![Zig](https://img.shields.io/badge/Zig-0.14+-F7A41D?style=flat&logo=zig&logoColor=white)](https://ziglang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![libvips](https://img.shields.io/badge/libvips-8.17+-4B8BBE?style=flat)](https://libvips.github.io/libvips/)
[![Release](https://img.shields.io/github/v/release/sonirico/zimg?style=flat)](https://github.com/sonirico/zimg/releases)

Fast image processing CLI tool built with Zig and libvips. Designed for high-performance batch operations and pipeline integration.

## Installation

### Quick install

```bash
curl -sSL https://raw.githubusercontent.com/sonirico/zimg/main/install.sh | bash
```

### Binary releases

Download the latest release for your platform:

```bash
# Linux x86_64
curl -L https://github.com/sonirico/zimg/releases/latest/download/zimg-linux-x86_64 -o zimg
chmod +x zimg

# macOS (Intel)
curl -L https://github.com/sonirico/zimg/releases/latest/download/zimg-darwin-x86_64 -o zimg
chmod +x zimg

# macOS (Apple Silicon)
curl -L https://github.com/sonirico/zimg/releases/latest/download/zimg-darwin-arm64 -o zimg
chmod +x zimg

# Windows
curl -L https://github.com/sonirico/zimg/releases/latest/download/zimg-windows-x86_64.exe -o zimg.exe
```

### Docker

```bash
docker pull ghcr.io/sonirico/zimg:latest
docker run --rm -v $(pwd):/workspace ghcr.io/sonirico/zimg inspect /workspace/image.jpg
```

### From source

Requires Zig 0.14+ and libvips development headers:

```bash
# Ubuntu/Debian
sudo apt install libvips-dev

# macOS
brew install vips

# Build
git clone https://github.com/sonirico/zimg.git
cd zimg
zig build -Doptimize=ReleaseFast
```

## Usage

All commands support reading from stdin for pipeline operations:

```bash
# Basic inspection
zimg inspect image.jpg

# Pipeline usage
cat image.jpg | zimg inspect

# JSON output for scripting
zimg inspect --json image.jpg | jq '.width'
```

### Commands

**inspect** - Analyze image properties
```bash
zimg inspect photo.jpg
zimg inspect --json photo.jpg  # JSON format
```

**optimize** - Compress images
```bash
zimg optimize --quality 85 --strip photo.jpg
zimg optimize --palette photo.png  # Enable palette optimization
```

**crop** - Extract image regions
```bash
zimg crop photo.jpg 100 100 800 600  # x y width height
```

**scale** - Resize images
```bash
zimg scale photo.jpg 1920 1080
```

### Pipeline examples

```bash
# Batch optimization
find . -name "*.jpg" | xargs -I {} zimg optimize --quality 80 {}

# Inspect multiple files
for img in *.jpg; do zimg inspect --json "$img"; done | jq '.size_bytes' | paste -sd+ | bc

# Convert and optimize pipeline
cat input.tiff | zimg optimize --quality 90 > output.jpg
```

## Development Status

### Implemented
- [x] Basic CLI structure with zli framework
- [x] Image inspection with full metadata
- [x] libvips integration for format detection
- [x] Pipeline support (stdin/stdout)
- [x] JSON output format
- [x] Error handling and validation

### In Progress
- [ ] Optimize command with compression options
- [ ] Crop command with coordinate validation
- [ ] Scale command with aspect ratio preservation

### Planned
- [ ] Format conversion (JPEG, PNG, WebP, AVIF)
- [ ] Batch processing mode
- [ ] Configuration file support
- [ ] Progress bars for large operations
- [ ] Color profile management
- [ ] Watermarking capabilities
- [ ] Advanced filters (blur, sharpen, etc.)
- [ ] Multi-threading for batch operations
- [ ] Plugin system for custom operations

### Research
- [ ] SIMD optimizations
- [ ] WebAssembly target
- [ ] GPU acceleration integration
- [ ] Streaming processing for large files

## Contributing

This project uses Zig 0.14 and follows standard practices. PRs welcome for bug fixes and feature implementations from the TODO list.

## License

MIT
