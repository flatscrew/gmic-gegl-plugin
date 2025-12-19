#!/bin/sh
set -e

ask() {
  printf "%s [y/N]: " "$1"
  read ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

if [ "$1" = "uninstall" ]; then
  ask "Uninstall G'MIC GEGL plugins?" || exit 0
  sh ./uninstall.sh
  exit 0
fi

VERSION="$(cat VERSION 2>/dev/null || echo unknown)"
echo "G'MIC GEGL Plugins version $VERSION"

ask "Install G'MIC GEGL plugins?" || exit 0

TARGET="$HOME/.var/app/io.flatscrew.RasterFlow/data/gegl-0.4/plug-ins"
mkdir -p "$TARGET"
cp -v usr/lib/x86_64-linux-gnu/gegl-0.4/*.so "$TARGET/"
