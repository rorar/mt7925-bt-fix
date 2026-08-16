# MT7925 Bluetooth Fix

A community-maintained script to fix MediaTek MT7925 Bluetooth not initializing on Linux.

> ⚠️ **Note:** This script was initially created with AI assistance (vibe-coded). It works on the author's system but may need adjustments for your setup. Contributions welcome!

## The Problem

The MediaTek MT7925 (Filogic 360) is a Wi-Fi 7 + Bluetooth 5.3 PCIe combo chip found in many modern laptops. On Linux, the Bluetooth portion often fails to initialize on boot, leaving you with no Bluetooth adapter.

The relevant kernel modules are:

- **WiFi:** `mt7925e`
- **Bluetooth:** `btmtk`, `btusb`

**Symptoms:**

- `bluetoothctl power on` returns "No default controller available"
- `/sys/class/bluetooth` is empty or missing
- WiFi works fine, but Bluetooth is nowhere to be found

## Quick Start

### Step 1: Confirm You Actually Have an MT7925 ⚠️

**Your laptop's model name does not tell you which wireless chip is inside.** Vendors ship the same model with different modules depending on batch and region — the Lenovo Yoga 7 14AKP10 in the table below exists with both MediaTek and Realtek wireless. Check the hardware, not the model number:

```bash
lspci -nn | grep -i network
```

You are looking for `MediaTek` and `MT7925`, PCI ID `14c3:7925`. If you see a different vendor, this script will not help you and the installer will refuse to run:

| What you see                   | Driver        | This script applies |
| ------------------------------ | ------------- | ------------------- |
| `MediaTek ... MT7925 [14c3:7925]` | `mt7925e`  | ✅ Yes              |
| `Realtek ... RTL89xx [10ec:*]`    | `rtw89_*`  | ❌ No               |
| `Intel ... Wi-Fi [8086:*]`        | `iwlwifi`  | ❌ No               |
| `Qualcomm ... [17cb:*]`           | `ath1*`    | ❌ No               |

It is also worth checking which driver actually serves your Bluetooth, since the combo chip's BT side is what this fixes:

```bash
journalctl -b -k | grep -i "bluetooth: hci0"
```

`btmtk` in that output means MediaTek. If you instead see `RTL:` (Realtek) or `btintel` (Intel), you have a different chip and a different problem.

### Step 2: Try This First (No Install Needed!) ⚡

Before installing anything, try the **power cycle fix** — it may solve your problem without needing the script:

```bash
# 1. Full power cycle: Shut down, unplug, hold power button for 30 seconds
# 2. Boot into UEFI/BIOS and ensure WiFi/Bluetooth is enabled
# 3. Toggle it OFF → Save & Exit → Re-enter UEFI → Toggle ON → Save & Exit
# 4. Reboot and test Bluetooth
```

This resets the internal USB BT controller's GPIO state, which can get stuck after a normal shutdown.

**Did Bluetooth work after the power cycle?**

- ✅ **Yes** → You're done! No script needed. 🎉
- ❌ **No** → Continue with installation below.

### Step 3: Install the Fix (If Power Cycle Didn't Work)

```bash
# Download and run
curl -sSL https://raw.githubusercontent.com/rorar/mt7925-bt-fix/main/install.sh | bash

# Or clone and run manually
git clone https://github.com/rorar/mt7925-bt-fix.git
cd mt7925-bt-fix
chmod +x mt7925-bt-fix.sh
sudo ./mt7925-bt-fix.sh install
```

## Usage

```bash
# Install the fix
sudo ./mt7925-bt-fix.sh install

# Check status
sudo ./mt7925-bt-fix.sh status

# Test manually
sudo ./mt7925-bt-fix.sh test

# View logs
sudo ./mt7925-bt-fix.sh logs

# Uninstall
sudo ./mt7925-bt-fix.sh uninstall
```

## What It Does

1. Creates a systemd service (`mt7925-bt-heal.service`) that reloads kernel modules on boot
2. Adds a suspend/resume hook to fix Bluetooth after waking from sleep
3. Provides helpful status checking and troubleshooting

## What Gets Installed

Running `install` creates these files:

| File                                          | Purpose              | Persists              |
| --------------------------------------------- | -------------------- | --------------------- |
| `/etc/systemd/system/mt7925-bt-heal.service`  | systemd service      | ✅ Runs on every boot |
| `/usr/bin/mt7925-bt-fix-reload.sh`            | Module reload script | ✅ Called by service  |
| `/usr/lib/systemd/system-sleep/mt7925-bt-fix` | Suspend/resume hook  | ✅ Runs after wake    |
| `/var/log/mt7925-bt-fix.log`                  | Activity log         | ℹ️ Can be deleted     |

## Uninstallation

To completely remove the fix:

```bash
sudo ./mt7925-bt-fix.sh uninstall
```

This will:

- Stop and disable the systemd service
- Remove all installed files (service, scripts, hooks)
- Remove the log file

## Tested Systems

> **Read this table by the PCI ID, not by the device name.** A row here means
> "this chip was fixed on that machine", not "every unit of this model has this
> chip". The same model name is shipped with different wireless modules, so a
> matching device name is not a reason to skip Step 1.

| Device                | PCI ID      | Chip                 | Distro               | Kernel          | Status   |
| --------------------- | ----------- | -------------------- | -------------------- | --------------- | -------- |
| Lenovo Yoga 7 14AKP10 | `14c3:7925` | MT7925 (Filogic 360) | Arch Linux (CachyOS) | 7.0.2-2-cachyos | ✅ Works |

**The specific unit that row was tested on:**

- CPU: AMD Ryzen AI 7 350 (16 cores) @ 5.09 GHz
- GPU: AMD Radeon 860M Graphics (RDNA 3.5)
- WiFi: MT7925 802.11be PCIe adapter (`14c3:7925`)
- Bluetooth: internal USB, Foxconn / Hon Hai (`0489:e111`)
- Memory: 32 GB
- Desktop: GNOME 50.1 on Wayland

Another Yoga 7 14AKP10 in the author's hands ships a Realtek RTL8922AE
(`10ec:8922`) with a Realtek BT radio (`0bda:d922`) instead. On that unit the
Bluetooth comes up on its own through `btrtl`, and this fix is not merely
unnecessary — its boot service unloads the working driver and loads `mt7925e`
for hardware that isn't there. Same model name, different silicon. Hence Step 1.

_Submit a PR to add your system — please include the PCI ID from
`lspci -nn | grep -i network`, that is the part that actually identifies the chip._

## Requirements

- Linux with systemd
- MediaTek MT7925 wireless card — verify with `lspci -nn | grep -i network` and
  look for `14c3:7925` (see Step 1 under Quick Start)
- Root access (sudo)

## Troubleshooting

### Bluetooth still not working after install?

1. **Reboot** — the service runs on boot, not during install
2. Try the power cycle procedure again (step 2 above)
3. Check BIOS settings — some laptops have separate WiFi/BT enable
4. Check for kernel updates — if a newer kernel or `linux-firmware` fixed the
   initialization upstream, this workaround is obsolete and should be removed
   with `uninstall`

### WiFi stopped working!

The script reloads the WiFi module briefly. It should recover automatically. If not:

```bash
sudo modprobe mt7925e
```

### Permission denied errors

Make sure to use `sudo`:

```bash
sudo ./mt7925-bt-fix.sh install
```

## How It Works

The MT7925 is a combo chip with WiFi (PCIe) and Bluetooth (internal USB). The BT controller often fails to initialize because:

1. The internal USB connection isn't properly reset
2. The kernel module loads before the hardware is ready
3. A GPIO line gets stuck in the wrong state

The fix works by:

1. Removing the kernel modules (`btusb`, `btmtk`, `mt7925e`)
2. Waiting a moment for the hardware to settle
3. Reloading them in the correct order
4. Repeating on every boot via systemd

## Contributing

Found a fix that works on your system? Please contribute!

1. Fork the repo
2. Add your system to the Tested Systems table
3. Submit a PR

## Disclaimer

This script is provided "as-is" without warranty of any kind. It modifies kernel modules and systemd services — use at your own risk. Always back up your system before making changes.

## License

MIT License — see [LICENSE](LICENSE) file.
