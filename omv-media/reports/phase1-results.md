# Phase 1 Results — 2026-05-22

**Pool:** `/srv/dev-disk-by-uuid-a85e8270-9716-45a0-90e5-d8bd29a801e5`  
**Status:** ~83% used, **~3.0 TB free** (was ~88% / ~2.0 TB free before this session’s major cleanup)

## Completed actions

| Action | Approx. reclaim / notes |
|--------|-------------------------|
| Junk purge (`.DS_Store`, `.scr`, samples, `Thumbs.db`) | ~1,100 files removed (prior pass) |
| Non-media downloads quarantined & removed (Batocera, games, fake `.exe`, epub) | **~896 GB** (prior pass) |
| Plex `Cache/` cleared | ~970 MB (prior) + ~100 MB (this pass) |
| Docker dangling prune | ~3 GB images (prior) |
| Imported **Se7en** duplicate download copies removed | **~4 GB** (not hardlinked to library) |
| Fake torrent `.exe` / epub quarantined & deleted | **~2.3 GB** |
| qBit `temp/` cleared | ~203 MB |
| `Media/.recycle` cleared | minimal |
| Library junk (3 files) | small |
| rmlint installed | duplicate report on Downloads (see `/tmp/phase1-rmlint-downloads.txt` on server) |

**Downloads folder:** ~915 GB → **~1 GB** (active torrents only).

## qBittorrent seed hygiene (already configured)

- `GlobalMaxSeedingMinutes=30`
- `MaxRatio=0.05`
- Sonarr/Radarr: `removeCompletedDownloads=true`, `copyUsingHardlinks=true`

## Orphan scan (report only — do not bulk-delete)

- **Tracked:** 1,568 files (Sonarr + Radarr)
- **On-disk videos (excl. Downloads):** ~15k+ files
- **“Orphans”:** 13,910 paths (~10.7 TB)

Most orphans are **library content not in Sonarr/Radarr** (e.g. remux packs, old imports), not safe to delete. Full list on server: `/tmp/phase1-orphans.txt`. Summary copied locally: `reports/phase1-orphans-summary-head.txt`.

**Recommendation:** Add series/movies to Sonarr/Radarr or run a targeted review of top orphan paths—not a blind delete.

## Next (Phase 2+)

- Verify hardlinks on **new** imports (`stat` same inode for torrent + library file).
- Optional TRaSH `/data` layout via OMV Compose plugin (files under `/compose/` are auto-generated).
- Tdarr / Recyclarr deploy if not already running.
