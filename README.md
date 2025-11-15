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

### Complete Installation

The `install.sh` script does everything in one go:

```bash
git clone https://github.com/AzorXer/My_dotfile.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
sudo ./install.sh
```

This will:
- Install all required packages (kitty, rofi, i3, dunst, picom, etc.)
- Detect your hardware (graphics/audio)
- Configure brightness and volume controls automatically
- Set up wallpapers
- Install fonts
- Link all dotfiles to your home directory

**Note:** The script will automatically request sudo privileges if needed.

## Structure

```
.
├── install.sh              # Unified installation script (does everything)
├── .config/                # Application configs
│   ├── i3/                 # i3 window manager
│   ├── kitty/              # Terminal
│   ├── rofi/               # App launcher
│   ├── dunst/              # Notifications
│   ├── picom/              # Compositor
│   └── i3blocks/           # Status bar blocks
├── .zsh/                   # Zsh configuration
├── .zshrc                  # Zsh config file
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
