#!/bin/sh
set -e

TARGET="$HOME/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins"

for f in usr/lib/x86_64-linux-gnu/gegl-0.4/*.so; do
  rm -v "$TARGET/$(basename "$f")"
done
