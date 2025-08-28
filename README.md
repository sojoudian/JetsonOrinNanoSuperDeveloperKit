# NVIDIA Jetson Orin Nano Super Developer Kit - Clean OS Setup

A comprehensive bash script to transform a fresh NVIDIA Jetson Orin Nano installation into a minimal, headless development environment by removing unnecessary packages, GUI components, and services.

## 🎯 Purpose

This script is designed for developers who want to:
- Maximize available system resources by removing unnecessary components
- Create a headless (no GUI) Jetson development environment
- Reduce attack surface by disabling unused services
- Optimize the system for edge computing, robotics, or AI inference workloads
- Free up storage space by removing bloatware and demo applications

## ⚠️ Warning

**This script makes IRREVERSIBLE changes to your system!**

The script will:
- ❌ Remove the entire desktop environment (GNOME, GDM3)
- ❌ Permanently disable WiFi and Bluetooth
- ❌ Remove Docker and all container runtimes
- ❌ Disable audio services (PulseAudio, PipeWire)
- ❌ Remove NVIDIA demo applications and GUI tools
- ❌ Disable various system services (printing, mDNS, ModemManager)

**Only run this on a fresh installation or test system that you're prepared to use in headless mode!**

## 📋 Prerequisites

- Fresh installation of NVIDIA JetPack on Jetson Orin Nano
- SSH access configured (you'll lose GUI access after running this)
- Ethernet connection (WiFi will be disabled)
- Root/sudo privileges
- Backup of any important data

## 🚀 Usage

1. **Clone or download the script:**
```bash
git clone https://github.com/sojoudian/JetsonOrinNanoSuperDeveloperKit.git
cd JetsonOrinNanoSuperDeveloperKit
```

2. **Review the script (recommended):**
```bash
less JetsonOrinNanoSuperDeveloperKit.sh
```

3. **Make the script executable:**
```bash
chmod +x JetsonOrinNanoSuperDeveloperKit.sh
```

4. **Run the script:**
```bash
sudo ./JetsonOrinNanoSuperDeveloperKit.sh
```

5. **Follow the prompts:**
   - Confirm you want to proceed (type "yes")
   - At the end, choose whether to reboot immediately

## 📝 What Gets Removed/Disabled

### Removed Packages
- **NVIDIA L4T packages**: Graphics demos, multimedia utils, Vulkan samples, GUI power tools
- **Desktop Environment**: GDM3, GNOME Shell, Ubuntu Desktop
- **Container Runtime**: Docker CE, Docker CLI, containerd, nvidia-docker2, nvidia-container-runtime
- **Audio Stack**: PulseAudio, PipeWire (disabled, not removed)

### Disabled Services
- **Networking**: WiFi (via rfkill and kernel module blacklist), Bluetooth
- **System Services**: Avahi daemon (mDNS), ModemManager, CUPS printing, haveged
- **NVIDIA Services**: nvidia-pva-allowd (if not needed for your application)

### System Changes
- Default target changed from `graphical.target` to `multi-user.target`
- WiFi kernel modules blacklisted (`brcmfmac`, `bcmdhd`)
- NetworkManager configured to ignore WiFi devices
- All radio communications disabled via nmcli

## 📊 System Verification

After running the script, it performs automatic verification checks:
- Confirms Docker/container packages are removed
- Verifies Docker command is unavailable
- Checks no Docker services are running
- Confirms WiFi is disabled
- Shows current system target (should be multi-user.target)

## 📁 Logging

All operations are logged to `/var/log/jetson-cleanup-YYYYMMDD-HHMMSS.log`

This log file contains:
- Timestamp of execution
- All commands executed
- Success/failure status of each operation
- Any error messages encountered

## 🔄 Reverting Changes (Partial)

While many changes are difficult to reverse, you can restore some functionality:

### Re-enable WiFi:
```bash
sudo nmcli radio wifi on
sudo rfkill unblock wifi
sudo rm /etc/modprobe.d/disable-wifi.conf
sudo update-initramfs -u
# Then reboot
```

### Re-enable GUI (requires internet):
```bash
sudo apt update
sudo apt install ubuntu-desktop gdm3
sudo systemctl set-default graphical.target
# Then reboot
```

### Reinstall Docker:
```bash
# Follow NVIDIA's official documentation for Docker on Jetson
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

## 🤝 Contributing

Feel free to submit issues, fork, and create pull requests for any improvements.

## 📄 License

This script is provided as-is without any warranty. Use at your own risk.

## 🔧 Tested On

- NVIDIA Jetson Orin Nano Super Developer Kit
- JetPack 5.x and 6.x
- Ubuntu 20.04 / 22.04 base images

## 📚 Additional Resources

- [NVIDIA Jetson Documentation](https://docs.nvidia.com/jetson/)
- [JetPack SDK](https://developer.nvidia.com/embedded/jetpack)
- [Jetson Software Stack](https://developer.nvidia.com/embedded/develop/software)

## ⚡ Performance Impact

After running this script, you can expect:
- **~2-3GB** of freed storage space
- **~500MB-1GB** reduction in RAM usage
- **Faster boot times** (no GUI initialization)
- **More CPU cycles** available for your applications
- **Reduced power consumption** (no display server, WiFi, Bluetooth)

## 🐛 Troubleshooting

### SSH Connection Lost
If you lose SSH connection during execution:
1. Check the log file at `/var/log/jetson-cleanup-*.log`
2. The script uses error handling to prevent partial execution
3. You can safely re-run the script if it was interrupted

### System Won't Boot
If the system fails to boot after running:
1. Connect via serial console
2. Check systemctl status for failed services
3. Review the log file for errors
4. Boot into recovery mode if necessary

### Need a Removed Service Back
Check the "Reverting Changes" section above for restoration instructions

---

**Remember**: This script is designed for creating a production-ready, minimal Jetson system. Always test in a development environment first!