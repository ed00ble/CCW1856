#!/bin/bash
# Orphan scan: video files on disk not referenced by Sonarr/Radarr (report only)
set -euo pipefail
OMV_HOST="${OMV_HOST:-127.0.0.1}"
SONARR_KEY="${SONARR_KEY:?set SONARR_KEY}"
RADARR_KEY="${RADARR_KEY:?set RADARR_KEY}"
MEDIA_ROOT="${MEDIA_ROOT:?set MEDIA_ROOT}"
OUT="${1:-/tmp/orphan-report-$(date +%Y%m).txt}"

python3 << PY
import json, os, urllib.request

SONARR_KEY = "$SONARR_KEY"
RADARR_KEY = "$RADARR_KEY"
MEDIA = "$MEDIA_ROOT"
OMV_HOST = "$OMV_HOST"
OUT = "$OUT"

def get(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return json.load(r)

tracked = set()
for m in get(f"http://{OMV_HOST}:7878/api/v3/movie?apikey={RADARR_KEY}"):
    mf = m.get("movieFile")
    if mf and mf.get("path"):
        tracked.add(mf["path"].replace("/movies/", MEDIA + "/Movies/"))

for s in get(f"http://{OMV_HOST}:8989/api/v3/series?apikey={SONARR_KEY}"):
    for ep in get(f"http://{OMV_HOST}:8989/api/v3/episode?apikey={SONARR_KEY}&seriesId={s['id']}"):
        ef = ep.get("episodeFile")
        if ef and ef.get("path"):
            tracked.add(ef["path"].replace("/tv/", MEDIA + "/TV/"))

on_disk = []
for root, _, files in os.walk(MEDIA):
    if "/Downloads/" in root or "/_quarantine/" in root:
        continue
    for f in files:
        if f.lower().endswith((".mkv", ".mp4", ".avi", ".m4v")):
            on_disk.append(os.path.join(root, f))

orphans = sorted(set(on_disk) - tracked)
with open(OUT, "w") as out:
    out.write(f"Tracked: {len(tracked)}  On-disk: {len(on_disk)}  Orphans: {len(orphans)}\n\n")
    for p in sorted(orphans, key=lambda x: os.path.getsize(x) if os.path.exists(x) else 0, reverse=True):
        sz = os.path.getsize(p) if os.path.exists(p) else 0
        out.write(f"{sz}\t{p}\n")
print(f"Wrote {OUT} ({len(orphans)} orphans)")
PY
