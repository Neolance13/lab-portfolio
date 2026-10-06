# HOW-TO: Tailscale for the lab

**Audience:** operators joining the lab VPN · **Date:** 2026-10-06 · **No passwords / no controlled details in this file.**

This is the short walkthrough. For the deeper design brief, see `INNO-REMOTE-ACCESS.md`.

---

## What Tailscale is here

Tailscale is a private mesh VPN (WireGuard under the hood). Every lab PC, phone, and Rocky VM that joins the same **tailnet** can reach the others by name or IP, even from another network.

| Item | Lab value |
|---|---|
| Lab tailnet | `<lab-tailnet>` |
| Account | the lab GitHub account (name in the private team repo) (console: https://login.tailscale.com ) |
| Plan | Free / personal — **lab use is non-commercial** |
| Admin console | https://login.tailscale.com/admin/machines |

**Do not use any personal Gmail Tailscale account for lab work.** If the Windows PC is still signed into an old Gmail tailnet, switch it to `<lab-tailnet>` (UAC prompt may appear). Lab devices belong on **`<lab-tailnet>` only**.

---

## 1. Install Tailscale on the Windows PC

1. On the lab PC, open https://tailscale.com/download/windows and download the Windows installer.
2. Run the installer. Approve the **UAC** prompt when Windows asks (needs an admin account).
3. When the installer finishes, Tailscale opens a browser sign-in page.

*(A Windows installer is also staged under `Installers/Net/` on the Cyberdeck tree and on the portable USB when present.)*

---

## 2. Join the lab tailnet (`<lab-tailnet>`)

1. Sign in with the **GitHub** account that owns `<lab-tailnet>` (or an invite to that tailnet).
2. If the PC was on a different tailnet before:
   - Right-click the Tailscale tray icon → **Log out** (or **Preferences** → account).
   - Sign in again and pick `<lab-tailnet>`.
3. Accept any “connect this device” prompt.

You should see the Tailscale icon in the system tray turn connected (not grey/disconnected).

---

## 3. Approve the device (if the console asks)

Some tailnets require an admin to approve new machines.

1. Open https://login.tailscale.com/admin/machines
2. Find the new PC (name like `desktop-…` or the hostname).
3. Click **Approve** if the status is pending.
4. Optional but useful: disable key expiry on long-lived lab machines so they stay on after 180 days.

---

## 4. Check that you are on the lab VPN

Open **PowerShell** or **Command Prompt** and run:

```text
tailscale status
```

You want to see:

- Your PC listed as connected
- Other lab machines (for example the Rocky lab VM) with `100.x.y.z` addresses
- The tailnet name matching `<lab-tailnet>`

Also useful:

```text
tailscale ip -4
```

That prints this machine’s Tailscale IPv4 (`100.…`).

If `tailscale` is not found in PATH, open “Tailscale” from the Start menu once, or use the full path under `C:\Program Files\Tailscale\`.

---

## 5. Reach lab nodes (MagicDNS or IP)

Once both ends are on `<lab-tailnet>`:

| Method | Example |
|---|---|
| **MagicDNS name** | `ssh rocky@<lab-vm>` (exact hostname as shown in `tailscale status`) |
| **Tailscale IP** | `ssh rocky@100.x.y.z` |

Tips:

- Prefer the **name** from `tailscale status` — MagicDNS is enabled on most Free tailnets.
- Ping first: `ping <lab-vm>` or `ping 100.x.y.z`.
- Windows Home cannot host RDP. For a full desktop into the PC, the lab plan is **RustDesk over Tailscale** (see `INNO-REMOTE-ACCESS.md`). For files and a shell into Rocky, use SSH/SFTP below.

---

## 6. Remote files: SFTP / SSH over the VPN

Traffic stays inside the Tailscale tunnel. You do **not** open SSH to the public internet.

### From Windows to a Rocky lab node

1. Confirm both devices appear in `tailscale status`.
2. SSH (shell):

   ```text
   ssh <user>@<magicdns-or-100-ip>
   ```

3. SFTP (files) — pick one:
   - **WinSCP** or **FileZilla**: protocol SFTP, host = MagicDNS name or `100.…`, port `22`, your Linux user.
   - **PowerShell** (OpenSSH client):

     ```text
     sftp <user>@<magicdns-or-100-ip>
     ```

4. Copy examples once connected:

   ```text
   put C:\path\to\local-file /home/<user>/
   get /home/<user>/remote-file C:\path\to\
   ```

### What belongs on Tailscale

- Docs, scripts, open-source tools, non-controlled configs.
- **Do not** push controlled media, controlled RF app install trees, or secrets over any cloud path. Those stay on local disk / the portable USB only.

---

## Quick checklist

- [ ] Tailscale installed on the PC (UAC approved)
- [ ] Signed into `<lab-tailnet>` (not a personal Gmail tailnet)
- [ ] Device approved in the admin console if needed
- [ ] `tailscale status` shows lab nodes as online
- [ ] SSH or SFTP works to a Rocky node by name or `100.…` IP

---

## If something fails

| Symptom | What to try |
|---|---|
| Tray icon disconnected | Right-click → Connect; check Wi-Fi/Ethernet |
| Wrong tailnet / old Gmail account | Log out → sign in → choose `<lab-tailnet>` |
| Machine “pending” | Approve it at https://login.tailscale.com/admin/machines |
| `tailscale` not found | Reopen a new terminal after install; or Start → Tailscale |
| Can ping `100.…` but SSH fails | Confirm `sshd` is running on the Linux node; user/name correct |
| UAC blocks install or switch | Use the admin Microsoft account on the PC to approve |

Still stuck: see `INNO-REMOTE-ACCESS.md` and `NETWORK-SOP.md`.
