#!/bin/sh

# THIS SCRIPT BUILDS MPV DEPENDENCIES AND MPV STATICALLY USING THIS: https://github.com/mpv-player/mpv-build
set -u
APP=mpv
APPDIR="$APP".AppDir
REPO="https://github.com/mpv-player/mpv-build.git"
EXEC="$APP"

APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/[()",{} ]/\n/g' | grep -oi 'https.*continuous.*tool.*x86_64.*mage$' | head -1)

# CREATE DIRECTORIES AND BUILD MPV
[ -n "$APP" ] && mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
git clone "$REPO" && cd ./mpv-build && sed -i "s#meson setup build#meson setup build -Dprefix=$CURRENTDIR/usr#g" ./scripts/mpv-config \
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
cp ./usr/share/icons/hicolor/128x128/apps/mpv.png ./ && ln -s ./mpv.png ./.DirIcon # If not done linuxdeploy will pick the wrong icon
sed -i 's/name/Name/g' ./usr/share/applications/*desktop # https://github.com/mpv-player/mpv/pull/14272

# MAKE APPIMAGE USING FUSE3 COMPATIBLE APPIMAGETOOL
cd .. && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool || exit 1
./appimagetool --appimage-extract-and-run deploy "$APPDIR"/usr/share/applications/*.desktop || exit 1
sed -i 's/export PYTHONHOME/#export PYTHONHOME/g' "$APPDIR"/AppRun # unsets this since python isn't bundled
ARCH=x86_64 VERSION="$APPVERSION-go-appimage" ./appimagetool --appimage-extract-and-run -s ./"$APPDIR" || exit 1
[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "All Done!" || exit 1
