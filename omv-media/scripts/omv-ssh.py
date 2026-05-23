#!/usr/bin/env python3
"""Run a command on OMV via password SSH.

  export OMV_SSH_PASSWORD='your-root-password'
  python3 omv-ssh.py 'df -hT'
  python3 omv-ssh.py --install-key
"""
import os
import sys

import pexpect

HOST = os.environ.get("OMV_HOST", "192.168.2.121")
USER = os.environ.get("OMV_USER", "root")
def _load_password() -> str:
    pw = os.environ.get("OMV_SSH_PASSWORD", "").strip()
    if pw:
        return pw
    pass_file = os.environ.get(
        "OMV_SSH_PASS_FILE",
        os.path.join(os.path.dirname(__file__), "..", ".ssh_pass"),
    )
    pass_file = os.path.abspath(pass_file)
    if os.path.isfile(pass_file):
        with open(pass_file) as f:
            return f.read().strip()
    return ""


PASSWORD = _load_password()
PUBKEY = os.path.expanduser("~/.ssh/id_ed25519.pub")
KNOWN = os.path.expanduser("~/.ssh/known_hosts")
TIMEOUT = int(os.environ.get("OMV_SSH_TIMEOUT", "180"))


def run_ssh(command: str) -> tuple[int, str]:
    if not PASSWORD:
        return 1, (
            "No password. Either: export OMV_SSH_PASSWORD='...' OR create "
            f"{os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '.ssh_pass'))} "
            "(one line, chmod 600)."
        )
    ssh = (
        f"ssh -o StrictHostKeyChecking=accept-new "
        f"-o UserKnownHostsFile={KNOWN} {USER}@{HOST}"
    )
    child = pexpect.spawn(ssh, timeout=TIMEOUT, encoding="utf-8")
    while True:
        idx = child.expect(
            [
                r"Are you sure you want to continue connecting",
                r"[Pp]assword:",
                r"#",
                r"\$",
                pexpect.EOF,
                pexpect.TIMEOUT,
            ],
            timeout=60,
        )
        if idx == 0:
            child.sendline("yes")
        elif idx == 1:
            child.sendline(PASSWORD)
        elif idx in (2, 3):
            break
        else:
            return 1, child.before or "SSH failed"

    child.sendline(command)
    child.expect([r"#", r"\$"], timeout=TIMEOUT)
    output = (child.before or "").strip()
    child.sendline("exit")
    child.close()
    print(output)
    return 0, output


def install_key() -> int:
    if not os.path.isfile(PUBKEY):
        print(f"Missing {PUBKEY}", file=sys.stderr)
        return 1
    with open(PUBKEY) as f:
        key = f.read().strip()
    cmd = (
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && "
        f"grep -qF '{key}' ~/.ssh/authorized_keys 2>/dev/null || "
        f"echo '{key}' >> ~/.ssh/authorized_keys; "
        "chmod 600 ~/.ssh/authorized_keys; echo KEY_INSTALLED"
    )
    rc, out = run_ssh(cmd)
    if "KEY_INSTALLED" in out:
        print("SSH key installed on OMV.")
        return 0
    return rc or 1


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    if sys.argv[1] == "--install-key":
        return install_key()
    rc, _ = run_ssh(" ".join(sys.argv[1:]))
    return rc


if __name__ == "__main__":
    sys.exit(main())
