# OMV Media Stack — Current State

**Host:** `omvt300` @ `192.168.2.121`  
**Pool:** `/srv/dev-disk-by-uuid-a85e8270-9716-45a0-90e5-d8bd29a801e5` (~17 TB, **~3.0 TB free**, ~82% used)  
**Updated:** 2026-05-23

## Services

| Service | Port | Notes |
|---------|------|-------|
| Plex | 32400 | tmpfs transcode |
| Sonarr | 8989 | hardlinks on |
| Radarr | 7878 | hardlinks on |
| qBittorrent | 8080 | `qbittorrentvpn` |
| Tdarr | 8265 | server + node |
| Recyclarr | — | cron daily sync |

**Compose:** `/compose/{sonarr,radarr,qbittorrentvpn,plex,tdarr,recyclarr}/`

## Storage

| Path | Container |
|------|-----------|
| `.../Media/Movies` | `/movies` |
| `.../Media/TV` | `/tv` |
| `.../Media/Downloads/Torrents` | `/downloads` |
| `.../Media` (Tdarr) | `/library` |

## Phase status

| Phase | Status |
|-------|--------|
| 0 Inspect | Done |
| 1 Quick wins | Done — [phase1-results.md](reports/phase1-results.md) |
| 2 Pipeline | Done — Recyclarr synced, hardlinks verified |
| 3 Tdarr | Deployed — **finish libraries/flows in UI** — [tdarr/README.md](tdarr/README.md) |
| 4 Hygiene | Done — cron + backups — [phase2-4-results.md](reports/phase2-4-results.md) |

## Your action items

1. **Tdarr:** http://192.168.2.121:8265 — add libraries, health check, then encode waves per README.
2. **OMV:** Enable filesystem notification at 85% used.
3. **Test hardlink:** After next download, `stat -c '%i' <file-in-downloads> <file-in-library>` — same inode = success.
