#!/bin/bash

echo "=== Compiling MuMain C++ Client to WebAssembly (client.wasm) ==="

if ! command -v emcc &> /dev/null; then
    echo "[!] Emscripten compiler (emcc) not found in PATH."
    echo "[!] Ensure sdk-upstream or EMSDK environment is sourced."
    echo "[!] Example: source /path/to/emsdk/emsdk_env.sh"
fi

BUILD_DIR="build-wasm"
mkdir -p "$BUILD_DIR"

if [ -n "$EMSDK" ]; then
    cmake -B "$BUILD_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_EDITOR=OFF

    cmake --build "$BUILD_DIR" --target Main -j$(nproc)

    echo "[+] Copying WASM build artifacts to public/..."
    cp "$BUILD_DIR/src/Main.js" public/client.js 2>/dev/null || true
    cp "$BUILD_DIR/src/Main.wasm" public/client.wasm 2>/dev/null || true
fi

echo "=== WASM Build Script Ready ==="
