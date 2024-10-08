#!/bin/sh

# THIS SCRIPT BUILDS MPV DEPENDENCIES AND MPV STATICALLY USING THIS: https://github.com/mpv-player/mpv-build
set -u
export ARCH=x86_64
export APPIMAGE_EXTRACT_AND_RUN=1
APP=mpv
APPDIR="$APP".AppDir
REPO="https://github.com/mpv-player/mpv-build.git"
EXEC="$APP"
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/[()",{} ]/\n/g' | grep -oi 'https.*continuous.*tool.*x86_64.*mage$' | head -1)

# make vulkan headers
wget https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.3.238.tar.gz
tar fx *tar* && cd Vulkan*
cmake -S . -B build/
sudo cmake --install build --prefix '/usr'
cd .. && rm -rf ./*tar* ./Vulkan*

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
export VERSION=$(./AppRun --version | awk 'FNR == 1 {print $2}')
cp ./usr/share/icons/hicolor/128x128/apps/mpv.png ./ && ln -s ./mpv.png ./.DirIcon # If not done linuxdeploy will pick the wrong icon

# MAKE APPIMAGE USING FUSE3 COMPATIBLE APPIMAGETOOL
cd .. && cp -r "$APPDIR" "$APPDIR"2 && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool || exit 1

./appimagetool deploy "$APPDIR"/usr/share/applications/*.desktop || exit 1
sed -i 's/export PYTHONHOME/#export PYTHONHOME/g' "$APPDIR"/AppRun # unsets this since python isn't bundled
./appimagetool -s ./"$APPDIR" || exit 1
mv ./*.AppImage .. && echo "Regular appimage made" || exit 1

# EXPERIMENTAL DEPLOY EVERYTHING MODE. TODO FIX INTERNET ISSUES
APPDIR="$APPDIR"2
export VERSION="$VERSION-anylinux"
sed -i 's/Name=mpv/Name=WIP-mpv/g' "$APPDIR"/usr/share/applications/*.desktop
./appimagetool -s deploy "$APPDIR"/usr/share/applications/*.desktop || exit 1
sed -i 's/export PYTHONHOME/#export PYTHONHOME/g' "$APPDIR"/AppRun # unsets this since python isn't bundled
./appimagetool -s ./"$APPDIR" || exit 1
[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "Deploy everything appimage made" || exit 1
