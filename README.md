# Niri + DankMaterialShell Dotfiles
## For CachyOS Non-Desktop

Cài đặt Niri compositor + DankMaterialShell theo **official documentation**.

## Files

```
├── install.sh         # Script cài đặt (CHẠY FILE NÀY)
├── niri-config.kdl   # Niri config (đã remove waybar spawn)
└── README.md         # File này
```

## Installation

### Step 1: Run install script

```bash
chmod +x install.sh
./install.sh
```

Script sẽ cài:
- ✅ Niri + dependencies (theo official docs)
- ✅ xwayland-satellite, xdg-desktop-portal-gnome, xdg-desktop-portal-gtk
- ✅ alacritty, fuzzel, swaylock
- ✅ GDM display manager
- ✅ NetworkManager, Bluetooth, Pipewire
- ✅ DankMaterialShell (dms-shell-bin từ AUR)
- ✅ DMS dependencies (matugen, wl-clipboard, cliphist, cava)
- ✅ Link DMS to niri: `systemctl --user add-wants niri.service dms`

**Time**: ~15-30 phút

### Step 2: Copy niri config

```bash
mkdir -p ~/.config/niri
cp niri-config.kdl ~/.config/niri/config.kdl
```

Config này đã:
- ❌ **REMOVED** `spawn-at-startup "waybar"` (default niri config có dòng này)
- ✅ DMS starts via systemd service (automatic)
- ✅ Basic niri keybindings từ official docs
- ✅ DMS overlay windows float

### Step 3: Reboot

```bash
sudo reboot
```

### Step 4: Login to Niri

At GDM:
1. Click gear icon ⚙️ (bottom right)
2. Select **"Niri"**
3. Login

DMS auto-starts!

## Important: Waybar Issue

Default niri config spawns waybar. Nếu bạn thấy **2 bars** sau khi login lần đầu:

```bash
# Kill waybar
pkill waybar

# Edit config
nano ~/.config/niri/config.kdl

# Tìm và XÓA dòng này (nếu còn):
spawn-at-startup "waybar"
```

Config mẫu của tôi đã remove dòng này rồi.

## Keybindings

### Niri Default (Official)

| Key | Action |
|-----|--------|
| `Super + Shift + /` | Show hotkey overlay |
| `Super + T` | Terminal (alacritty) |
| `Super + D` | Launcher (fuzzel) |
| `Super + Alt + L` | Lock (swaylock) |
| `Super + Q` | Close window |
| `Super + H/J/K/L` | Focus window |
| `Super + Ctrl + H/J/K/L` | Move window |
| `Super + 1-9` | Switch workspace |
| `Super + Ctrl + 1-9` | Move to workspace |
| `Super + Shift + E` | Exit niri |

Full list: Press `Super + Shift + /`

### DMS Controls (via IPC)

Bạn có thể add thêm keybindings cho DMS vào niri config:

```kdl
binds {
    // DMS Spotlight
    Mod+Space { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
    
    // DMS Dashboard
    Mod+A { spawn "dms" "ipc" "call" "overview" "toggle"; }
    
    // DMS Control Center
    Mod+C { spawn "dms" "ipc" "call" "controlcenter" "toggle"; }
}
```

## DMS CLI

```bash
# IPC commands
dms ipc call spotlight toggle
dms ipc call overview toggle
dms ipc call controlcenter toggle

# Set wallpaper (auto-theme)
dms ipc call wallpaper set ~/Pictures/wallpaper.jpg

# Audio
dms ipc call audio volume +5

# Process management
dms                          # TUI
systemctl --user status dms
journalctl --user -u dms -f
```

## Check DMS Status

```bash
# DMS service status
systemctl --user status dms

# Check if DMS is linked to niri
systemctl --user show -p Wants niri.service | grep dms
# Should output: Wants=dms.service

# View logs
journalctl --user -u dms -f
```

## Customization

### Niri Config

Edit `~/.config/niri/config.kdl`:

```bash
nano ~/.config/niri/config.kdl
```

Changes:
- Gaps, borders, colors
- Window rules
- Keybindings
- Output (monitor) config

After changes:
```bash
niri msg action reload-config
```

### DMS Config

Location: `~/.config/DankMaterialShell/`

Docs: https://danklinux.com/docs/dankmaterialshell/advanced-configuration

### Tiếng Việt

Edit niri config:

```kdl
input {
    keyboard {
        xkb {
            layout "us,vn"
            options "grp:alt_shift_toggle"
        }
    }
}
```

## Troubleshooting

### DMS không start

```bash
# Check service
systemctl --user status dms

# Check if linked
systemctl --user show -p Wants niri.service

# Re-link nếu cần
systemctl --user add-wants niri.service dms

# Logs
journalctl --user -u dms -f
```

### Niri black screen

Check mesa version match:
```bash
pacman -Q mesa niri
```

### Two bars on screen

```bash
pkill waybar
# Edit ~/.config/niri/config.kdl
# Remove: spawn-at-startup "waybar"
```

### Audio không hoạt động

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Documentation

- **Niri**: https://yalter.github.io/niri/
- **DMS**: https://danklinux.com/docs
- **DMS GitHub**: https://github.com/AvengeMedia/DankMaterialShell
- **Niri Getting Started**: https://yalter.github.io/niri/Getting-Started.html

## Based On

- Niri Quick Start: https://yalter.github.io/niri/Getting-Started.html#quick-start
- DMS được cài theo official method cho Arch Linux
- `systemctl --user add-wants niri.service dms` (official DMS method)

## Next Steps

1. ✅ Set wallpaper: `dms ipc call wallpaper set ~/path.jpg`
2. ✅ Press `Super + Shift + /` để xem niri hotkeys
3. ✅ Try DMS Spotlight: `Super + Space` (nếu đã add keybind)
4. ✅ Browse plugins: `dms plugins search`

Enjoy! 🎉
