# Phases 2–4 Results — 2026-05-23

## Phase 2 — Pipeline

| Item | Status |
|------|--------|
| Same filesystem for downloads + library | Confirmed (ext4 on `md0`) |
| `copyUsingHardlinks` in Sonarr/Radarr | Already `true` |
| Hardlink FS test | **OK** (cross-dir link Downloads ↔ Movies) |
| qBit categories | `tv-sonarr`, `radarr` (Sonarr/Radarr clients) |
| Category folders | `Downloads/Torrents/{tv-sonarr,radarr}` |
| TRaSH `/data` unified mount | **Not applied** — OMV auto-generates `/compose/*.yml`; current separate mounts work for hardlinks on same pool |
| Recyclarr v8 | **Synced** — templates `web-1080p` (Sonarr), `hd-bluray-web` (Radarr) |

Configs: `/compose/recyclarr/config/configs/`

## Phase 3 — Tdarr

| Item | Status |
|------|--------|
| `tdarr` + `tdarr_node` | Running (~41h uptime) |
| Library mount | `/library` → full `Media` share |
| `/dev/dri` | Passed to containers |
| Encode policy | Documented in [tdarr/README.md](../tdarr/README.md) |
| UI libraries & flows | **You:** add Movies/TV paths and flows at http://192.168.2.121:8265 (Option A safe seeding) |

## Phase 4 — Hygiene

| Item | Schedule / location |
|------|---------------------|
| Recyclarr sync | Daily 4:00 — `/etc/cron.d/omv-media` |
| Orphan scan | Monthly 1st 5:00 — `/usr/local/sbin/omv-orphan-scan.sh` |
| Config backup | Daily 2:00 → `Media/Backups/config/` |
| OMV disk alert | Set in UI: **System → Notification → Filesystem** → warn ≥85% |

Logs: `/var/log/recyclarr-sync.log`, `/var/log/omv-orphan-scan.log`, `/var/log/omv-config-backup.log`
