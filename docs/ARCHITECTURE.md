# Architecture: where things live

## GitHub (this repo) — public

- Runbooks and checklists
- Non-secret scripts
- Architecture and process notes suitable for a resume / portfolio

## Google Drive — BotTools

- Day-to-day docs and activity logs
- Non-controlled tooling indexes
- Shared collaboration without putting disks/installers in git

## Local disk (prefer non-synced for VMs)

- Rocky Linux ISOs
- VirtualBox machine folders (VDI) and OVA exports
- Vendor installers (including any ITAR-marked packages)

## Rules of thumb

1. If it is multi-gigabyte or an installer, it does not go in git.
2. If it is marked ITAR / export-controlled, it does not go on personal public cloud without an approved policy.
3. Prefer documenting *how* to install over storing the installer.
