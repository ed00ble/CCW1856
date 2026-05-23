# SSH access for omv-media automation

The Cursor agent **cannot** see `export OMV_SSH_PASSWORD` from your interactive terminal.

Use **one** of these:

## Option A — password file (recommended)

```bash
echo 'YOUR_ROOT_PASSWORD' > /home/eric/Documents/omv-media/.ssh_pass
chmod 600 /home/eric/Documents/omv-media/.ssh_pass
```

Then reply **ready** in chat.

## Option B — inline for a single command

```bash
OMV_SSH_PASSWORD='YOUR_ROOT_PASSWORD' python3 /home/eric/Documents/omv-media/scripts/omv-ssh.py 'hostname'
```

## Install key (after password works)

```bash
python3 /home/eric/Documents/omv-media/scripts/omv-ssh.py --install-key
```

Host: `root@192.168.2.121` (override with `OMV_HOST` / `OMV_USER`).
