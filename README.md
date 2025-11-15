# My Dotfiles

Personal dotfiles for Arch Linux with i3 window manager.

## What's Included

- **i3** - Tiling window manager configuration
- **Kitty** - Terminal emulator
- **Rofi** - Application launcher
- **Dunst** - Notification daemon
- **Picom** - Compositor for transparency and effects
- **FiraCode Nerd Font** - Programming font with ligatures
- **Shell configs** - Bash aliases and configuration

## Installation

### Quick Install

git clone https://github.com/AzorXer/My_dotfile.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh### Arch Linux Setup

For a complete Arch Linux setup with all packages:

sudo bash setup.shThis will:
- Install all required packages
- Detect your hardware (graphics/audio)
- Configure brightness and volume controls
- Set up wallpapers
- Install fonts

## Structure

```
.
├── install.sh              # Main installation script
├── setup.sh                # Arch Linux setup script
├── .config/                # Application configs
│   ├── i3/                 # i3 window manager
│   ├── kitty/              # Terminal
│   ├── rofi/               # App launcher
│   ├── dunst/              # Notifications
│   └── picom/              # Compositor
├── FiraCode/               # Fonts
├── wallpapers/             # Wallpapers
└── bin/                    # Custom scripts
```

## Features

- **Hardware Detection** - Automatically detects graphics and audio
- **Auto Configuration** - Sets up brightness and volume controls
- **Wallpaper Management** - Automatic wallpaper setup
- **Font Installation** - Installs FiraCode Nerd Font

## Key Bindings

- `Mod+Return` - Open terminal (Kitty)
- `Mod+d` - Application launcher (Rofi)
- `Mod+h/j/k/l` - Focus windows (vim-style)
- `Mod+Shift+h/j/k/l` - Move windows
- `Mod+1-10` - Switch workspaces
- `Mod+Shift+c` - Reload i3 config
- `Mod+Shift+r` - Restart i3

## Requirements

- Arch Linux (or Arch-based distro)
- i3 window manager
- Kitty terminal
- Rofi
- Dunst
- Picom

## License

MIT
```
