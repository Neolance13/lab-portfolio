# How-to: Rocky Linux SDR guest on VirtualBox (public)

Generic procedure; controlled RF software specifics are kept in private docs.

## 1. Create the guest

| Setting | Value |
|---------|-------|
| Type | Linux / Red Hat (64-bit) |
| Memory / CPU | 8192 MB / 4 |
| Disk | 60 GB VDI under local `VMs/` |
| Network | NAT |
| Storage | SATA: disk port 0, optical port 1 |
| USB | xHCI (USB 3.0) - built into VirtualBox 7.2, no Extension Pack needed |

Install Rocky Linux 10.x from a local DVD ISO (graphical install), create an operator desktop account, snapshot `clean-os`.

## 2. Deliver software offline

Build a transfer ISO under `Images/Xfer`, attach it to the guest optical drive, copy the installer into the operator's home directory. Run GUI installers **as the normal desktop user from a terminal in the desktop session** - not root/sudo (fails with `no $DISPLAY`).

## 3. Device access

```bash
# /etc/udev/rules.d/99-lab-devices.rules  (illustrative)
SUBSYSTEM=="usb", MODE="0666"
KERNEL=="ttyUSB[0-9]*", MODE="0666"
KERNEL=="ttyACM[0-9]*", MODE="0666"

# /etc/modprobe.d/rtl-sdr-blacklist.conf
blacklist dvb_usb_rtl28xxu
```

```bash
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG wheel,dialout <operator>
sudo firewall-cmd --set-default-zone=trusted   # isolated NAT lab only
```

## 4. USB passthrough

Add one USB filter per SDR vendor, e.g. RTL-SDR `0bda:2838`. Avoid catch-all filters so the image stays SDR-agnostic.

## 5. Package

Power off, ensure the folder is under `VMs/`, then:

```bash
VBoxManage export "<vm-name>" -o VMs/<vm-name>.ova
```

OVAs, ISOs, and installers never go in git.
