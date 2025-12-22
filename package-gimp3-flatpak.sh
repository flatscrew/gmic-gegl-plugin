#!/bin/sh

VERSION="$(cat VERSION-RUNTIME)"

flatpak-builder --force-clean --disable-rofiles-fuse --keep-build-dirs --repo=repo "$PWD/_install" org.gimp.GIMP.Plugin.GMICRuntime.yml
flatpak build-bundle --runtime repo org.gimp.GIMP.Plugin.GMICRuntime-$VERSION.flatpak --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo org.gimp.GIMP.Plugin.GMICRuntime 3