#!/usr/bin/env bash
# Host preflight for Rocky/VirtualBox lab work. Safe to run anywhere.
set -euo pipefail
echo "== Lab preflight =="
command -v VBoxManage >/dev/null 2>&1 && VBoxManage --version || echo "VBoxManage: missing"
command -v git >/dev/null 2>&1 && git --version || echo "git: missing"
df -h . 2>/dev/null | head -n 5 || true
echo "Remember: ISOs/installers/VDIs stay outside this git repo."
