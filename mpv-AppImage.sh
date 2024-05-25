#!/bin/sh

# THIS SCRIPTS BUILDS MPV DEPENDENCIES AND MPV STATICALLY USING THIS: https://github.com/mpv-player/mpv-build

set -u
ARCH=x86_64
APP=mpv
APPDIR="$APP".AppDir
REPO="https://github.com/mpv-player/mpv/archive/refs/tags/v0.38.0.tar.gz"
EXEC="$APP"

LINUXDEPLOY="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-static-x86_64.AppImage"
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')

# CREATE DIRECTORIES
[ -n "$APP" ] && mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# USE HELPER SCRIPT FOR BUILDING
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
git clone https://github.com/mpv-player/mpv-build.git && cd ./mpv-build \
&& sed -i "s#meson setup build#meson setup build -Dprefix=$CURRENTDIR/usr#g" ./scripts/mpv-config \
&& ./rebuild -j$(nproc) && ./install && cd .. && rm -rf ./mpv-build || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
if [ -z "$@" ]; then
	"$CURRENTDIR/usr/bin/mpv" --player-operation-mode=pseudo-gui
else
	"$CURRENTDIR/usr/bin/mpv" "$@"
fi
EOF
chmod a+x ./AppRun
APPVERSION=$(./AppRun --version | awk 'FNR == 1 {print $2}')

# Desktop
cp ./usr/share/applications/*.desktop ./

# Icon
cp ./usr/share/icons/hicolor/128x128/apps/mpv.png ./
ln -s ./mpv.png ./.DirIcon

# MAKE APPIMAGE USING FUSE3 COMPATIBLE APPIMAGETOOL
cd .. && wget "$LINUXDEPLOY" -O linuxdeploy && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./linuxdeploy ./appimagetool \
&& ./linuxdeploy --appdir "$APPDIR" --executable "$APPDIR"/usr/bin/"$EXEC" && VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR" || exit 1
[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "All Done!" || exit 1
