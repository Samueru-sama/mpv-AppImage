#!/bin/sh

# dependencies: 
# meson cmake automake ninja ninja-build vulkan-headers freetype-dev libass-dev
# fribidi-dev harfbuzz-dev yasm libx11 libx11-dev libxinerama-dev libxrandr-dev 
# libxscrnsaver libxscrnsaver-dev xscreensaver-gl-extras jack libpulse pulseaudio-dev
# rubberband libcaca mesa-egl libxpresent-dev lua5.3-dev libxcb-dev desktop-file-utils

set -u
export ARCH=x86_64
export APPIMAGE_EXTRACT_AND_RUN=1
REPO="https://github.com/mpv-player/mpv-build.git"
GOAPPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi 'https.*continuous.*tool.*x86_64.*mage$' | head -1)
mkdir -p ./mpv/mpv.AppDir && cd ./mpv/mpv.AppDir || exit 1

# Build mpv
if [ ! -d ./usr ]; then
	CURRENTDIR="$(readlink -f "$(dirname "$0")")"
	git clone "$REPO" && cd ./mpv-build || exit 1
	sed -i "s#meson setup build#meson setup build -Dprefix=$CURRENTDIR/usr#g" ./scripts/mpv-config
	./rebuild -j$(nproc) && ./install && cd .. && rm -rf ./mpv-build || exit 1
	cp ./usr/share/icons/hicolor/128x128/apps/mpv.png ./ && ln -s ./mpv.png ./.DirIcon
fi

# make appimage
export VERSION=$(./usr/bin/mpv --version 2>/dev/null | awk 'FNR==1 {print $2}')
[ -z "$VERSION" ] && echo "ERROR: Could not get version from mpv" && exit 1
cd .. 
[ ! -f ./go-appimagetool ] && { wget -q "$GOAPPIMAGETOOL" -O ./go-appimagetool || exit 1; }
chmod +x ./*tool
./go-appimagetool -s deploy ./mpv.AppDir/usr/share/applications/*.desktop || exit 1
sed -i 's/export PYTHONHOME/#export PYTHONHOME/g' ./mpv.AppDir/AppRun
./go-appimagetool -s ./mpv.AppDir || exit 1
mv ./*.AppImage* .. && cd .. && rm -rf ./mpv || exit 1
echo "All done!"
