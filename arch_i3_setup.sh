#!/bin/bash

set -e

echo "------------------------------------------------------"
echo "   Installing Kitty + Thunar + feh + rofi + yay"
echo "------------------------------------------------------"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo bash arch_i3_setup.sh)"
  exit 1
fi

# Update system
echo "🔄 Updating system packages..."
pacman -Syu --noconfirm

# Install Kitty terminal
echo "🖥️ Installing Kitty terminal..."
if ! pacman -Qi kitty &> /dev/null; then
  pacman -S --noconfirm kitty
else
  echo "✅ Kitty already installed"
fi

# Install Thunar + USB/CD support
echo "📁 Installing Thunar and USB/CD support..."
pacman -S --noconfirm thunar thunar-volman gvfs gvfs-mtp gvfs-afc gvfs-smb gvfs-nfs \
  gvfs-goa udiskie udisks2 ntfs-3g exfatprogs dosfstools

# Install feh (for wallpapers)
echo "🖼️ Installing feh..."
pacman -S --noconfirm feh

# Install rofi (app launcher)
echo "🚀 Installing rofi..."
pacman -S --noconfirm rofi

# Install additional useful packages
echo "📦 Installing additional utilities..."
pacman -S --noconfirm \
  brightnessctl \
  xss-lock \
  i3lock \
  networkmanager \
  network-manager-applet \
  pulseaudio \
  pulseaudio-alsa \
  alsa-utils \
  dex \
  i3status \
  picom \
  arandr \
  scrot \
  xclip \
  neofetch

# Install yay (AUR helper)
echo "📦 Installing yay..."
if ! command -v yay &> /dev/null; then
  if [ -z "$SUDO_USER" ]; then
    echo "❌ SUDO_USER not set. Cannot install yay without a non-root user."
    exit 1
  fi
  sudo -u "$SUDO_USER" bash <<'EOF'
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
EOF
else
  echo "✅ yay already installed"
fi

echo "------------------------------------------------------"
echo "✅ Installation Complete!"
echo "   Installed:"
echo "   - Kitty terminal"
echo "   - Thunar (with auto-mount)"
echo "   - feh (wallpapers)"
echo "   - rofi (launcher)"
echo "   - yay (AUR helper)"
echo "   - Additional utilities (brightnessctl, i3lock, etc.)"
echo ""
echo "📝 Next steps:"
echo "   1. Copy i3/config to ~/.config/i3/config"
echo "   2. Copy kitty/kitty.conf to ~/.config/kitty/kitty.conf"
echo "   3. Install FiraCode Nerd Font from the FiraCode/ directory"
echo "   4. Reboot or restart i3"
echo "------------------------------------------------------"
