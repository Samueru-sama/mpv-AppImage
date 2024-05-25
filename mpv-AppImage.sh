#!/bin/sh

# THIS SCRIPT BUILDS MPV USING THE SYSTEM DEPENDENCIES.
# THE PROBLEM IS THAT IT ONLY WORKS ON UBUNTU 24.04 AS OLDER VERSIONS HAVE TOO OLD DEPENDENCIES FOR MESON TO BUILD MPV
# THIS IS A PROBLEM AS THE APPIMAGE SPEC NEEDS IT TO BE BUILT ON 20.04 FOR IT TO BE COMPATIBLE ON OLD DISTROS.
# INSTEAD mpv-AppImage2.sh IS USED AS THAT ONE BUILDS THE DEPENDENCIES AND A STATICALLY LINKED MPV.

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

# DOWNLOAD AND BUILD MPV
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
wget "$REPO" -O download.tar.xz && tar fx *tar* && cd "$APP"* \
&& meson setup build -Dprefix="$CURRENTDIR"/usr && meson compile -C build && meson install -C build \
&& cd .. && rm -rf ./"$APP"* ./download.tar.xz || exit 1

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
"$CURRENTDIR/usr/bin/mpv" "$@"
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
