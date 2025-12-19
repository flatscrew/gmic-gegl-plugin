#!/bin/sh

flatpak-builder --force-clean --disable-rofiles-fuse --keep-build-dirs --repo=repo "$PWD/_install" org.gimp.GIMP.Plugin.GMICRuntime.yml
flatpak build-bundle --runtime repo org.gimp.GIMP.Plugin.GMICRuntime.flatpak --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo org.gimp.GIMP.Plugin.GMICRuntime 3