#!/bin/sh

# Download yt-dlp if needed
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"
export PATH="$PATH:$CACHEDIR/mpv-appimage_yt-dlp"
if echo "$@" | grep -q "http" && ! command -v yt-dlp >/dev/null 2>&1; then
	echo "Video link detected but yt-dlp is not installed, installing..."
	mkdir -p "$CACHEDIR"/mpv-appimage_yt-dlp
	YT=$(curl -Ls https://api.github.com/repos/yt-dlp/yt-dlp/releases \
		| sed 's/[()",{} ]/\n/g' | grep -oi 'https.*yt.*linux$' | head -1)
	if command -v wget >/dev/null 2>&1; then
		wget -q "$YT" -O "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp
	elif command -v curl >/dev/null 2>&1; then
		curl -Ls "$YT" -o "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp
	else
		echo "ERROR: You need wget or curl in order to download yt-dlp"
	fi
fi

chmod +x "$CACHEDIR"/mpv-appimage_yt-dlp/yt-dlp 2>/dev/null

