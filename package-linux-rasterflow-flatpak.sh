#!/bin/sh

VERSION="$(cat VERSION-RUNTIME)"

flatpak-builder --force-clean --disable-rofiles-fuse --keep-build-dirs --repo=repo "$PWD/_install" io.flatscrew.RasterFlow.Extension.GMICRuntime.yml
flatpak build-bundle --runtime repo io.flatscrew.RasterFlow.Extension.GMICRuntime-$VERSION.flatpak --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo io.flatscrew.RasterFlow.Extension.GMICRuntime 1