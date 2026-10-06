# Cyberdeck Filing SOP (public summary)

**Status:** v3.6 - 2026-10-05  
**Audience:** Contributors reviewing the public lab portfolio

Sanitized excerpt of the private Cyberdeck Filing and Storage SOP. Controlled product names, ITAR paths, and host identifiers are omitted. Full operator SOP lives in the private `cyberdeck` repository and local lab mirrors.

## Canonical homes (summary)

| Asset class | Home |
|-------------|------|
| Tool installers | `Installers/{Net,RF,Dev,Print3D,Design,Apps}` - local only |
| Distro / transfer ISOs | `Images/ISOs`, `Images/Xfer` - local only |
| Virtual machines | `VMs/` - local only |
| Active OVA / snapshot working copies | `VMs/exports/` |
| Retired docs / installers / snapshots / OVAs | `Archive/YYYY-MM-DD/{docs,installers,snapshots,ova}/` |
| RF captures | `RF/` - local only |
| Active projects | `Projects/<Name>` |
| Operator docs | `Docs/` |
| Credentials / license material | Local secrets file only - gitignored, never mirrored |
| Bot rules / task owners | [BOT-SOP.md](BOT-SOP.md), [TASK-REGISTRY.md](TASK-REGISTRY.md) |

## OneDrive is dead / four approved locations

Nothing new goes to OneDrive. The lab VM folder was moved off cloud sync to local `VMs/` (2026-10-05) with a second local copy.

| # | Location | What goes there |
|---|----------|-----------------|
| 1 | Local (primary disk + second local copy) | Everything |
| 2 | Removable USB take-with-me kit | Travel copy - physical only, no secrets |
| 3 | GitHub (private docs repo; scrubbed public portfolio) | Docs and scripts only |
| 4 | Google Drive | Docs only |

Controlled material, installers, VM images and secrets: Local and USB only.

## Archive and Backups

- Superseded docs, old installers, retired snapshots/OVAs move into dated buckets under `Archive/YYYY-MM-DD/...` - **never delete**.
- Every archive move is logged in the changelog.
- Never touch application installs, games, or OS/system files for filing.
- Docs and scripts mirror: local lab + private docs repo; sanitized public copies OK under this portfolio folder.
- Controlled / export-restricted installers and VM images: **second LOCAL copy required**, never cloud. Second copy assigned 2026-10-05 on a separate local disk; VM disks are copied only after power-off.
- Active OVA/snapshot landing: `VMs/exports/` (working copies); retired copies go to Archive.
- A weekly backup check routine confirms Archive buckets, exports, second-local-copy reachability, and that controlled media is not on cloud-sync volumes.

## Hard rules

- Controlled software, ISOs, VM disks, large RF captures: local disk only - never git or cloud sync.
- Secrets and license material: local secrets file only (gitignored; never in docs, git, or Drive). Docs say "see local credentials file".
- Prefer dated Archive buckets over deletion.
- VM snapshots only when the VM is powered off (a live snapshot on a slow cloud-sync path failed).

*Cyberdeck Filing SOP (public summary) v3.6*
