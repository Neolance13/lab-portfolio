#!/usr/bin/env bash
# Export a VirtualBox VM to OVA. Run on the host that has VirtualBox.
# Usage: ./vbox-export-ova.sh <vm-name> [output-path.ova]
set -euo pipefail
VM_NAME="${1:?vm name required}"
OUT="${2:-${VM_NAME}.ova}"
if ! command -v VBoxManage >/dev/null 2>&1; then
  echo "VBoxManage not found in PATH" >&2
  exit 1
fi
VBoxManage export "$VM_NAME" --output "$OUT"
echo "Exported: $OUT"
