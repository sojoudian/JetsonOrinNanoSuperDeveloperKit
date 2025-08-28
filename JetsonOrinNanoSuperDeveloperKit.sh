sudo apt remove nvidia-l4t-graphics-demos nvidia-l4t-multimedia-utils \
nvidia-l4t-vulkan-sc-samples nvidia-l4t-vulkan-sc-sdk \
nvidia-l4t-jetsonpower-gui-tools nvidia-l4t-nvpmodel-gui-tools



sudo apt autoremove
sudo apt clean


# Stop desktop login manager
sudo systemctl set-default multi-user.target
sudo systemctl disable gdm3
sudo systemctl stop gdm3



sudo apt remove --purge gdm3 gnome-shell ubuntu-desktop
sudo apt autoremove --purge


# 1. Turn Wi-Fi off right now
sudo nmcli radio wifi off

# 2. Block Wi-Fi via rfkill (software + hardware block)
sudo rfkill block wifi

# 3. Make rfkill block persistent across reboots
sudo systemctl enable rfkill-block@wifi.service

# 4. (Optional, extra safety) Tell NetworkManager not to manage Wi-Fi
nmcli device status      # note your Wi-Fi device name (usually wlan0)
sudo nmcli device set wlan0 managed no

mcli radio


sudo nmcli radio wifi off
sudo nmcli radio all off


echo "blacklist brcmfmac" | sudo tee /etc/modprobe.d/disable-wifi.conf
echo "blacklist bcmdhd"   | sudo tee -a /etc/modprobe.d/disable-wifi.conf
sudo update-initramfs -u


sudo systemctl stop docker docker.socket
sudo systemctl disable docker docker.socket

sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo apt-get purge -y nvidia-docker2 nvidia-container-runtime

sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo apt autoremove -y

sudo apt-get purge -y docker.io


####################################################################################################################################################################################
# APT packages related to Docker/NVIDIA containers
echo "=== APT: installed docker/container packages ==="
dpkg -l | grep -E '^(ii|rc)\s' | awk '{print $2}' | \
grep -E '^(docker(-ce|-ce-cli|-buildx-plugin|-compose-plugin)?|docker\.io|containerd(\.io)?|runc|moby-engine|nvidia-container-toolkit|nvidia-container-runtime|libnvidia-container1|libnvidia-container-tools|nvidia-docker2?)$' || echo "None found"
# Also show versions (optional)
echo -e "\n=== apt list --installed (filtered) ==="
apt list --installed 2>/dev/null | \
grep -E '^(docker|containerd|runc|moby|nvidia.*container)'
# Snap (in case docker was installed via snap)
echo -e "\n=== snap: installed ==="
snap list 2>/dev/null | grep -i docker || echo "No docker snap found"
####################################################################################################################################################################################










# Purge only matching APT packages that are actually present
dpkg -l | grep -E '^ii\s' | awk '{print $2}' | \
grep -E '^(docker(-ce|-ce-cli|-buildx-plugin|-compose-plugin)?|docker\.io|containerd(\.io)?|runc|moby-engine|nvidia-container-toolkit|nvidia-container-runtime|libnvidia-container1|libnvidia-container-tools|nvidia-docker2?)$' | \
xargs -r sudo apt-get purge -y

# Remove docker snap if present
if snap list 2>/dev/null | grep -qi '^docker\s'; then
  sudo snap remove --purge docker
fi

# Clean residual configs and deps
sudo apt-get autoremove -y
sudo apt-get autoclean





#######################################********************************#############################################
# Purge remaining NVIDIA container packages
sudo apt-get purge -y libnvidia-container1 nvidia-container-toolkit-base
# Remove the NVIDIA Container Toolkit APT source & key if present
sudo rm -f /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
sudo rm -f /etc/apt/trusted.gpg.d/nvidia-container-toolkit.gpg
# Remove any stray config files
sudo rm -f /etc/ld.so.conf.d/nvidia-container-toolkit.conf
sudo ldconfig
# Cleanup
sudo apt-get autoremove -y
sudo apt-get autoclean
# Verify nothing container-related remains
dpkg -l | grep -iE 'docker|containerd|nvidia.*container' || echo "No matching APT packages remain"
which docker || echo "docker not found"
systemctl list-units --type=service | grep -iE 'docker|containerd' || echo "No docker/containerd services"
#######################################********************************#############################################






#######################################********************************#############################################
# If you don’t need sound:
systemctl --user stop pulseaudio.service pulseaudio.socket 2>/dev/null || true
systemctl --user mask pulseaudio.service pulseaudio.socket 2>/dev/null || true
# If PipeWire is present (your list shows pipewire-media-session):
systemctl --user stop pipewire.service pipewire.socket pipewire-media-session.service 2>/dev/null || true
systemctl --user mask pipewire.service pipewire.socket pipewire-media-session.service 2>/dev/null || true
#######################################********************************#############################################



# Avahi (mDNS) – only if you don’t need .local discovery
sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket 2>/dev/null || true
sudo systemctl disable --now ModemManager.service
# Printing stack
sudo systemctl disable --now cups.service cups-browsed.service 2>/dev/null || true
# Bluetooth (if you don’t use it)
sudo systemctl disable --now bluetooth.service 2>/dev/null || true




sudo systemctl disable --now nvidia-pva-allowd.service 2>/dev/null || true
sudo systemctl disable --now haveged
sudo systemctl disable --now ModemManager
sudo systemctl disable --now avahi-daemon
