#!/bin/bash

set -e

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# Helper Functions
# ============================================================================

check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo bash arch_i3_setup.sh)"
    exit 1
  fi
}

check_sudo_user() {
  if [ -z "$SUDO_USER" ]; then
    echo "❌ SUDO_USER not set. Cannot determine user home directory."
    exit 1
  fi
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  I3_CONFIG_DIR="$USER_HOME/.config/i3"
  I3_CONFIG_FILE="$I3_CONFIG_DIR/config"
}

install_if_missing() {
  local package=$1
  if ! pacman -Qi "$package" &> /dev/null; then
    pacman -S --noconfirm "$package"
  else
    echo "   ✅ $package already installed"
  fi
}

# ============================================================================
# Main Setup
# ============================================================================

echo "------------------------------------------------------"
echo "   Arch i3 Setup Script"
echo "------------------------------------------------------"

check_root
check_sudo_user

# Update system
echo "🔄 Updating system packages..."
pacman -Syu --noconfirm

# Install main packages
echo "📦 Installing main packages..."
pacman -S --noconfirm \
  kitty \
  thunar thunar-volman gvfs udisks2 ntfs-3g exfatprogs dosfstools \
  feh \
  rofi

# Install essential utilities
echo "📦 Installing essential utilities..."
install_if_missing brightnessctl
install_if_missing xss-lock
install_if_missing networkmanager
install_if_missing network-manager-applet
install_if_missing alsa-utils
install_if_missing dex
install_if_missing scrot
install_if_missing xclip
install_if_missing picom
install_if_missing fastfetch

# Install i3 components
echo "🔒 Installing i3 components..."
install_if_missing i3lock
install_if_missing i3status

# Install audio system
echo "🔊 Installing audio system..."
if systemctl --user is-active --quiet pipewire 2>/dev/null || pgrep -x pipewire > /dev/null; then
  echo "   Installing PipeWire..."
  pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber
elif ! command -v pactl &> /dev/null; then
  echo "   Installing PulseAudio..."
  pacman -S --noconfirm pulseaudio pulseaudio-alsa
else
  echo "   ✅ Audio system already available"
fi

# Install yay (AUR helper)
echo "📦 Installing yay..."
if ! command -v yay &> /dev/null; then
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

# ============================================================================
# Hardware Detection
# ============================================================================

detect_graphics() {
  echo "🔍 Detecting graphics chipset..."
  local pci_output=$(lspci | grep -i "vga\|3d\|display" 2>/dev/null || true)
  
  if echo "$pci_output" | grep -qi "intel"; then
    GRAPHICS_CHIPSET="intel"
    echo "   Detected: Intel graphics"
    [ -d /sys/class/backlight/intel_backlight ] && BRIGHTNESS_DEVICE="intel_backlight" || \
    [ -d /sys/class/backlight/acpi_video0 ] && BRIGHTNESS_DEVICE="acpi_video0" || \
    BRIGHTNESS_DEVICE=$(ls /sys/class/backlight/ 2>/dev/null | head -n 1)
    BRIGHTNESS_METHOD="brightnessctl"
  elif echo "$pci_output" | grep -qi "amd\|ati\|radeon"; then
    GRAPHICS_CHIPSET="amd"
    echo "   Detected: AMD graphics"
    [ -d /sys/class/backlight/amdgpu_bl0 ] && BRIGHTNESS_DEVICE="amdgpu_bl0" || \
    [ -d /sys/class/backlight/acpi_video0 ] && BRIGHTNESS_DEVICE="acpi_video0" || \
    BRIGHTNESS_DEVICE=$(ls /sys/class/backlight/ 2>/dev/null | head -n 1)
    BRIGHTNESS_METHOD="brightnessctl"
  elif echo "$pci_output" | grep -qi "nvidia"; then
    GRAPHICS_CHIPSET="nvidia"
    echo "   Detected: NVIDIA graphics"
    if [ -d /sys/class/backlight/acpi_video0 ]; then
      BRIGHTNESS_DEVICE="acpi_video0"
      BRIGHTNESS_METHOD="brightnessctl"
    elif command -v xbacklight &> /dev/null; then
      BRIGHTNESS_METHOD="xbacklight"
    else
      BRIGHTNESS_DEVICE=$(ls /sys/class/backlight/ 2>/dev/null | head -n 1)
      BRIGHTNESS_METHOD="brightnessctl"
    fi
  else
    echo "   ⚠️  Could not detect graphics chipset, using default"
    BRIGHTNESS_DEVICE=$(ls /sys/class/backlight/ 2>/dev/null | head -n 1)
    BRIGHTNESS_METHOD="brightnessctl"
  fi
  
  if [ -n "$BRIGHTNESS_DEVICE" ]; then
    echo "   ✅ Brightness device: $BRIGHTNESS_DEVICE"
  else
    echo "   ⚠️  No backlight device found, brightness control may not work"
  fi
}

detect_audio() {
  echo "🔍 Detecting audio driver..."
  if systemctl --user is-active --quiet pipewire 2>/dev/null || pgrep -x pipewire > /dev/null; then
    AUDIO_DRIVER="pipewire"
    echo "   Detected: PipeWire"
  elif systemctl --user is-active --quiet pulseaudio 2>/dev/null || pgrep -x pulseaudio > /dev/null; then
    AUDIO_DRIVER="pulseaudio"
    echo "   Detected: PulseAudio"
  elif command -v amixer &> /dev/null && [ -n "$(amixer 2>/dev/null)" ]; then
    AUDIO_DRIVER="alsa"
    echo "   Detected: ALSA"
  else
    AUDIO_DRIVER=$(command -v pactl &> /dev/null && echo "pulseaudio" || echo "alsa")
    echo "   Detected: $AUDIO_DRIVER (default)"
  fi
}

detect_graphics
detect_audio

# ============================================================================
# Generate Configuration Files
# ============================================================================

generate_audio_brightness_config() {
  echo "⚙️  Generating brightness and volume control configuration..."
  
  # Generate brightness config
  if [ "$BRIGHTNESS_METHOD" = "brightnessctl" ] && [ -n "$BRIGHTNESS_DEVICE" ]; then
    BRIGHTNESS_CONFIG="# Brightness control (Intel/AMD/NVIDIA via brightnessctl)
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl -d $BRIGHTNESS_DEVICE set +10%
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl -d $BRIGHTNESS_DEVICE set 10%-"
  elif [ "$BRIGHTNESS_METHOD" = "xbacklight" ]; then
    BRIGHTNESS_CONFIG="# Brightness control (NVIDIA via xbacklight)
bindsym XF86MonBrightnessUp exec --no-startup-id xbacklight -inc 10
bindsym XF86MonBrightnessDown exec --no-startup-id xbacklight -dec 10"
  else
    BRIGHTNESS_CONFIG="# Brightness control (generic)
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +10%
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 10%-"
  fi
  
  # Generate volume config
  case "$AUDIO_DRIVER" in
    pipewire)
      VOLUME_CONFIG="# Volume control (PipeWire)
set \$refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+ && \$refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- && \$refresh_i3status
bindsym XF86AudioMute exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && \$refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && \$refresh_i3status"
      ;;
    pulseaudio)
      VOLUME_CONFIG="# Volume control (PulseAudio)
set \$refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && \$refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && \$refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && \$refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && \$refresh_i3status"
      ;;
    *)
      VOLUME_CONFIG="# Volume control (ALSA)
set \$refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id amixer -q set Master 10%+ unmute && \$refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id amixer -q set Master 10%- unmute && \$refresh_i3status
bindsym XF86AudioMute exec --no-startup-id amixer -q set Master toggle && \$refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id amixer -q set Capture toggle && \$refresh_i3status"
      ;;
  esac
  
  # Save configuration
  sudo -u "$SUDO_USER" mkdir -p "$I3_CONFIG_DIR"
  CONFIG_FILE="$I3_CONFIG_DIR/audio-brightness.conf"
  sudo -u "$SUDO_USER" bash -c "cat > '$CONFIG_FILE'" <<EOF
# Auto-generated audio and brightness control configuration
# Graphics: $GRAPHICS_CHIPSET
# Audio: $AUDIO_DRIVER
# Brightness device: ${BRIGHTNESS_DEVICE:-auto}

$BRIGHTNESS_CONFIG

$VOLUME_CONFIG
EOF
  echo "   ✅ Configuration saved to: $CONFIG_FILE"
}

setup_wallpaper() {
  echo "🖼️ Setting up wallpaper..."
  WALLPAPER_DIR="$USER_HOME/Pictures/wallpapers"
  
  # Find wallpaper
  WALLPAPER_FILE=""
  for pattern in "wallhaven-xley1v-colorized.png" "wallpaper.png" "*.png" "*.jpg" "*.jpeg" "*.webp"; do
    if [ -f "$SCRIPT_DIR/$pattern" ]; then
      WALLPAPER_FILE="$SCRIPT_DIR/$pattern"
      break
    fi
  done
  
  if [ -z "$WALLPAPER_FILE" ]; then
    WALLPAPER_FILE=$(find "$SCRIPT_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | head -n 1)
  fi
  
  if [ -n "$WALLPAPER_FILE" ] && [ -f "$WALLPAPER_FILE" ]; then
    echo "   Found wallpaper: $(basename "$WALLPAPER_FILE")"
    sudo -u "$SUDO_USER" mkdir -p "$WALLPAPER_DIR"
    sudo -u "$SUDO_USER" cp "$WALLPAPER_FILE" "$WALLPAPER_DIR/"
    WALLPAPER_PATH="$WALLPAPER_DIR/$(basename "$WALLPAPER_FILE")"
    
    # Set wallpaper if X is running
    if [ -n "$DISPLAY" ] || pgrep -x Xorg > /dev/null || pgrep -x X > /dev/null; then
      sudo -u "$SUDO_USER" feh --bg-fill "$WALLPAPER_PATH" 2>/dev/null || \
        echo "   ⚠️  Could not set wallpaper immediately (X may not be running)"
    fi
    
    # Create .fehbg script
    WALLPAPER_SCRIPT="$USER_HOME/.fehbg"
    sudo -u "$SUDO_USER" bash -c "cat > '$WALLPAPER_SCRIPT'" <<EOF
#!/bin/sh
feh --bg-fill "$WALLPAPER_PATH"
EOF
    sudo -u "$SUDO_USER" chmod +x "$WALLPAPER_SCRIPT"
    
    echo "   ✅ Wallpaper set up at: $WALLPAPER_PATH"
  else
    echo "   ⚠️  No wallpaper file found in $SCRIPT_DIR"
  fi
}

setup_config_files() {
  # Setup Kitty config
  echo "🐱 Setting up Kitty configuration..."
  KITTY_CONFIG_DIR="$USER_HOME/.config/kitty"
  KITTY_SOURCE_CONFIG="$SCRIPT_DIR/kitty/kitty.conf"
  
  if [ -f "$KITTY_SOURCE_CONFIG" ]; then
    sudo -u "$SUDO_USER" mkdir -p "$KITTY_CONFIG_DIR"
    sudo -u "$SUDO_USER" cp "$KITTY_SOURCE_CONFIG" "$KITTY_CONFIG_DIR/kitty.conf"
    echo "   ✅ Kitty config copied"
  else
    echo "   ⚠️  Kitty config file not found"
  fi
  
  # Setup i3 config
  echo "🪟 Setting up i3 configuration..."
  I3_SOURCE_CONFIG="$SCRIPT_DIR/i3/config"
  
  if [ -f "$I3_SOURCE_CONFIG" ]; then
    sudo -u "$SUDO_USER" mkdir -p "$I3_CONFIG_DIR"
    sudo -u "$SUDO_USER" cp "$I3_SOURCE_CONFIG" "$I3_CONFIG_FILE"
    echo "   ✅ i3 config copied"
    
    # Add audio-brightness.conf include if not present
    if ! grep -q "include audio-brightness.conf" "$I3_CONFIG_FILE"; then
      if grep -q "exec --no-startup-id ~/.fehbg" "$I3_CONFIG_FILE"; then
        sudo -u "$SUDO_USER" sed -i '/exec --no-startup-id ~\/\.fehbg/a include audio-brightness.conf' "$I3_CONFIG_FILE"
      else
        sudo -u "$SUDO_USER" bash -c "echo -e '\n# Include auto-generated audio and brightness control\ninclude audio-brightness.conf' >> '$I3_CONFIG_FILE'"
      fi
      echo "   ✅ Added 'include audio-brightness.conf' to i3 config"
    fi
  else
    echo "   ⚠️  i3 config file not found"
  fi
}

generate_audio_brightness_config
setup_wallpaper
setup_config_files

# ============================================================================
# Summary
# ============================================================================

echo "------------------------------------------------------"
echo "✅ Installation Complete!"
echo ""
echo "📊 Detected Hardware:"
echo "   - Graphics: $GRAPHICS_CHIPSET"
echo "   - Audio: $AUDIO_DRIVER"
echo "   - Brightness device: ${BRIGHTNESS_DEVICE:-auto}"
echo ""
echo "📁 Configuration Files:"
echo "   - Kitty: ~/.config/kitty/kitty.conf"
echo "   - i3: ~/.config/i3/config"
echo "   - Audio/Brightness: ~/.config/i3/audio-brightness.conf"
echo ""
echo "📝 Next steps:"
echo "   1. Install FiraCode Nerd Font from the FiraCode/ directory"
echo "   2. Reboot or restart i3 (Mod+Shift+R to reload i3 config)"
echo ""
echo "💡 All configuration files have been automatically set up!"
echo "------------------------------------------------------"
