#!/bin/sh
set -e

# prepare 
rm -rf build

# first compilation to get generator
# for Windows, generated operations never have Aux input, applies for Gimp and RasterFlow
# at least for now ...
meson setup build -Dwith_generator=true -Dwith_aux=false
meson compile -C build

# generate operations
./build/generator/gmic-gegl-generator --output-dir=operations/commands

# second compilation to get .dll-s for operations
DESTDIR=payload ninja -C build install

mkdir -p build/payload
