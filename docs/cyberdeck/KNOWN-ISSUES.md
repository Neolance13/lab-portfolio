# Cyberdeck Known Issues (public)

| # | Issue | Workaround / status |
|---|-------|---------------------|
| 1 | GUI installer fails with `no $DISPLAY` under root/sudo | Run as the normal desktop user from a GUI terminal |
| 2 | A first-build transfer ISO was bad media | Resolved: rebuilt ISO used; bad copy archived (not deleted) |
| 3 | VM folder was on a cloud-sync path | **Resolved** - moved to local `VMs/` with a second local copy |
| 4 | Temporary host transfer listener + firewall rule | Cleanup pending |
| 5 | Extension Pack licensing (personal/educational only) | Decided 2026-10-05: keep (personal/non-commercial lab use). Not needed for USB on VirtualBox 7.2; revisit before other use |
| 6 | udev `0666` and firewalld `trusted` are permissive | OK for the lab; move to a restrictive zone before any release or bridged/shared use (tracked) |
| 7 | USB filters configured for RTL-SDR and HackRF | Add one filter per new SDR device family |
