# OMV 6 → 7 upgrade walkthrough (omvt300)

**Server:** `192.168.2.121` · **Current:** OMV 6.9.x on Debian 11 · **Target:** OMV 7 (Sandworm) on Debian 12

Use this during a **maintenance window** (1–3 hours; Plex/*arr down briefly).

---

## Phase A — Before you touch anything

### A1. Pre-flight checklist

| Check | Requirement | How |
|-------|-------------|-----|
| Root disk `/` | **≥15 GB free** (≥20 GB safer) | `df -h /` |
| Pool free space | Enough for backup folder (~35 GB if full Plex config) | `df -h` on pool mount |
| UPS / power | Stable power | — |
| Browser | Hard-refresh after upgrade (Ctrl+Shift+R) | — |
| Clients | Note who uses SMB/Plex during window | — |

### A2. Pause heavy I/O (recommended)

In **OMV Workbench → Services → Compose** (or SSH):

```bash
docker stop tdarr tdarr_node recyclarr 2>/dev/null || true
# Optional: stop *arr during backup only
# docker stop sonarr radarr qbittorrentvpn
```

Leave Plex running until backup starts if you want zero downtime until the window.

### A3. Note current state

```bash
hostname
cat /etc/debian_version
omv-version 2>/dev/null || dpkg -l openmediavault | tail -1
docker ps --format 'table {{.Names}}\t{{.Status}}'
ls /compose/
```

---

## Phase B — Backup (do all of these)

### B1. OMV Workbench system backup (manual, UI)

1. Open **https://192.168.2.121/**
2. **System → Backup**
3. Create backup → download or save to a **second location** (PC, NAS, not only the same pool)

This captures OMV settings in OMV’s native format (restorable from Workbench).

### B2. Automated server backup (script on pool)

On the server (or from your Mac via SSH):

```bash
/tmp/omv-pre-upgrade-backup.sh
```

**Creates:** `Media/Backups/omv-upgrade-YYYYMMDD-HHMMSS/` containing:

| Artifact | Purpose |
|----------|---------|
| `openmediavault-etc.tar.gz` | `/etc/openmediavault/` |
| `omv-confdb.xml` | Config database export |
| `compose-stacks.tar.gz` | All `/compose/*` stacks |
| `config/{sonarr,radarr,qBittorrentVPN,plex}/` | App configs (Plex cache excluded) |
| `fstab`, `omv-media` cron, `docker-ps.txt`, `docker-inspect.json` | Recovery hints |

**Verify:**

```bash
ls -la "$POOL/Media/Backups/omv-upgrade-"*/
cat "$POOL/Media/Backups/omv-upgrade-"*/MANIFEST.txt
```

### B3. Existing nightly backups (already in place)

- **Path:** `Media/Backups/config/` (cron rsync ~2am)
- **Not a substitute** for B1+B2 before a major OS upgrade.

### B4. Optional: copy backup off-box

From your Mac:

```bash
rsync -av --progress root@192.168.2.121:'/srv/dev-disk-by-uuid-.../Media/Backups/omv-upgrade-*' ~/Backups/omvt300/
```

---

## Phase C — Upgrade on OMV 6 (still Debian 11)

SSH as **root**:

```bash
omv-upgrade
```

- Accept package changes when prompted.
- Fix any errors before continuing.

Optional (if you use Salt-managed config heavily):

```bash
omv-salt deploy run
```

---

## Phase D — Release upgrade (Debian 11 → 12, OMV 6 → 7)

**Point of no return.** Ensure B1+B2 finished.

```bash
omv-release-upgrade
```

- Read prompts carefully; confirm disk space when asked.
- Expect **30–90+ minutes**; SSH may drop during kernel/package steps.
- Do **not** reboot manually mid-script unless it tells you to.

When the script finishes, it usually requests a reboot:

```bash
reboot
```

After reboot, SSH back in:

```bash
omv-upgrade
```

Then in browser: **hard refresh** Workbench (Ctrl+Shift+R).

---

## Phase E — Post-upgrade fixes (OMV 7)

### E1. Reinstall omv-extras

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash
```

Follow prompts in Workbench for **openmediavault-omvextrasorg** if needed.

### E2. Run 6→7 migration helper

```bash
wget -O /tmp/fix6to7.sh https://raw.githubusercontent.com/OpenMediaVault-Plugin-Developers/Scripts/master/fix6to7upgrade
bash /tmp/fix6to7.sh
```

### E3. Compose / Docker

1. **Services → Compose** — open each stack, **Save** then **Up** if stacks show errors.
2. Verify **remotemount** (music CIFS) still mounts.
3. Confirm **Recyclarr** cron: `/etc/cron.d/omv-media`

```bash
docker ps
docker start tdarr tdarr_node recyclarr 2>/dev/null || true
```

### E4. Smoke tests

| Service | URL / check |
|---------|-------------|
| OMV | https://192.168.2.121/ |
| Plex | :32400/web |
| Sonarr | :8989 |
| Radarr | :7878 |
| qBittorrent | WebUI via VPN container |
| Tdarr | :8265 |
| SMB | `//192.168.2.121/Media` |

---

## Rollback (if upgrade fails badly)

1. **Do not** delete `Media/Backups/omv-upgrade-*` until stable for a week.
2. OMV 7 downgrade to 6 is **not** officially supported — recovery is restore-from-backup or reinstall OS.
3. Worst case: reinstall OMV 7 on OS disk, restore pool (data intact), re-import compose from `compose-stacks.tar.gz` and app configs from backup.

---

## Quick command reference (order)

```text
1. Pre-flight (df, stop tdarr)
2. Workbench System Backup (UI)
3. /tmp/omv-pre-upgrade-backup.sh
4. omv-upgrade
5. omv-release-upgrade
6. reboot → omv-upgrade
7. omv-extras install + fix6to7upgrade
8. Compose Up + docker ps + app URLs
```

---

## Your server specifics

- **Pool:** `/srv/dev-disk-by-uuid-a85e8270-9716-45a0-90e5-d8bd29a801e5`
- **Compose:** `/compose/{sonarr,radarr,qbittorrentvpn,plex,tdarr,recyclarr}/`
- **Plugins:** omv-extras, compose, remotemount (music → `//syn_ds.local/music`)
- **SSH:** `ssh root@192.168.2.121` (key from `eric-iMac`)
