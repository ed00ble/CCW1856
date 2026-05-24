#!/bin/bash
# Full pre-OMV7 backup — run on omvt300 as root
set -euo pipefail
POOL="/srv/dev-disk-by-uuid-a85e8270-9716-45a0-90e5-d8bd29a801e5"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$POOL/Media/Backups/omv-upgrade-$STAMP"
mkdir -p "$DEST"
LOG="$DEST/backup.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== OMV pre-upgrade backup $STAMP ==="
echo "Destination: $DEST"

# 1. OMV database + config
echo "--- OMV config ---"
tar czf "$DEST/openmediavault-etc.tar.gz" /etc/openmediavault/
omv-confdbadm dump > "$DEST/omv-confdb.xml" 2>/dev/null || true

# 2. Compose stacks
echo "--- Docker compose ---"
tar czf "$DEST/compose-stacks.tar.gz" /compose/

# 3. App configs (already backed nightly; refresh now)
echo "--- App configs ---"
mkdir -p "$DEST/config"
rsync -a "$POOL/config/sonarr/" "$DEST/config/sonarr/"
rsync -a "$POOL/config/radarr/" "$DEST/config/radarr/"
rsync -a "$POOL/config/QBittorrentVPN/" "$DEST/config/QBittorrentVPN/"
rsync -a --exclude "Library/Application Support/Plex Media Server/Cache" \
  "$POOL/config/plex/" "$DEST/config/plex/"

# 4. Cron + fstab + network hints
echo "--- System hints ---"
cp -a /etc/fstab "$DEST/fstab"
cp -a /etc/cron.d/omv-media "$DEST/" 2>/dev/null || true
docker ps -a > "$DEST/docker-ps.txt"
docker inspect plex sonarr radarr qbittorrentvpn tdarr tdarr_node recyclarr 2>/dev/null \
  > "$DEST/docker-inspect.json" || true
df -h > "$DEST/df.txt"
lsblk -f > "$DEST/lsblk.txt"
dpkg -l | grep -iE 'openmediavault|omv' > "$DEST/omv-packages.txt"

# 5. Manifest
du -sh "$DEST"/* | sort -hr > "$DEST/MANIFEST.txt"
echo "DONE: $DEST"
cat "$DEST/MANIFEST.txt"
