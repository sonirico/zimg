# Multi-stage Dockerfile for Pictomancer Zig API with optimized libvips
FROM alpine:3.22 AS base

# Set libvips version as build arg
ARG VIPS_VERSION=8.17.1
ENV VIPS_VERSION=${VIPS_VERSION}

# Install build tools
RUN apk add --no-cache \
    build-base \
    curl \
    git \
    meson \
    ninja \
    pkgconfig \
    python3 \
    py3-pip \
    tar \
    xz \
    wget

# Install libvips dependencies  
RUN apk add --no-cache \
    glib-dev \
    libexif-dev \
    expat-dev \
    fftw-dev \
    lcms2-dev \
    cairo-dev \
    pango-dev \
    librsvg-dev \
    orc-dev \
    libimagequant-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    tiff-dev \
    giflib-dev \
    cfitsio-dev \
    cgif-dev \
    libjxl-dev \
    libwebp-dev \
    libheif-dev \
    openjpeg-dev \
    openexr-dev \
    libarchive-dev \
    poppler-dev 

# Build and install libvips with optimal settings for image processing API
RUN cd /tmp && \
    curl -L https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz | tar xJ && \
    cd vips-${VIPS_VERSION} && \
    meson setup build \
        --prefix=/usr/local \
        --buildtype=release \
        --default-library=both \
        -Ddeprecated=false \
        -Dexamples=false \
        -Dcplusplus=false \
        -Ddocs=false \
        -Dintrospection=disabled \
        -Dvapi=false \
        -Dmodules=disabled \
        -Dimagequant=enabled \
        -Djpeg=enabled \
        -Dpng=enabled \
        -Dtiff=enabled \
        -Dwebp=enabled \
        -Dheif=enabled \
        -Dnsgif=true \
        -Dcgif=enabled \
        -Dpoppler=enabled \
        -Drsvg=enabled \
        -Dlcms=enabled \
        -Djpeg-xl=enabled \
        -Dfftw=enabled \
        -Dorc=enabled \
        -Dcfitsio=enabled \
        -Dopenjpeg=enabled \
        -Dopenexr=enabled \
        -Darchive=enabled \
        -Dexif=enabled \
        -Dzlib=enabled \
        -Dppm=true \
        -Danalyze=false \
        -Dradiance=false \
        -Dfuzzing_engine=none \
    && cd build \
    && ninja \
    && ninja install \
    && ldconfig /usr/local/lib \
    && cd / \
    && rm -rf /tmp/vips-${VIPS_VERSION}

# ================================
# Zig build stage
# ================================
FROM base AS zig-builder

# Install Zig
ARG ZIG_VERSION=0.14.1
ENV ZIG_VERSION=${ZIG_VERSION}

RUN cd /tmp && \
    curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" | tar xJ && \
    mv zig-x86_64-linux-${ZIG_VERSION} /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig

# Verify installations
RUN zig version && /usr/local/bin/vips --version

# ================================
# Development dependencies stage  
# ================================
FROM zig-builder AS deps

WORKDIR /app

# Copy build files first for better caching
COPY build.zig ./
COPY build.zig.zon ./

# Pre-compile dependencies (if any)
RUN zig build --help || true

# ================================
# Testing stage
# ================================
FROM deps AS test

# Copy source code
COPY src/ ./src/
COPY bench/ ./bench/

# Run tests
RUN zig build test

# ================================
# Production build stage
# ================================
FROM deps AS builder

# Copy source code
COPY src/ ./src/
COPY bench/ ./bench/

# Build the application with optimizations
RUN zig build -Doptimize=ReleaseFast

# ================================
# Production runtime stage
# ================================
FROM alpine:3.22 AS production

# Install only runtime dependencies (no -dev packages)
RUN apk add --no-cache \
    ca-certificates \
    glib \
    libexif \
    expat \
    fftw \
    lcms2 \
    cairo \
    pango \
    librsvg \
    orc \
    libimagequant \
    libjpeg-turbo \
    libjxl \
    libpng \
    tiff \
    giflib \
    cgif \
    libwebp \
	libwebp-dev \
    libheif \
    openjpeg \
    openexr \
    cfitsio \
    libarchive \
    poppler \
    poppler-glib ;

# Copy libvips libraries and binary from builder
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/vips /usr/local/bin/
RUN ldconfig /usr/local/lib

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copy application binary
COPY --from=builder /app/zig-out/bin/zimg /usr/local/bin/zimg
RUN chmod +x /usr/local/bin/zimg

# Switch to non-root user
USER appuser

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/usr/local/bin/zimg", "--help"] || exit 1

ENTRYPOINT ["/usr/local/bin/zimg"]
