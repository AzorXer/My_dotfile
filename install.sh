#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory of this script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

echo -e "${GREEN}Installing dotfiles...${NC}"

# Function to create symlink
link_file() {
  local src="$1"
  local dst="$2"
  
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      echo -e "${GREEN}✓${NC} $dst already linked"
      return
    fi
    echo -e "${YELLOW}⚠${NC}  $dst exists, backing up to ${dst}.backup"
    mv "$dst" "${dst}.backup"
  fi
  
  echo -e "${GREEN}✓${NC} Linking $dst"
  ln -s "$src" "$dst"
}

# Create necessary directories
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/wallpapers

# Link config files
echo -e "\n${GREEN}Linking configuration files...${NC}"

# i3 config
if [ -d "$DOTFILES_DIR/.config/i3" ]; then
  link_file "$DOTFILES_DIR/.config/i3" ~/.config/i3
fi

# Kitty config
if [ -d "$DOTFILES_DIR/.config/kitty" ]; then
  link_file "$DOTFILES_DIR/.config/kitty" ~/.config/kitty
fi

# Rofi config
if [ -d "$DOTFILES_DIR/.config/rofi" ]; then
  link_file "$DOTFILES_DIR/.config/rofi" ~/.config/rofi
fi

# Dunst config
if [ -d "$DOTFILES_DIR/.config/dunst" ]; then
  link_file "$DOTFILES_DIR/.config/dunst" ~/.config/dunst
fi

# Picom config
if [ -d "$DOTFILES_DIR/.config/picom" ]; then
  link_file "$DOTFILES_DIR/.config/picom" ~/.config/picom
fi

# Link shell configs
echo -e "\n${GREEN}Linking shell configuration...${NC}"
link_file "$DOTFILES_DIR/.aliases" ~/.aliases
link_file "$DOTFILES_DIR/.bashrc" ~/.bashrc
link_file "$DOTFILES_DIR/.Xresources" ~/.Xresources

# Link zshrc if it exists
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
  link_file "$DOTFILES_DIR/.zshrc" ~/.zshrc
fi

# Copy wallpapers
if [ -d "$DOTFILES_DIR/wallpapers" ]; then
  echo -e "\n${GREEN}Copying wallpapers...${NC}"
  cp -r "$DOTFILES_DIR/wallpapers/"* ~/Pictures/wallpapers/ 2>/dev/null || true
fi

# Install fonts
if [ -d "$DOTFILES_DIR/FiraCode" ]; then
  echo -e "\n${GREEN}Installing fonts...${NC}"
  if [ -d ~/.local/share/fonts ]; then
    cp -r "$DOTFILES_DIR/FiraCode/"* ~/.local/share/fonts/ 2>/dev/null || true
    fc-cache -fv ~/.local/share/fonts/ 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Fonts installed"
  fi
fi

# Source aliases in bashrc if not already there
if ! grep -q "source ~/.aliases" ~/.bashrc 2>/dev/null; then
  echo -e "\n# Source aliases\nsource ~/.aliases" >> ~/.bashrc
fi

echo -e "\n${GREEN}✓${NC} Dotfiles installation complete!"
echo -e "${YELLOW}Note:${NC} Run 'source ~/.bashrc' or restart your terminal to apply changes."
