#!/bin/sh
set -e

VERSION="$(cat VERSION)"
NAME="RasterFlow-GMIC-GEGL-$VERSION"
OUT="$NAME.run"
TITLE="G'Mic GEGL Plugins $VERSION"

# first compilation to get generator
meson setup build -Dwith_generator=true
meson compile -C build

# generate operations
./build/generator/gmic-gegl-generator --output-dir=operations/commands

# second compilation to get .so for operations
DESTDIR=payload ninja -C build install

mkdir -p build/payload
cp VERSION build/payload
cp rasterflow-linux/install.sh build/payload
cp rasterflow-linux/uninstall.sh build/payload

makeself build/payload "$OUT" "$TITLE" ./install.sh

echo "Built installer: $OUT"
