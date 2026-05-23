#!/bin/bash
# Monthly orphan scan: files on disk not in Sonarr/Radarr DB (report only)
set -euo pipefail
OMV_HOST="${OMV_HOST:-192.168.2.121}"
SONARR_KEY="${SONARR_KEY:?set SONARR_KEY}"
RADARR_KEY="${RADARR_KEY:?set RADARR_KEY}"
MEDIA_ROOT="${MEDIA_ROOT:?set MEDIA_ROOT}"
OUT="${1:-/tmp/orphan-report-$(date +%Y%m).txt}"

tracked=$(mktemp)
findlist=$(mktemp)

curl -fsS "http://${OMV_HOST}:8989/api/v3/episodefile?apikey=${SONARR_KEY}&pageSize=100000" \
  | python3 -c "import json,sys; [print(x['path']) for x in json.load(sys.stdin)]" >>"$tracked" 2>/dev/null || true
curl -fsS "http://${OMV_HOST}:7878/api/v3/moviefile?apikey=${RADARR_KEY}&pageSize=100000" \
  | python3 -c "import json,sys; [print(x['path']) for x in json.load(sys.stdin)]" >>"$tracked" 2>/dev/null || true

find "$MEDIA_ROOT" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) >"$findlist"

{
  echo "Orphan scan $(date)"
  echo "Tracked: $(wc -l <"$tracked")  On-disk videos: $(wc -l <"$findlist")"
  comm -23 <(sort "$findlist") <(sort "$tracked") | head -500
} | tee "$OUT"
echo "Wrote $OUT"
rm -f "$tracked" "$findlist"
