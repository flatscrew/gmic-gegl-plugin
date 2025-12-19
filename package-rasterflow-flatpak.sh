#!/bin/sh

flatpak-builder --force-clean --disable-rofiles-fuse --keep-build-dirs --repo=repo "$PWD/_install" io.flatscrew.RasterFlow.Extension.GMICRuntime.yml
flatpak build-bundle --runtime repo io.flatscrew.RasterFlow.Extension.GMICRuntime.flatpak --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo io.flatscrew.RasterFlow.Extension.GMICRuntime 1