# MT7925 Bluetooth Fix

A community-maintained script to fix MediaTek MT7925 Bluetooth not initializing on Linux.

> ⚠️ **Note:** This script was initially created with AI assistance (vibe-coded). It works on the author's system but may need adjustments for your setup. Contributions welcome!

## The Problem

The MediaTek MT7925 (Filogic 360) is a Wi-Fi 7 + Bluetooth 5.3 PCIe combo chip found in many modern laptops. On Linux, the Bluetooth portion often fails to initialize on boot, leaving you with no Bluetooth adapter.

**Symptoms:**

- `bluetoothctl power on` returns "No default controller available"
- `/sys/class/bluetooth` is empty or missing
- WiFi works fine, but Bluetooth is nowhere to be found

## Quick Start

### Step 1: Try This First (No Install Needed!) ⚡

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

### Step 2: Install the Fix (If Power Cycle Didn't Work)

```bash
# Download and run
curl -sSL https://raw.githubusercontent.com/rorar/mt7925-bt-fix/main/install.sh | bash

# Or clone and run manually
git clone https://github.com/rorar/mt7925-bt-fix.git
cd mt7925-bt-fix
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

## Tested Systems

| Device                | Chip                 | WiFi Module        | Distro               | Kernel          | Status   |
| --------------------- | -------------------- | ------------------ | -------------------- | --------------- | -------- |
| Lenovo Yoga 7 14AKP10 | MT7925 (Filogic 360) | PCIe WiFi + USB BT | Arch Linux (CachyOS) | 7.0.2-2-cachyos | ✅ Works |

**Reference specs:**

- AMD Ryzen AI processor (Strix Point)
- MediaTek MT7925 802.11be WiFi 7 PCIe adapter
- Internal USB Bluetooth (0489:e111 Foxconn)
- BIOS: C7CN39WW+

_Submit a PR to add your system!_

## Requirements

- Linux with systemd
- MediaTek MT7925 wireless card (check with `lspci | grep MT7925`)
- Root access (sudo)

## Troubleshooting

### Bluetooth still not working after install?

1. **Reboot** — the service runs on boot, not during install
2. Try the power cycle procedure again (step 1 above)
3. Check BIOS settings — some laptops have separate WiFi/BT enable
4. Check for kernel updates

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
