#!/bin/bash
# Complete Niri + DankMaterialShell installation for CachyOS Non-Desktop
# Based on official Niri documentation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║   Niri + DankMaterialShell Installation                      ║
║   CachyOS Non-Desktop → Full Wayland Desktop                 ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Don't run as root! Script will ask for sudo when needed.${NC}"
    exit 1
fi

# Check internet
echo -e "${YELLOW}[1/7] Checking internet...${NC}"
if ! ping -c 1 archlinux.org &> /dev/null; then
    echo -e "${RED}No internet connection!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected${NC}"

# Update system
echo -e "${YELLOW}[2/7] Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Install paru if needed
echo -e "${YELLOW}[3/7] Setting up AUR helper...${NC}"
if ! command -v paru &> /dev/null; then
    echo "Installing paru..."
    cd /tmp
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/paru-bin
fi
echo -e "${GREEN}✓ paru ready${NC}"

# Install Niri + dependencies (theo official docs)
echo -e "${YELLOW}[4/7] Installing Niri and dependencies...${NC}"
sudo pacman -Syu --needed --noconfirm \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    alacritty \
    kitty \
    fuzzel \
    swaylock \
    gdm \
    networkmanager \
    network-manager-applet \
    bluez \
    bluez-utils \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    brightnessctl \
    grim \
    slurp \
    nautilus \
    firefox

echo -e "${GREEN}✓ Niri installed${NC}"

# Install DMS dependencies
echo -e "${YELLOW}[5/7] Installing DankMaterialShell dependencies...${NC}"
paru -S --needed --noconfirm \
    matugen \
    wl-clipboard \
    cliphist \
    cava \
    qt6-multimedia-ffmpeg

echo -e "${GREEN}✓ Dependencies ready${NC}"

# Install DMS (theo official docs)
echo -e "${YELLOW}[6/7] Installing DankMaterialShell...${NC}"
paru -S --needed --noconfirm dms-shell-bin

# Add DMS to niri (theo official docs)
systemctl --user add-wants niri.service dms

echo -e "${GREEN}✓ DMS installed${NC}"

# Enable services
echo -e "${YELLOW}[7/7] Enabling services...${NC}"
sudo systemctl enable gdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber

echo -e "${GREEN}✓ Services enabled${NC}"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  INSTALLATION COMPLETE!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1. Copy niri config:"
echo "   ${YELLOW}mkdir -p ~/.config/niri${NC}"
echo "   ${YELLOW}cp niri-config.kdl ~/.config/niri/config.kdl${NC}"
echo ""
echo "2. Reboot:"
echo "   ${YELLOW}sudo reboot${NC}"
echo ""
echo "3. At GDM login:"
echo "   - Click gear icon (⚙️) at bottom right"
echo "   - Select 'Niri'"
echo "   - Login"
echo ""
echo "4. DMS will auto-start!"
echo ""
echo -e "${YELLOW}NOTE: Default niri config spawns waybar.${NC}"
echo "Since DMS provides its own bar, you should:"
echo "  - After first login, run: ${YELLOW}pkill waybar${NC}"
echo "  - Edit ${YELLOW}~/.config/niri/config.kdl${NC}"
echo "  - Remove the line: ${RED}spawn-at-startup \"waybar\"${NC}"
echo ""
echo -e "${BLUE}Hotkeys (when using DMS):${NC}"
echo "  Super + Space   → Spotlight Launcher"
echo "  Super + A       → Dashboard"
echo "  Super + T       → Terminal"
echo "  Super + Q       → Close window"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  Niri: https://yalter.github.io/niri/"
echo "  DMS:  https://danklinux.com/docs"
echo ""
