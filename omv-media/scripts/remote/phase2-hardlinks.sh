#!/bin/bash
# Phase 2: TRaSH-style unified /data mount (run on OMV after phase0 confirms paths)
# SAFETY: backs up compose files, does not move library data.
set -euo pipefail

MEDIA_HOST="${MEDIA_HOST:-}"  # e.g. /srv/dev-disk-by-uuid-XXX/sharedfolders/Media
DATA_ROOT="${DATA_ROOT:-}"      # e.g. /srv/dev-disk-by-uuid-XXX/data

if [ -z "$MEDIA_HOST" ] || [ -z "$DATA_ROOT" ]; then
  echo "Usage: MEDIA_HOST=/path/to/Media DATA_ROOT=/path/to/data $0"
  echo "Creates DATA_ROOT/{torrents/{movies,tv},media/{movies,tv}} and bind-mount layout."
  exit 1
fi

mkdir -p "$DATA_ROOT/torrents/movies" "$DATA_ROOT/torrents/tv"
mkdir -p "$DATA_ROOT/media/movies" "$DATA_ROOT/media/tv"

# Bind existing library into TRaSH paths if not already present
mountpoint -q "$DATA_ROOT/media/movies" 2>/dev/null || {
  [ -d "$MEDIA_HOST/Movies" ] && mount --bind "$MEDIA_HOST/Movies" "$DATA_ROOT/media/movies"
}
mountpoint -q "$DATA_ROOT/media/tv" 2>/dev/null || {
  [ -d "$MEDIA_HOST/TV" ] && mount --bind "$MEDIA_HOST/TV" "$DATA_ROOT/media/tv"
}
mountpoint -q "$DATA_ROOT/torrents" 2>/dev/null || {
  [ -d "$MEDIA_HOST/Downloads/Torrents" ] && mount --bind "$MEDIA_HOST/Downloads/Torrents" "$DATA_ROOT/torrents"
}

# Persist bind mounts in fstab if missing
grep -q "$DATA_ROOT/media/movies" /etc/fstab 2>/dev/null || {
  echo "$MEDIA_HOST/Movies $DATA_ROOT/media/movies none bind 0 0" >> /etc/fstab
  echo "$MEDIA_HOST/TV $DATA_ROOT/media/tv none bind 0 0" >> /etc/fstab
  echo "$MEDIA_HOST/Downloads/Torrents $DATA_ROOT/torrents none bind 0 0" >> /etc/fstab
}

echo "DATA_ROOT layout:"
find "$DATA_ROOT" -maxdepth 3 -type d
echo ""
echo "Update each stack docker-compose.yml to mount:"
echo "  $DATA_ROOT:/data"
echo "Then set container paths:"
echo "  qBit save: /data/torrents/movies, /data/torrents/tv"
echo "  Sonarr root: /data/media/tv"
echo "  Radarr root: /data/media/movies"
echo "  Plex: /data/media:ro"
echo "Enable hardlinks in *arr download client settings."
