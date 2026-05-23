#!/bin/bash
# Master deploy — requires /home/eric/Documents/omv-media/.ssh_pass (chmod 600)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSH="$ROOT/scripts/omv-ssh.py"

if ! python3 "$SSH" 'echo SSH_OK' 2>/dev/null | grep -q SSH_OK; then
  echo "SSH failed. Create $ROOT/.ssh_pass (one line, root password) and chmod 600."
  echo "See $ROOT/README-SSH.md"
  exit 1
fi

python3 "$SSH" --install-key

upload() {
  local local="$1" remote="$2"
  b64=$(base64 -w0 "$local")
  python3 "$SSH" "echo '$b64' | base64 -d > '$remote' && chmod +x '$remote'"
}

upload "$ROOT/scripts/remote/phase0-inspect.sh" /tmp/phase0-inspect.sh
python3 "$SSH" /tmp/phase0-inspect.sh

upload "$ROOT/scripts/remote/phase1-quickwins.sh" /tmp/phase1-quickwins.sh
python3 "$SSH" "MEDIA_ROOT=\$(find /srv -type d -name Movies -path '*/Media/*' 2>/dev/null | head -1 | xargs dirname) CONFIG_ROOT=\$(find /srv -type d -name plex -path '*/config/*' 2>/dev/null | head -1 | xargs dirname) /tmp/phase1-quickwins.sh"

upload "$ROOT/scripts/remote/phase2-hardlinks.sh" /tmp/phase2-hardlinks.sh
echo "Phase 2: edit MEDIA_HOST/DATA_ROOT from phase0 output, then run phase2 on server manually."

# Recyclarr + Tdarr: copy compose to server appdata (paths adjusted after phase0)
echo "Deploy Recyclarr/Tdarr compose via OMV Compose plugin or copy from $ROOT/compose/"
