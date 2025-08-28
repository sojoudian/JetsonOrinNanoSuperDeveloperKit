#!/bin/bash

###############################################################################
# NVIDIA Jetson Orin Nano Super Developer Kit - Clean OS Setup Script
###############################################################################
# Description: This script cleans up a fresh Jetson Orin Nano installation
#              by removing unnecessary packages, GUI components, and services
#              to create a minimal, headless development environment.
#
# WARNING: This script will:
#   - Remove desktop environment and GUI components
#   - Disable WiFi, Bluetooth, and other wireless services
#   - Remove Docker and container runtime
#   - Disable various system services
#
# IMPORTANT: Run this script only on a fresh installation or test system
#            Some changes are difficult to reverse!
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging setup
LOG_FILE="/var/log/jetson-cleanup-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${GREEN}===== NVIDIA Jetson Orin Nano Clean OS Setup Script =====${NC}"
echo -e "${YELLOW}Log file: $LOG_FILE${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${GREEN}===== $1 =====${NC}"
    echo ""
}

# Function to handle errors
error_handler() {
    echo -e "${RED}Error occurred in script at line $1${NC}"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Confirmation prompt
echo -e "${YELLOW}WARNING: This script will make significant changes to your system!${NC}"
echo "It will remove GUI, disable WiFi/Bluetooth, remove Docker, and more."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborting script."
    exit 0
fi

###############################################################################
# SECTION 1: Remove NVIDIA Demo and GUI Tools
###############################################################################
print_section "Removing NVIDIA Demo Packages and GUI Tools"

sudo apt remove -y nvidia-l4t-graphics-demos nvidia-l4t-multimedia-utils \
nvidia-l4t-vulkan-sc-samples nvidia-l4t-vulkan-sc-sdk \
nvidia-l4t-jetsonpower-gui-tools nvidia-l4t-nvpmodel-gui-tools || true

###############################################################################
# SECTION 2: Clean APT Cache
###############################################################################
print_section "Cleaning APT Cache"

sudo apt autoremove -y
sudo apt clean

###############################################################################
# SECTION 3: Disable Desktop Environment
###############################################################################
print_section "Disabling Desktop Environment"

# Stop desktop login manager
sudo systemctl set-default multi-user.target
sudo systemctl disable gdm3 || true
sudo systemctl stop gdm3 || true

# Remove desktop packages
sudo apt remove --purge -y gdm3 gnome-shell ubuntu-desktop || true
sudo apt autoremove --purge -y

###############################################################################
# SECTION 4: Disable WiFi
###############################################################################
print_section "Disabling WiFi"

# Turn Wi-Fi off
sudo nmcli radio wifi off || true

# Block Wi-Fi via rfkill
sudo rfkill block wifi || true

# Make rfkill block persistent
sudo systemctl enable rfkill-block@wifi.service || true

# Get WiFi device name and disable it in NetworkManager
WIFI_DEVICE=$(nmcli device status | grep wifi | awk '{print $1}' | head -n1)
if [[ -n "$WIFI_DEVICE" ]]; then
    sudo nmcli device set "$WIFI_DEVICE" managed no || true
fi

# Disable all radio
sudo nmcli radio all off || true

# Blacklist WiFi kernel modules
echo "blacklist brcmfmac" | sudo tee /etc/modprobe.d/disable-wifi.conf
echo "blacklist bcmdhd" | sudo tee -a /etc/modprobe.d/disable-wifi.conf
sudo update-initramfs -u

###############################################################################
# SECTION 5: Remove Docker and Container Runtime
###############################################################################
print_section "Removing Docker and Container Runtime"

# Stop Docker services
sudo systemctl stop docker docker.socket || true
sudo systemctl disable docker docker.socket || true

# List installed Docker/Container packages for reference
echo "Currently installed Docker/Container packages:"
dpkg -l | grep -E '^ii\s' | awk '{print $2}' | \
grep -E '^(docker|containerd|runc|moby|nvidia.*container)' || echo "None found"

# Purge Docker packages
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
sudo apt-get purge -y docker.io || true

# Purge NVIDIA container packages
sudo apt-get purge -y nvidia-docker2 nvidia-container-runtime || true
sudo apt-get purge -y libnvidia-container1 nvidia-container-toolkit-base || true
sudo apt-get purge -y nvidia-container-toolkit libnvidia-container-tools || true

# Remove Docker snap if present
if snap list 2>/dev/null | grep -qi '^docker\s'; then
    sudo snap remove --purge docker
fi

# Remove NVIDIA Container Toolkit APT sources
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
sudo rm -f /etc/apt/trusted.gpg.d/nvidia-container-toolkit.gpg
sudo rm -f /etc/ld.so.conf.d/nvidia-container-toolkit.conf
sudo ldconfig

# Final cleanup
sudo apt-get autoremove -y
sudo apt-get autoclean

###############################################################################
# SECTION 6: Disable Audio Services
###############################################################################
print_section "Disabling Audio Services"

# Disable PulseAudio
systemctl --user stop pulseaudio.service pulseaudio.socket 2>/dev/null || true
systemctl --user mask pulseaudio.service pulseaudio.socket 2>/dev/null || true

# Disable PipeWire if present
systemctl --user stop pipewire.service pipewire.socket pipewire-media-session.service 2>/dev/null || true
systemctl --user mask pipewire.service pipewire.socket pipewire-media-session.service 2>/dev/null || true

###############################################################################
# SECTION 7: Disable Unnecessary System Services
###############################################################################
print_section "Disabling Unnecessary System Services"

# Avahi (mDNS)
sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket 2>/dev/null || true

# ModemManager
sudo systemctl disable --now ModemManager.service 2>/dev/null || true

# Printing services
sudo systemctl disable --now cups.service cups-browsed.service 2>/dev/null || true

# Bluetooth
sudo systemctl disable --now bluetooth.service 2>/dev/null || true

# NVIDIA PVA service (if not needed)
sudo systemctl disable --now nvidia-pva-allowd.service 2>/dev/null || true

# Entropy daemon
sudo systemctl disable --now haveged 2>/dev/null || true

###############################################################################
# SECTION 8: Final Verification
###############################################################################
print_section "System Cleanup Complete - Verification"

echo "Checking remaining Docker/Container packages:"
dpkg -l | grep -iE 'docker|containerd|nvidia.*container' || echo "✓ No Docker/Container packages found"

echo ""
echo "Checking Docker command availability:"
which docker 2>/dev/null && echo "⚠ Docker command still found" || echo "✓ Docker command not found"

echo ""
echo "Checking active Docker/Container services:"
systemctl list-units --type=service | grep -iE 'docker|containerd' || echo "✓ No Docker/Container services running"

echo ""
echo "WiFi status:"
nmcli radio wifi 2>/dev/null || echo "✓ WiFi disabled"

echo ""
echo "Current system target:"
systemctl get-default

###############################################################################
# SECTION 9: Completion
###############################################################################
print_section "Script Completed Successfully"

echo -e "${GREEN}The Jetson Orin Nano has been configured for minimal headless operation.${NC}"
echo ""
echo "Summary of changes:"
echo "  - Removed GUI and desktop environment"
echo "  - Disabled WiFi and Bluetooth"
echo "  - Removed Docker and container runtime"
echo "  - Disabled unnecessary system services"
echo ""
echo -e "${YELLOW}A reboot is recommended to ensure all changes take effect.${NC}"
echo ""
echo "Log file saved to: $LOG_FILE"
echo ""
read -p "Would you like to reboot now? (yes/no): " reboot_confirm
if [[ "$reboot_confirm" == "yes" ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
fi