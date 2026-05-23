#!/bin/bash
# Run a remote script on OMV via omv-ssh.py
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${1:?usage: run-remote.sh scripts/remote/foo.sh}"
REMOTE="/tmp/omv-$(basename "$SCRIPT")"
python3 "$DIR/scripts/omv-ssh.py" "cat > $REMOTE" < "$DIR/$SCRIPT"
python3 "$DIR/scripts/omv-ssh.py" "chmod +x $REMOTE && $REMOTE"
