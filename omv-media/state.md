# OMV Media Stack — Current State

**Host:** `omvt300` @ `192.168.2.121` (TerraMaster / Debian 11, kernel 6.1)  
**Inspected:** 2026-05-21 (SMB guest + Sonarr/Radarr API; SSH pending `.ssh_pass`)  
**Pool (SMB):** ~16.3 TB total, ~2.04 TB free (`17510163244` × 1K blocks)

## Services (reachable on LAN)

| Service   | Port  | Version / notes        |
|-----------|-------|------------------------|
| OMV       | 80    | Workbench              |
| Plex      | 32400 | Running                |
| Sonarr    | 8989  | 4.0.15.2941 (Docker)   |
| Radarr    | 7878  | 6.0.4.10291 (Docker)   |
| qBittorrent | 8080 | VPN container `QBittorrentVPN` |
| Prowlarr  | (config present) | |

**API keys (from SMB `config` share):** stored in `smb-cache/*/config.xml` — use for automation, do not commit.

## SMB layout (guest read/write on `config`)

| Share   | Role |
|---------|------|
| `//192.168.2.121/Media` | Library: `Movies/`, `TV/`, `Downloads/Torrents/` |
| `//192.168.2.121/config` | App configs: `sonarr/`, `radarr/`, `plex/`, `QBittorrentVPN/`, `prowlarr/` |

## Container paths (*arr API — not TRaSH unified `/data` yet)

**Sonarr root folders:** `/tv`, `/tv/Series`, `/tv/Kids TV`, `/tv/TV_Archive`, `/tv/Documentaries`  
**Radarr root folders:** `/movies`, `/movies/General`, archives, genre folders, `/media/...`  
**qBittorrent:** `Downloads\SavePath=/downloads/`  
**Categories (qBit):** `tv-sonarr`, `radarr`, `readarr`, `readarr-audiobooks`, `games` → `/downloads2/`  
**Sonarr → qBit category:** `tv-sonarr`  
**Radarr → qBit category:** `radarr`  
**Remote path mappings:** none  
**Completed download removal:** enabled on both *arr clients  

## Pipeline gaps (space impact)

1. **No unified mount** — downloads (`/downloads/`) vs library (`/tv`, `/movies`) likely different bind mounts → **copy import, not hardlinks** → doubles disk use while seeding.
2. **Many unmapped folders** — large `unmappedFolders` lists on root folders; Sonarr DB shows very few tracked episode files vs disk content.
3. **Downloads folder clutter** — `Media/Downloads/Torrents/` contains games, ebooks, `.scr` partials, non-media (reclaim candidates).
4. **qBit seed limits** — `GlobalMaxSeedingMinutes=30`, `MaxRatio=0.05` (good); categories not aligned to TRaSH `sonarr`/`radarr` names.

## SMB ↔ container mapping (inferred)

| SMB (Media share)        | Likely container path |
|--------------------------|------------------------|
| `Movies/`                | `/movies`              |
| `TV/`                    | `/tv`                  |
| `Downloads/Torrents/`    | `/downloads/`          |

**Confirm via SSH:** `docker inspect` bind mounts for plex, sonarr, radarr, qbittorrent.

## Hardware / transcode (pending SSH)

Run on server: `lspci | grep -i vga; ls /dev/dri 2>/dev/null` for QSV/VAAPI Tdarr decision.

## Compose file locations (pending SSH)

Typical OMV-extras: `/srv/dev-disk-by-uuid-*/compose/<stack>/docker-compose.yml`  
Find with: `find /srv -name docker-compose.yml 2>/dev/null | head -20`

## Next step

Create `/home/eric/Documents/omv-media/.ssh_pass` (one line, root password, `chmod 600`), reply **ready**, then run:

```bash
python3 /home/eric/Documents/omv-media/scripts/omv-ssh.py --install-key
bash /home/eric/Documents/omv-media/scripts/remote/phase0-inspect.sh  # via omv-ssh wrapper
```
