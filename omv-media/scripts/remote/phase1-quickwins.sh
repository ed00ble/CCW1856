#!/bin/bash
# Phase 1: low-risk space wins on OMV (run as root)
set -euo pipefail
MEDIA_ROOT="${MEDIA_ROOT:-}"
CONFIG_ROOT="${CONFIG_ROOT:-}"

# Auto-detect largest media mount under /srv
if [ -z "$MEDIA_ROOT" ]; then
  for m in /srv/dev-disk-by-uuid-*/sharedfolders/Media /srv/dev-disk-by-uuid-*/Media; do
    [ -d "$m/Movies" ] && MEDIA_ROOT="$m" && break
  done
fi
[ -n "$MEDIA_ROOT" ] || { echo "Set MEDIA_ROOT to Media share path"; exit 1; }

QUAR="${MEDIA_ROOT}/_quarantine"
mkdir -p "$QUAR"
REPORT="/tmp/phase1-$(date +%Y%m%d).log"
exec > >(tee -a "$REPORT") 2>&1

echo "=== Phase 1 quick wins $(date) ==="
echo "MEDIA_ROOT=$MEDIA_ROOT"

echo "--- Samples / junk (dry-run list) ---"
find "$MEDIA_ROOT" -type f \( \
  -iname 'sample*.mkv' -o -iname 'sample*.mp4' -o \
  -iname '*.rar' -o -iname '*.r00' -o -iname '*.r01' -o \
  -iname '*.nfo.bak' -o -iname '*.scr' -o -iname 'Thumbs.db' -o -iname '.DS_Store' \
\) 2>/dev/null | tee /tmp/phase1-delete-candidates.txt | wc -l

echo "--- Deleting candidates (reversible: check /tmp/phase1-delete-candidates.txt) ---"
xargs -r -a /tmp/phase1-delete-candidates.txt rm -fv

echo "--- Plex photo transcoder cache ---"
for p in "$CONFIG_ROOT"/plex/*/Cache/PhotoTranscoder \
         /config/plex/Cache/PhotoTranscoder; do
  [ -d "$p" ] && du -sh "$p" && rm -rf "${p:?}"/* && echo "cleared $p"
done

echo "--- Docker prune (dangling only) ---"
docker system prune -f

echo "Report: $REPORT"
