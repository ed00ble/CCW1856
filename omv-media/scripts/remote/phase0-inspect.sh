#!/bin/bash
# Run on OMV host (root). Collects storage, docker, codec sample.
set -euo pipefail
OUT="${1:-/tmp/omv-phase0.txt}"
{
  echo "=== hostname ==="
  hostname -f
  uname -a
  echo "=== df ==="
  df -hT
  echo "=== lsblk ==="
  lsblk -f
  echo "=== fstab ==="
  cat /etc/fstab
  echo "=== docker ps ==="
  docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
  echo "=== compose files ==="
  find /srv -name 'docker-compose.yml' 2>/dev/null | head -30
  for c in $(docker ps --format '{{.Names}}' | grep -iE 'plex|sonarr|radarr|qbit|torrent'); do
    echo "=== inspect $c ==="
    docker inspect "$c" --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
  done
  echo "=== GPU ==="
  lspci 2>/dev/null | grep -iE 'vga|3d|display' || true
  ls -la /dev/dri 2>/dev/null || true
  echo "=== du media (depth 2) ==="
  for d in /srv/dev-disk-by-uuid-*; do
    [ -d "$d" ] && du -h --max-depth=2 "$d" 2>/dev/null | head -40
  done
  echo "=== codec sample (20 files) ==="
  command -v ffprobe >/dev/null && find /srv -type f \( -iname '*.mkv' -o -iname '*.mp4' \) 2>/dev/null | head -20 | while read -r f; do
    codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$f" 2>/dev/null || echo unknown)
    size=$(stat -c%s "$f" 2>/dev/null || echo 0)
    echo "$codec $size $f"
  done
} | tee "$OUT"
echo "Wrote $OUT"
