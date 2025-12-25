#!/bin/bash

set -e

# Colors
readonly RED='\e[38;2;255;0;0m'        # Đỏ thuần
readonly GREEN='\e[38;2;0;255;0m'      # Xanh lá thuần
readonly YELLOW='\e[38;2;255;255;0m'   # Vàng thuần
readonly MAGENTA='\e[38;2;234;0;255m'  # Hồng tím
readonly CYAN='\e[38;2;0;255;255m'    # Xanh lơ
readonly BLUE='\e[38;2;0;191;255m'     # Xanh dương
readonly NC='\e[0m'                    # Reset màu

LOG_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly LOG="$HOME/niri_setup_complete_${LOG_TIMESTAMP}.log"
readonly STATE_DIR="$HOME/.cache/niri-setup"
readonly STATE_FILE="$STATE_DIR/setup_state.json"
readonly BACKUP_DIR="$HOME/Documents/niri-configs-${BACKUP_TIMESTAMP}"

log() {
	echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG"
}

warn() {
    echo -e "${YELLOW}⚠ [$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG"
}

error() {
    echo -e "${RED}✗ [$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG"
    echo -e "${YELLOW}See log: $LOG${NC}"
    exit 1
}

ai_info() {
    echo -e "${MAGENTA}[AI/ML]${NC} $1" | tee -a "$LOG"
}

creative_info() {
    echo -e "${CYAN}[CREATIVE]${NC} $1" | tee -a "$LOG"
}

# Check sudo
if ! sudo -v; then
    error "Không có quyền sudo. Thoát."
fi

# Keep sudo alive - tự động refresh mỗi 60s
(
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null
) &
SUDO_REFRESH_PID=$!

trap 'kill $SUDO_REFRESH_PID 2>/dev/null' EXIT

# Create directories
mkdir -p "$STATE_DIR" "$BACKUP_DIR"

# ===== STATE MANAGEMENT =====

init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" <<EOF
{
  "version": "1.0",
  "start_time": "$(date -Iseconds)",
  "completed": [],
  "failed": [],
  "warnings": []
}
EOF
    fi
}

mark_completed() {
    local step="$1"
    python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
    if '$step' not in state['completed']:
        state['completed'].append('$step')
    with open('$STATE_FILE', 'w') as f:
        json.dump(state, f, indent=2)
except Exception as e:
    print(f'Warning: Could not update state: {e}')
" 2>/dev/null || true
}

is_completed() {
    local step="$1"
    python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
    print('yes' if '$step' in state['completed'] else 'no')
except:
    print('no')
" 2>/dev/null || echo "no"
}

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_path="$BACKUP_DIR${file}"
        mkdir -p "$(dirname "$backup_path")"
        cp -a "$file" "$backup_path"
        log "Backed up: $file"
    fi
}

# ===== BANNER =====

show_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║   ███▄    █  ██▓ ██▀███   ██▓    ▓█████▄ ▓█████   ██████  ██ ▄█▀▄▄▄█████▓ ▒█████   ██▓███      ║
║   ██ ▀█   █ ▓██▒▓██ ▒ ██▒▓██▒    ▒██▀ ██▌▓█   ▀ ▒██    ▒  ██▄█▒ ▓  ██▒ ▓▒▒██▒  ██▒▓██░  ██▒    ║
║  ▓██  ▀█ ██▒▒██▒▓██ ░▄█ ▒▒██▒    ░██   █▌▒███   ░ ▓██▄   ▓███▄░ ▒ ▓██░ ▒░▒██░  ██▒▓██░ ██▓▒    ║
║  ▓██▒  ▐▌██▒░██░▒██▀▀█▄  ░██░    ░▓█▄   ▌▒▓█  ▄   ▒   ██▒▓██ █▄ ░ ▓██▓ ░ ▒██   ██░▒██▄█▓▒ ▒    ║
║  ▒██░   ▓██░░██░░██▓ ▒██▒░██░    ░▒████▓ ░▒████▒▒██████▒▒▒██▒ █▄  ▒██▒ ░ ░ ████▓▒░▒██▒ ░  ░    ║
║  ░ ▒░   ▒ ▒ ░▓  ░ ▒▓ ░▒▓░░▓       ▒▒▓  ▒ ░░ ▒░ ░▒ ▒▓▒ ▒ ░▒ ▒▒ ▓▒  ▒ ░░   ░ ▒░▒░▒░ ▒▓▒░ ░  ░    ║
║  ░ ░░   ░ ▒░ ▒ ░  ░▒ ░ ▒░ ▒ ░     ░ ▒  ▒  ░ ░  ░░ ░▒  ░ ░░ ░▒ ▒░    ░      ░ ▒ ▒░ ░▒ ░         ║
║     ░   ░ ░  ▒ ░  ░░   ░  ▒ ░     ░ ░  ░    ░   ░  ░  ░  ░ ░░ ░   ░      ░ ░ ░ ▒  ░░           ║
║           ░  ░     ░      ░         ░       ░  ░      ░  ░  ░                ░ ░               ║
║                                    ░                                                           ║
║   Niri + DankMaterialShell Installer - Optimized For CachyOS                                   ║
║   • Target System: CachyOS + Niri + DankMaterialShell                                          ║
║   • Hardware: ROG STRIX B550-XE GAMING WIFI | Ryzen 7 5800X | RTX 3060 12GB                    ║
║   • Optimizations: Performance adjustments, Vietnamese input methods...                        ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

clone_repo(){
    local repo_dir="$HOME/.local/share/Niri"
    
    if [ -d "$repo_dir/.git" ]; then
        log "Repository already exists, pulling latest changes..."
        cd "$repo_dir" || error "Failed to cd to $repo_dir"
        git pull || warn "Failed to pull latest changes, continuing with existing version"
    else
        log "Cloning repository..."
        git clone https://github.com/hoangducdt/Niri.git "$repo_dir" || error "Failed to clone repository"
        cd "$repo_dir" || error "Failed to cd to $repo_dir"
    fi
}

# ===== PACKAGE MANAGEMENT =====

handle_conflicts() {
    log "Checking and removing conflicting packages..."
    
    # Conflict 1: pipewire-jack vs jack2
    if pacman -Qi jack2 &>/dev/null; then
        log "Removing jack2 (conflicts with pipewire-jack)..."
        sudo pacman -Rdd --noconfirm jack2 2>&1 | tee -a "$LOG" || warn "Failed to remove jack2"
    fi
    
    # Conflict 2: rust vs rustup
    if pacman -Qi rustup &>/dev/null; then
        if pacman -Qi rust &>/dev/null; then
            log "Removing rust (conflicts with rustup)..."
            sudo pacman -Rdd --noconfirm rust 2>&1 | tee -a "$LOG" || warn "Failed to remove rust"
        fi
    fi
    
    # Conflict 3: obs-studio-browser vs obs-studio
    if pacman -Qi obs-studio-browser &>/dev/null; then
        log "Removing obs-studio-browser (conflicts with obs-studio)..."
        sudo pacman -Rdd --noconfirm obs-studio-browser 2>&1 | tee -a "$LOG" || warn "Failed to remove obs-studio-browser"
    fi
    
    log "✓ Conflict check completed"
}

install_package() {
    local pkg="$1"
    local max_retries=3
    local retry=0
    
    if pacman -Qi "$pkg" &>/dev/null; then
        return 0
    fi
    
    while [ $retry -lt $max_retries ]; do
        if sudo pacman -S --noconfirm "$pkg" 2>&1 | tee -a "$LOG"; then
            log "✓ Successfully installed: $pkg"
            return 0
        fi
        
        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            warn "Retry installing $pkg ($retry/$max_retries)..."
            sleep 2
        fi
    done
    
    warn "Failed to install $pkg"
    return 1
}

install_aur_package() {
    local pkg="$1"
    local max_retries=3
    local retry=0
    
    if pacman -Qi "$pkg" &>/dev/null; then
        return 0
    fi
    
    while [ $retry -lt $max_retries ]; do
        if paru -S --noconfirm "$pkg" 2>&1 | tee -a "$LOG"; then
            log "✓ Successfully installed (AUR): $pkg"
            return 0
        fi
        
        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            warn "Retry installing $pkg ($retry/$max_retries)..."
            sleep 2
        fi
    done
    
    warn "Failed to install AUR package: $pkg"
    return 1
}

install_packages() {
    local packages=("$@")
    local failed=()
    
    for pkg in "${packages[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            continue
        fi
        
        if pacman -Si "$pkg" &>/dev/null 2>&1; then
            if ! install_package "$pkg"; then
                failed+=("$pkg")
            fi
        else
            log "Package '$pkg' not found in official repos, trying AUR..."
            if ! install_aur_package "$pkg"; then
                failed+=("$pkg")
            fi
        fi
    done
    
    if [ ${#failed[@]} -gt 0 ]; then
        warn "Failed packages: ${failed[*]}"
    fi
}

install_aur_packages() {
    local pkgs=("$@")
    local failed=()
    
    for pkg in "${pkgs[@]}"; do
        if ! install_aur_package "$pkg"; then
            failed+=("$pkg")
        fi
    done
    
    if [ ${#failed[@]} -gt 0 ]; then
        warn "Some AUR packages failed to install: ${failed[*]}"
    fi
}

install_helper() {
    if [ "$(is_completed install_helper)" == "yes" ]; then
        log "Helper tools already installed"
        return
    fi
    
    log "Installing helper tools..."
    
    local helper_pkgs=(
        "base-devel"
        "git"
        "wget"
        "curl"
        "python"
        "python-pip"
    )
    
    install_packages "${helper_pkgs[@]}"
    
    # Install paru if needed
    if ! command -v paru &> /dev/null; then
        log "Installing paru AUR helper..."
        cd /tmp
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/paru-bin
    fi
    
    mark_completed "install_helper"
    log "✓ Helper tools installed"
}

# ===== SYSTEM UPDATE =====

setup_system_update() {
    if [ "$(is_completed system_update)" == "yes" ]; then
        log "System already updated"
        return
    fi
    
    log "Updating system..."
    sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG"
    
    mark_completed "system_update"
    log "✓ System updated"
}

# ===== NVIDIA OPTIMIZATION =====

setup_nvidia_optimization() {
    if [ "$(is_completed nvidia)" == "yes" ]; then
        log "✓ NVIDIA optimization already applied"
        return
    fi
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "NVIDIA OPTIMIZATION (Config Only - Packages in base_packages)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! lspci | grep -i nvidia &>/dev/null; then
        log "⊘ No NVIDIA GPU detected, skipping"
        mark_completed "nvidia"
        return
    fi
    
    log "✓ NVIDIA GPU detected:"
    lspci | grep -i nvidia | head -1
    echo ""
    
    log "Checking driver status..."
    
    if ! pacman -Qi nvidia-utils &>/dev/null; then
        warn "NVIDIA driver not found! It should be installed by base_packages."
        warn "Please wait for base_packages installation to complete."
    else
        log "✓ Driver found:"
        pacman -Q | grep -E '^(linux-cachyos-nvidia|nvidia-utils|lib32-nvidia)' | sed 's/^/  • /'
        echo ""
    fi
    
    # Backup existing configs
    [ -f "/etc/mkinitcpio.conf" ] && backup_file "/etc/mkinitcpio.conf"
    [ -f "/etc/modprobe.d/nvidia.conf" ] && backup_file "/etc/modprobe.d/nvidia.conf"
    
    log "Applying optimizations..."
    
    # 1. Modprobe configuration
    sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<'NVIDIA_CONF'
# NVIDIA RTX 3060 Optimization
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_UsePageAttributeTable=1
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_EnableGpuFirmware=0
NVIDIA_CONF
    log "✓ Modprobe config applied"
    
    # 2. Mkinitcpio configuration
    if grep -q "^MODULES=" /etc/mkinitcpio.conf; then
        if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
            sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
            log "✓ Mkinitcpio updated & rebuilt"
        else
            log "✓ Mkinitcpio already configured"
        fi
    fi
    
    # 3. Enable NVIDIA services
    for svc in nvidia-suspend nvidia-hibernate nvidia-resume; do
        if systemctl list-unit-files | grep -q "${svc}.service"; then
            sudo systemctl enable "${svc}.service" 2>/dev/null || true
        fi
    done
    log "✓ NVIDIA services enabled"
    
    mark_completed "nvidia"
    
    echo ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✓ NVIDIA OPTIMIZATION COMPLETE!"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ===== BASE PACKAGES (FULL LIST) =====

setup_base_packages() {
    if [ "$(is_completed base_packages)" == "yes" ]; then
        log "✓ Base packages already installed"
        return
    fi
    
    log "Installing base packages (CachyOS optimized with Niri)..."
    local meta_pkgs=(
		# ==========================================================================
		# PHASE 1: CORE SYSTEM DEPENDENCIES (Cài đầu tiên - Foundation)
		# ==========================================================================
		
		## 1.1 Base System Libraries
		"python"                        # Core Python runtime - Dependency của nhiều tools
		"python-pip"                    # Python package manager
		"python-virtualenv"             # Virtual environments
		
		## 1.2 Essential System Tools
		"git-lfs"                       # Git Large File Storage - BẮT BUỘC cho UE5 assets
		"rsync"                         # File synchronization
		"tmux"                          # Terminal multiplexer
		"jq"                            # JSON processor - Dependency của scripts
        "i2c-tools"                     # I2C/SMBus utilities for sensors/RGB
        "dmidecode"                     # Hardware information decoder
        "fwupd"                         # Firmware update manager
        "libnotify"                     # Library for sending desktop notifications
		"inotify-tools"                 # File system event monitoring
		
		## 1.3 Compression Tools (Dependencies cho nhiều packages)
		"zip"                           # ZIP compression
		"unzip"                         # ZIP extraction
		"p7zip"                         # 7-Zip compression
		"unrar"                         # RAR extraction
        "ark"                           # KDE archive manager - GUI for all formats
		"thunar-archive-plugin"			# Thunar Archive Plugin
		
		## 1.4 File System Support
		"btrfs-progs"                   # Btrfs file system utilities
		"exfatprogs"                    # exFAT file system support
		"ntfs-3g"                       # NTFS read/write support
		"dosfstools"                    # FAT/FAT32 utilities
		
		# ==========================================================================
		# PHASE 2: DISPLAY & GRAPHICS FOUNDATION
		# ==========================================================================
		
		## 2.1 Wayland Core
		"qt5-wayland"                   # Qt5 Wayland support
		"qt6-wayland"                   # Qt6 Wayland support
		"wl-clipboard"                  # Wayland clipboard utilities
		"xdg-desktop-portal-gtk"        # XDG portal for file dialogs
		"xdg-desktop-portal-gnome"      # GNOME portal (for Niri)
		
		## 2.2 Graphics Libraries (Cài trước GPU drivers/apps)
		"vulkan-icd-loader"             # Vulkan loader - BẮT BUỘC cho gaming/UE5
		"lib32-vulkan-icd-loader"       # 32-bit Vulkan support
		
		## 2.3 NVIDIA Hardware Acceleration
		"libva-nvidia-driver"           # VA-API for NVIDIA - Video acceleration
		"lib32-nvidia-utils"            # 32-bit NVIDIA utilities - Cho gaming
		
		# ==========================================================================
		# PHASE 3: AUDIO FOUNDATION (Cài trước multimedia apps)
		# ==========================================================================
		
		## 3.1 PipeWire Core (Modern audio server)
		"pipewire"                      # Core audio/video server
		"pipewire-pulse"                # PulseAudio replacement
		"pipewire-alsa"                 # ALSA support
		"pipewire-jack"                 # JACK audio support - Thay thế jack2
		"wireplumber"                   # Session manager for PipeWire
		
		## 3.2 Audio Tools
		"pavucontrol"                   # GUI volume control
		"helvum"                        # PipeWire patchbay GUI
        "easyeffects"                   # Audio effects for PipeWire
        "qpwgraph"                      # PipeWire graph editor
		"v4l2loopback-dkms"             # Virtual video device - Cho OBS
		"noise-suppression-for-voice"   # AI noise cancellation - Cho streaming
		
		# ==========================================================================
		# PHASE 4: MULTIMEDIA CODECS (Dependencies cho video/audio apps)
		# ==========================================================================
		
		## 4.1 GStreamer Framework
		"gstreamer"                     # Multimedia framework core
		"gstreamer-vaapi"               # VA-API acceleration for GStreamer
		"gst-plugins-base"              # Base plugins
		"gst-plugins-good"              # Good quality plugins
		"gst-plugins-bad"               # Experimental plugins
		"gst-plugins-ugly"              # Legally restricted plugins
		"gst-libav"                     # Libav wrapper plugin
		
		## 4.2 FFmpeg & Codecs
		"ffmpeg"                        # Complete multimedia solution
		"lib32-ffmpeg"                  # 32-bit FFmpeg - Cho gaming/Proton
		"x264"                          # H.264 encoder
		"x265"                          # HEVC encoder
		
		## 4.3 Audio Codecs
		"libvorbis"                     # Vorbis audio codec
		"lib32-libvorbis"               # 32-bit Vorbis
		"opus"                          # Opus audio codec
		"lib32-opus"                    # 32-bit Opus
		"flac"                          # FLAC lossless audio
		"lib32-flac"                    # 32-bit FLAC
		
		# ==========================================================================
		# PHASE 5: DEVELOPMENT TOOLS FOUNDATION
		# ==========================================================================
		
		## 5.1 Build System Core (Cài trước compilers)
		"cmake"                         # Cross-platform build system - UE5 dependency
		"ninja"                         # Fast build tool - UE5 build system
		"meson"                         # Modern build system
		"ccache"                        # Compiler cache - TĂNG TỐC build UE5
		
		## 5.2 Compilers & Linkers
		"gcc"                           # GNU C/C++ compiler
		"clang"                         # LLVM C/C++ compiler - UE5 prefer Clang
		"lld"                           # LLVM linker - NHANH hơn ld cho UE5
		
		## 5.3 Version Control
		"github-cli"                    # GitHub CLI tool
		"github-desktop"                # GitHub Desktop GUI
		
		## 5.4 Programming Languages
		"nodejs"                        # Node.js runtime
		"npm"                           # Node package manager
		#"rust"                       	# Rust language - REMOVED: conflicts with rustup
		"go"                            # Go language
		
		## 5.5 Python Development
		"python-numpy"                  # Numerical computing
		"python-pandas"                 # Data analysis
		"python-matplotlib"             # Plotting library
		"python-pillow"                 # Image processing
		"python-scipy"                  # Scientific computing
		"python-scikit-learn"           # Machine learning
		"jupyter-notebook"              # Interactive notebooks
        "python-build"					# Python build frontend
        "python-installer"				# Python package installer
        "python-hatch"					# Project manager
        "python-hatch-vcs"				# Hatch plugin for versioning
        "qt6-declarative"				# QML and JavaScript
        "libqalculate"					# Multi-purpose calculator
        "qt6-base"						# Qt6 framework
		
		## 5.6 3D Development Libraries (Cho UE5)
		"assimp"                        # 3D model import library
		"fbx-sdk"                       # FBX SDK - Import/export FBX for UE5
		"helix-cli"                     # Perforce Helix client
		
		# ==========================================================================
		# PHASE 6: .NET DEVELOPMENT STACK
		# ==========================================================================
		
		## 6.1 .NET Runtime & SDK
		"dotnet-runtime"                # .NET runtime
		"dotnet-sdk-8.0"                # .NET 8.0 LTS SDK
		"dotnet-sdk-9.0"                # .NET 9.0 Latest SDK
		"dotnet-sdk"                    # Latest SDK meta-package
		"aspnet-runtime"                # ASP.NET Core runtime
		"mono"                          # Mono framework
		"mono-msbuild"                  # MSBuild for Mono
		
		# ==========================================================================
		# PHASE 7: CONTAINERIZATION & DATABASES
		# ==========================================================================
		
		## 7.1 Container Platform
		"docker"						# Docker Engine
		#"docker-desktop"                # Docker Desktop - Bao gồm docker + compose | ⚠️ KHÔNG cài riêng "docker" và "docker-compose"
        "docker-compose"				# Docker Compose
        "nvidia-container-toolkit"      # NVIDIA Container Toolkit

		## 7.2 Databases
		"postgresql"                    # PostgreSQL database
		"redis"                         # Redis in-memory database
		
		# ==========================================================================
		# PHASE 8: AI/ML STACK
		# ==========================================================================
		
		## 8.1 CUDA Foundation (Cài trước PyTorch)
		"cuda"                          # NVIDIA CUDA Toolkit
		"cudnn"                         # CUDA Deep Neural Network library
		
		## 8.2 PyTorch with CUDA
		"python-pytorch-cuda"           # PyTorch with CUDA support
		"python-torchvision-cuda"       # Computer vision for PyTorch
		"python-torchaudio-cuda"        # Audio processing for PyTorch
		"python-transformers"           # Hugging Face Transformers
		"python-accelerate"             # Training acceleration library
		
		## 8.3 Local AI Runtime
		#"ollama-cuda"                   # Local LLM inference with CUDA
		
		# ==========================================================================
		# PHASE 9: GAMING STACK
		# ==========================================================================
		
		## 9.1 Gaming Core
		"gamemode"                      # CPU governor optimization for gaming
		"lib32-gamemode"                # 32-bit gamemode
		"xpadneo-dkms"                  # Xbox controller support
		
		## 9.2 CachyOS Gaming Meta-packages (Bao gồm nhiều dependencies)
		"cachyos-gaming-meta"           # Includes: Wine, Proton, Vulkan tools, lib32 libs
										# Dependencies: alsa-plugins, giflib, glfw, gst-plugins-base-libs
										#               lib32-* variants, proton-cachyos-slr, umu-launcher
										#               protontricks, wine-cachyos-opt, winetricks, vulkan-tools
		
		"cachyos-gaming-applications"   # Includes: Steam, Lutris, Heroic, MangoHud, Gamescope
										# Dependencies: gamescope, goverlay, heroic-games-launcher
										#               lib32-mangohud, mangohud, steam, wqy-zenhei
		
		## 9.3 Gaming Utilities
		"protonup-qt"                   # Proton-GE version manager GUI
		"asf"                   		# ArchiSteamFarm is a tool for automatically farming Steam trading cards on multiple accounts simultaneously.
		
		# ==========================================================================
		# PHASE 10: 3D CREATION & BLENDER ECOSYSTEM
		# ==========================================================================
		
		## 10.1 Blender Core
		"blender"                       # 3D creation suite
		
		## 10.2 Blender Dependencies
		"openimagedenoise"              # AI-powered denoising
		"opencolorio"                   # Color management
		"opensubdiv"                    # Subdivision surfaces
		"openvdb"                       # Volumetric data structure
		"embree"                        # Ray tracing kernel
		"openimageio"                   # Image I/O library
		"alembic"                       # Animation interchange
		"openjpeg2"                     # JPEG 2000 codec
		"openexr"                       # HDR image format
		"libspnav"                      # 3D mouse support
		
		# ==========================================================================
		# PHASE 11: 2D GRAPHICS & DESIGN TOOLS
		# ==========================================================================
		
		## 11.1 Raster Graphics
		"imv"       					# Wayland-native image viewer
        "gwenview"                      # KDE image viewer
		"gimp"                          # GNU Image Manipulation Program
		"gimp-plugin-gmic"              # G'MIC plugin for GIMP
		"krita"                         # Digital painting
		
		## 11.2 Vector Graphics
		"inkscape"                      # Vector graphics editor
		
		## 11.3 Photo Editing
		"darktable"                     # RAW photo workflow
		"rawtherapee"                   # Advanced RAW editor
		
		## 11.4 Image Processing
		"imagemagick"                   # Command-line image processing
		"graphicsmagick"                # Image processing fork
		"potrace"                       # Bitmap to vector tracing
		
		## 11.5 Font Tools
		"fontforge"                     # Font editor
		
		# ==========================================================================
		# PHASE 12: VIDEO & AUDIO PRODUCTION
		# ==========================================================================
		
		## 12.1 Video Editing
		"kdenlive"                      # Video editor
		"frei0r-plugins"                # Video effects plugins
		"mediainfo"                     # Media file information
		"mlt"                           # Multimedia framework for kdenlive
		"davinci-resolve"               # Professional video editor
		"natron"                        # Compositing & VFX
		
		## 12.2 Video Players
		"mpv"                           # Minimalist video player
		"vlc"                           # VLC media player
		
		## 12.3 Audio Production
		"audacity"                      # Audio wave editor
		"ardour"                        # Digital Audio Workstation (DAW)
        "aubio"
        "libpipewire"
		
		## 12.4 Streaming & Recording
		"obs-studio"                    # Streaming/recording software
		"obs-vaapi"                     # VA-API plugin for OBS
		"obs-nvfbc"                     # NVIDIA capture plugin
		"obs-vkcapture"                 # Vulkan capture plugin
		#"obs-websocket"               # WebSocket plugin - REMOVED: installs obs-studio-browser which conflicts with obs-studio
		
		# ==========================================================================
		# PHASE 13: PUBLISHING & DOCUMENT TOOLS
		# ==========================================================================
		
		"scribus"                       # Desktop publishing
		
		## 13.1 PDF Tools
		"zathura"                       # Minimalist PDF viewer
		"zathura-pdf-poppler"           # Poppler backend for zathura
        "okular"                        # KDE document viewer
		
		# ==========================================================================
		# PHASE 14: PROFESSIONAL DEVELOPMENT TOOLS
		# ==========================================================================
		
		## 14.1 Code Editors
		"neovim"                        # Modern Vim
		"codium"                        # VSCodium - Open-source VS Code
        "kate"                          # KDE Advanced Text Editor
		
		## 14.2 IDEs
		"rider"                         # JetBrains Rider
		"lmstudio"                      # Local LLM GUI
		
		## 14.3 API Testing
		"postman-bin"                   # API testing tool
		
		# ==========================================================================
		# PHASE 15: NIRI WINDOW MANAGER
		# ==========================================================================
		
		## 15.1 Niri Core
		"niri"                          # Scrollable-tiling Wayland compositor
		"xwayland-satellite"            # XWayland rootful server
		
		## 15.2 Niri/Wayland Utilities
        "ddcutil"						# Query and change Linux monitor settings using DDC/CI and USB.
        "brightnessctl"					# Lightweight brightness control tool
		"cliphist"                      # Clipboard manager
		"kanshi"                        # Dynamic display configuration
		"nwg-displays"                  # Display manager GUI
        "libcava"						# Cava library
        "swappy"						# Screenshot editor for Wayland
        "grim"							# Screenshot utility for Wayland
        "dart-sass"						# Sass compiler
        "slurp"							# Region selector for Wayland
        "gpu-screen-recorder"			# Screen recorder for Linux
        "glib2"							# Low level core library
        "fuzzel"						# Application launcher for Wayland
		
		## 15.3 DankMaterialShell
        "quickshell"                    # The core framework
        "cava"                          # Console audio visualizer
        "matugen"                       # Material You color generation
        "qt6-multimedia-ffmpeg"         # Qt6 multimedia with FFmpeg
        "dgop"                          # System telemetry for resource widgets
        "dsearch"                       # Filesystem search engine
		"dms-shell-bin"                 # DankMaterialShell
        
		# ==========================================================================
		# PHASE 16: GTK/QT THEMING & APPEARANCE
		# ==========================================================================
		
		## 16.1 Themes
		"adw-gtk-theme"                 # Adwaita GTK theme
		"papirus-icon-theme"            # Papirus icon theme
		"tela-circle-icon-theme-git"    # Tela Circle icon theme
		"whitesur-icon-theme-git"       # WhiteSur icon theme
		"numix-circle-icon-theme-git"   # Numix Circle icon theme
		"qt5ct-kde"                     # Qt5 configuration tool
		"qt6ct-kde"                     # Qt6 configuration tool
        "nwg-look"						# GTK settings editor
        "accountsservice"               # D-Bus interface for user account query and manipulatio
		
		## 16.2 Authentication
		"gnome-keyring"                 # Password manager
		"polkit-gnome"                  # Polkit authentication agent
		
		# ==========================================================================
		# PHASE 17: FILE MANAGER & THUMBNAILS
		# ==========================================================================
		
		"thunar"                        # Lightweight file manager
		"tumbler"                       # Thumbnail generator
		"ffmpegthumbnailer"             # Video thumbnail generator
		"libgsf"                        # Structured file library
		"file-roller"                   # Archive manager
		
		# ==========================================================================
		# PHASE 18: TERMINAL & SHELL ENHANCEMENTS
		# ==========================================================================
		
		## 18.1 Terminal Emulator
		"fish"                          # Friendly shell
		"kitty"                         # GPU-accelerated terminal
		"alacritty"                     # GPU-accelerated terminal
		
		## 18.2 Shell Utilities
		"starship"                      # Cross-shell prompt
		"eza"                           # Modern ls replacement
		"bat"                           # Cat with syntax highlighting
		"ripgrep"                       # Fast grep alternative
		"fd"                            # Fast find alternative
		"fzf"                           # Fuzzy finder
		"zoxide"                        # Smart cd command
		"direnv"                        # Directory-based environments
		"trash-cli"                     # CLI trash management
		"app2unit"                      # Systemd unit generator
		
		# ==========================================================================
		# PHASE 19: SYSTEM MONITORING & MANAGEMENT
		# ==========================================================================
		
		## 19.1 System Monitors
		"htop"                          # Interactive process viewer
		"btop"                          # Resource monitor
		"neofetch"                      # System information
		"fastfetch"                     # Fast system information
		"nvtop"                         # NVIDIA GPU monitor
        "lm_sensors"                    # Hardware monitoring sensors
        "zenmonitor"                    # AMD Ryzen monitor GUI
        "corectrl"                      # AMD GPU/CPU control center
		"iotop"                         # I/O monitor
		"iftop"                         # Network monitor
		
		## 19.2 Power Management
		"irqbalance"                    # IRQ load balancing
		"cpupower"                      # CPU frequency scaling
		"thermald"                      # Thermal management
		"tlp"                           # Power management
		"powertop"                      # Power consumption analyzer
        "ryzenadj"                      # Ryzen power adjustment
        "auto-cpufreq"                  # Automatic CPU frequency optimization
		"preload"                       # Application preloader
		
		# ==========================================================================
		# PHASE 20: DISK & STORAGE MANAGEMENT
		# ==========================================================================
		
		"gparted"                       # Partition editor GUI
		"gnome-disk-utility"            # Disk management GUI
		
		# ==========================================================================
		# PHASE 21: NETWORK MANAGEMENT
		# ==========================================================================
		
		"networkmanager"                # Network connection manager
        "iwd"                           # Intel Wireless Daemon
        "bluez"                         # Bluetooth protocol stack
        "bluez-utils"                   # Bluetooth utilities
        "blueman"                       # Bluetooth manager GUI
		"network-manager-applet"        # NetworkManager tray applet
		"nm-connection-editor"          # NetworkManager GUI editor
		
		# ==========================================================================
		# PHASE 22: DISPLAY MANAGER & LOGIN
		# ==========================================================================
		
		"gdm"                           # GNOME Display Manager
		"gdm-settings"                  # GDM configuration tool
		
		# ==========================================================================
		# PHASE 23: RGB & PERIPHERAL CONTROL
		# ==========================================================================
		
		"openrgb"                       # RGB lighting control
		
		# ==========================================================================
		# PHASE 24: INPUT METHOD (Vietnamese)
		# ==========================================================================
		
		## 24.1 Fcitx5 Core
		"fcitx5"                        # Input method framework
		"fcitx5-qt"                     # Qt5/Qt6 support
		"fcitx5-gtk"                    # GTK support
		"fcitx5-configtool"             # Configuration GUI
		"fcitx5-bamboo-git"             # Vietnamese input method
		
		# ==========================================================================
		# PHASE 25: WEB BROWSER & COMMUNICATION
		# ==========================================================================
		
		"microsoft-edge-stable-bin"     # Microsoft Edge browser
		"vesktop-bin"                   # Discord with Vencord
		
		# ==========================================================================
		# PHASE 26: PRODUCTIVITY APPS
		# ==========================================================================
		
		"todoist-appimage"              # Task management
		
		# ==========================================================================
		# PHASE 27: FONTS
		# ==========================================================================
		
        "ttf-material-symbols-variable" # Material Design icons
        "ttf-cascadia-code-nerd"        # Cascadia Code Nerd Font
		"ttf-rubik-vf"          		# Rubik variable font
		"ttf-jetbrains-mono-nerd"       # JetBrains Mono Nerd Font
		"adobe-source-code-pro-fonts"   # Adobe Source Code Pro
		"ttf-liberation"                # Liberation fonts
		"ttf-dejavu"                    # DejaVu fonts
		"ttf-font-awesome"              # Font Awesome
		"noto-fonts"                    # Noto fonts
		"noto-fonts-cjk"                # CJK fonts
		"noto-fonts-emoji"              # Emoji fonts
		
		# ==========================================================================
		# PHASE 28: XDG UTILITIES
		# ==========================================================================
		
		"xdg-user-dirs"                 # User directories
		"xdg-utils"                     # XDG utilities
	)
	
    install_packages "${meta_pkgs[@]}"
	
    # Enable NetworkManager
    sudo systemctl enable NetworkManager
    
    # Add DMS to niri autostart
    systemctl --user add-wants niri.service dms 2>/dev/null || warn "Failed to add DMS to niri autostart"
    
    mark_completed "base_packages"
    log "✓ Base packages installed"
}

# ===== GAMING =====

setup_gaming() {
    if [ "$(is_completed gaming)" == "yes" ]; then
        log "Gaming setup already done"
        return
    fi
    
    log "Setting up gaming environment..."
    
    # Enable multilib (32-bit support for gaming)
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log "Enabling multilib repository..."
        sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
        sudo pacman -Sy
    fi
    
    # Configure gamemode
    sudo usermod -aG gamemode "$USER"

    # Configure ASF
	sudo chown -R "$USER":"$USER" /usr/lib/asf/

	cd /usr/lib/asf
	mkdir -p "www"

	if [ -d "/usr/lib/asf/temp-ui/.git" ]; then
        log "Repository already exists, pulling latest changes..."
        cd temp-ui
        sudo git pull || warn "Failed to pull latest changes, continuing with existing version"
    else
        log "Cloning repository..."
        sudo git clone https://github.com/JustArchiNET/ASF-ui.git temp-ui || error "Failed to clone repository"
        cd temp-ui
    fi
	
	sudo npm install
	sudo npm run build
	cd ..
	sudo cp -r temp-ui/dist/* www/
	sudo rm -rf temp-ui
    
    mark_completed "gaming"
    log "✓ Gaming setup completed"
}

# ===== DOCKER =====

setup_docker() {
    if [ "$(is_completed docker)" == "yes" ]; then
        log "✓ Docker already configured"
        return
    fi
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "DOCKER SETUP & AUTO-START (Packages in base_packages)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log "Checking Docker installation..."
    
    # Kiểm tra Docker đã cài đặt chưa
    if ! command -v docker &>/dev/null; then
        warn "Docker not found! It should be installed by base_packages."
        warn "Please wait for base_packages installation to complete."
        mark_completed "docker"
        return
    fi
    
    if ! command -v docker-compose &>/dev/null; then
        warn "Docker Compose not found! It should be installed by base_packages."
    fi
    
    log "✓ Docker found: $(docker --version)"
    log "✓ Docker Compose found: $(docker-compose --version)"
    
    # ========================================
    # CONFIGURE DOCKER AUTO-START
    # ========================================
    
    log "Configuring Docker auto-start..."
    
    # 1. Enable Docker service
    sudo systemctl enable docker.service 2>&1 | tee -a "$LOG" || warn "Failed to enable docker.service"
    sudo systemctl enable docker.socket 2>&1 | tee -a "$LOG" || warn "Failed to enable docker.socket"
    
    # 2. Start Docker service immediately
    sudo systemctl start docker.service 2>&1 | tee -a "$LOG" || warn "Failed to start docker.service"
    sudo systemctl start docker.socket 2>&1 | tee -a "$LOG" || warn "Failed to start docker.socket"
    
    log "✓ Docker service enabled and started"
    
    # ========================================
    # CONFIGURE USER PERMISSIONS
    # ========================================
    
    log "Configuring user permissions for Docker..."
    
    # 3. Add user to docker group
    if ! getent group docker > /dev/null 2>&1; then
        sudo groupadd docker
        log "✓ Created docker group"
    fi
    
    # Add user to docker group
    sudo usermod -aG docker "$USER" 2>&1 | tee -a "$LOG"
    log "✓ Added $USER to docker group"
    
    # ========================================
    # CONFIGURE NVIDIA CONTAINER TOOLKIT
    # ========================================
    
    log "Configuring NVIDIA Container Toolkit..."
    
    # 4. Configure NVIDIA container runtime
    if command -v nvidia-ctk &>/dev/null; then
        sudo nvidia-ctk runtime configure --runtime=docker 2>&1 | tee -a "$LOG" || warn "Failed to configure NVIDIA runtime"
        
        # Restart Docker to apply NVIDIA runtime
        sudo systemctl restart docker 2>&1 | tee -a "$LOG" || warn "Failed to restart docker"
        log "✓ NVIDIA Container Toolkit configured"
    else
        warn "⚠ NVIDIA Container Toolkit not found, skipping NVIDIA GPU support"
    fi
    
    # ========================================
    # TEST DOCKER INSTALLATION
    # ========================================
    
    log "Testing Docker installation..."
    
    # 5. Test Docker without sudo
    sleep 2  # Give time for group changes
    
    # Create a simple test container
    if docker run --rm hello-world 2>&1 | tee -a "$LOG" | grep -q "Hello from Docker"; then
        log "✓ Docker test successful (hello-world)"
    else
        warn "⚠ Docker test failed - you may need to log out and log back in"
    fi
    
    # 6. Test NVIDIA container support
    if command -v nvidia-smi &>/dev/null; then
        log "Testing NVIDIA GPU in containers..."
        if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi 2>&1 | tee -a "$LOG" | grep -q "NVIDIA-SMI"; then
            log "✓ NVIDIA GPU container support working"
        else
            warn "⚠ NVIDIA GPU container support may not be working"
        fi
    fi
    
    # ========================================
    # CONFIGURE DOCKER DAEMON
    # ========================================
    
    log "Configuring Docker daemon settings..."
    
    # 7. Create/update Docker daemon.json
    local docker_daemon_config="/etc/docker/daemon.json"
    backup_file "$docker_daemon_config"
    
    sudo tee "$docker_daemon_config" > /dev/null <<'DOCKER_DAEMON'
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
DOCKER_DAEMON
    
    sudo chmod 644 "$docker_daemon_config"
    log "✓ Docker daemon configuration updated"
    
    # 8. Restart Docker to apply new configuration
    sudo systemctl restart docker 2>&1 | tee -a "$LOG" || warn "Failed to restart docker"
    
    # ========================================
    # CREATE DOCKER VOLUME DIRECTORIES
    # ========================================
    
    log "Creating Docker volume directories..."
    
    # 9. Create common Docker directories
    local docker_dirs=(
        "$HOME/docker"
        "$HOME/docker/compose"
        "$HOME/docker/volumes"
        "$HOME/docker/volumes/postgres"
        "$HOME/docker/volumes/redis"
        "$HOME/docker/volumes/mysql"
    )
    
    for dir in "${docker_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    log "✓ Docker directories created"
    
    mark_completed "docker"
    
    echo ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✓ DOCKER SETUP COMPLETE!"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ===== MULTIMEDIA =====

setup_multimedia() {
    if [ "$(is_completed multimedia)" == "yes" ]; then
        log "Multimedia already configured"
        return
    fi
    
    log "Configuring multimedia (enabling pipewire services)..."
    
    # Enable Pipewire
    systemctl --user enable pipewire
    systemctl --user enable pipewire-pulse
    systemctl --user enable wireplumber
    
    mark_completed "multimedia"
    log "✓ Multimedia configured"
}

setup_ai_ml() {
    if [ "$(is_completed 'ai_ml')" = "yes" ]; then
        log "✓ AI/ML already installed"
        return 0
    fi
    
    ai_info "Installing AI/ML stack (CUDA RTX 3060)..."

    # Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh

    # Create ollama user
    sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama 2>/dev/null || true
    sudo usermod -a -G ollama "$(whoami)"

    # ========================================
    # CUSTOM MODEL DIRECTORY CONFIGURATION
    # ========================================
    
    ai_info "Configuring Ollama model storage..."
    
    # Fixed model directory
    local model_dir="$HOME/AI-Models/ollama"
    
    ai_info "Model directory: $model_dir"
    
    # Create directory
    mkdir -p "$model_dir" || error "Failed to create directory: $model_dir"
    
    # Set ownership to ollama user
    sudo chown -R ollama:ollama "$model_dir" 2>&1 | tee -a "$LOG" || warn "Failed to set ownership"
    
    # Set permissions (770 - owner and group can read/write/execute)
    sudo chmod -R 770 "$model_dir" 2>&1 | tee -a "$LOG" || warn "Failed to set permissions"
    
    ai_info "✓ Model directory created: $model_dir"
    
    # Display storage info
    local storage_info
    storage_info=$(df -h "$model_dir" 2>/dev/null | tail -1 | awk '{print $4 " available of " $2 " total"}')
    ai_info "Storage: $storage_info"

    # ========================================
    # SYSTEMD SERVICE CONFIGURATION
    # ========================================
    
    ai_info "Creating Ollama systemd service..."

    # Check if NVIDIA is available
    local gpu_env=""
    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        ai_info "✓ NVIDIA GPU detected, enabling GPU support"
        gpu_env='Environment="CUDA_VISIBLE_DEVICES=0"'
    fi

    sudo tee /etc/systemd/system/ollama.service > /dev/null <<OLLAMA_SERVICE
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=\$PATH"
Environment="OLLAMA_MODELS=$model_dir"
${gpu_env}

[Install]
WantedBy=multi-user.target
OLLAMA_SERVICE

    ai_info "✓ Systemd service created with custom model path"

    # ========================================
    # DOCKER NVIDIA RUNTIME
    # ========================================
    
    ai_info "Configuring Docker NVIDIA runtime..."
    sudo nvidia-ctk runtime configure --runtime=docker 2>&1 | tee -a "$LOG" || warn "Failed to configure NVIDIA runtime"

    # ========================================
    # ENABLE AND START SERVICE
    # ========================================
    
    ai_info "Enabling and starting Ollama service..."
    
    sudo systemctl daemon-reload
    sudo systemctl enable ollama 2>&1 | tee -a "$LOG"
    
    mark_completed "ai_ml"
    ai_info "✓ AI/ML stack installed"
}

setup_streaming() {
    if [ "$(is_completed 'streaming')" = "yes" ]; then
        log "✓ Streaming tools already installed"
        return 0
    fi
    
    log "Installing streaming tools..."
	
    # Load v4l2loopback
    sudo modprobe v4l2loopback 2>/dev/null || true
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
    
    mark_completed "streaming"
    log "✓ Streaming tools installed"
}

setup_system_optimization() {
    if [ "$(is_completed 'system_optimization')" = "yes" ]; then
        log "✓ System optimization already done"
        return 0
    fi
    
    log "Applying system optimizations (Ryzen 7 5800X)..."
	
    # CPU governor (performance for desktop)
    sudo cpupower frequency-set -g performance
    
    # Create systemd service for CPU governor
    sudo tee /etc/systemd/system/cpupower-performance.service > /dev/null <<EOF
[Unit]
Description=Set CPU governor to performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable cpupower-performance.service
    
    # Enable services
    sudo systemctl enable irqbalance
    sudo systemctl enable thermald
    
    # TLP configuration (balanced)
    if [ -f /etc/tlp.conf ]; then
        backup_file "/etc/tlp.conf"
        sudo sed -i 's/^#CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC=performance/' /etc/tlp.conf
        sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/' /etc/tlp.conf
        sudo systemctl enable tlp.service
    fi
    
    # Kernel parameters for Ryzen 7 5800X (AMD Zen 3)
    sudo tee /etc/sysctl.d/99-ryzen-optimization.conf > /dev/null <<EOF
# Ryzen 7 5800X Optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5

# Network performance
net.core.default_qdisc=cake
net.ipv4.tcp_congestion_control=bbr

# File system
fs.inotify.max_user_watches=524288
EOF
    
    sudo sysctl -p /etc/sysctl.d/99-ryzen-optimization.conf
    
    # I/O scheduler (BFQ for responsiveness)
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="bfq"' | \
        sudo tee /etc/udev/rules.d/60-ioschedulers.rules
    echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"' | \
        sudo tee -a /etc/udev/rules.d/60-ioschedulers.rules
    
    mark_completed "system_optimization"
    log "✓ System optimization completed"
}

# ===== I2C FOR RGB =====

setup_i2c_for_rgb() {
    if [ "$(is_completed rgb)" == "yes" ]; then
        log "RGB control already configured"
        return
    fi
    
    log "Setting up RGB control (OpenRGB already installed)..."
    
    # Enable i2c
    sudo modprobe i2c-dev
    sudo modprobe i2c-piix4
    
    # Make i2c modules load on boot
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf > /dev/null
    echo "i2c-piix4" | sudo tee -a /etc/modules-load.d/i2c.conf > /dev/null
    
    # Add user to i2c group
    sudo groupadd -f i2c
    sudo usermod -aG i2c "$USER"
    
    # Create udev rules
    sudo tee /etc/udev/rules.d/99-i2c.rules > /dev/null <<'I2C_RULES'
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
I2C_RULES
    
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    mark_completed "rgb"
    log "✓ RGB control configured"
}

setup_dev() {
    if [ "$(is_completed 'dev')" = "yes" ]; then
        log "✓ Dev tools already installed"
        return 0
    fi
    
    log "Installing Dev tools..."
	
    dotnet new install "Avalonia.Templates"
    
    mark_completed "dev"
    log "✓ Dev tools installed"
}

# ===== GDM CONFIGURATION =====

setup_gdm() {
    if [ "$(is_completed 'gdm')" = "yes" ]; then
        log "✓ GDM already installed"
        return 0
    fi
    
    log "Installing GDM..."
    
    # Bật GDM
    sudo systemctl enable gdm.service
    
    mark_completed "gdm"
    log "✓ GDM installed and enabled"
}

# ===== DIRECTORIES =====

setup_directories() {
    if [ "$(is_completed directories)" == "yes" ]; then
        log "Directories already created"
        return
    fi
    
    log "Creating user directories..."
    
    xdg-user-dirs-update
    
    # Create additional directories
    mkdir -p "$HOME/Projects"
    mkdir -p "$HOME/Screenshots"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share/applications"
    
    mark_completed "directories"
    log "✓ Directories created"
}

# ===== SYSTEM SETTINGS =====

setup_configs() {
    if [ "$(is_completed system_settings)" == "yes" ]; then
        log "System settings already configured"
        return
    fi
    
    log "Configuring system settings..."

    local config_home="$HOME"
    local configs_dir="$HOME/.local/share/Niri/Configs"
    
    if [ ! -d "$configs_dir" ]; then
        error "Configs directory not found at $configs_dir"
    fi
    
    local CONFIGS_BACKUP_DIR=""
    
    symlink_item() {
        local source="$1"
        local target="$2"
        local relative_path="$3"
        
        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ -L "$target" ]; then
                local current_target
                current_target=$(readlink -f "$target" 2>/dev/null || echo "")
                local source_abs
                source_abs=$(realpath "$source" 2>/dev/null || echo "")
                
                if [ "$current_target" = "$source_abs" ]; then
                    log "  ✓ Already linked: $relative_path"
                    return 0
                fi
            fi
            
            if [ -z "$CONFIGS_BACKUP_DIR" ]; then
                CONFIGS_BACKUP_DIR="$BACKUP_DIR/configs-backup-$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$CONFIGS_BACKUP_DIR"
                log "Created backup directory: $CONFIGS_BACKUP_DIR"
            fi
            
            local backup_path="$CONFIGS_BACKUP_DIR/$relative_path"
            mkdir -p "$(dirname "$backup_path")"
            
            if cp -rL "$target" "$backup_path" 2>/dev/null; then
                log "  ✓ Backed up: $relative_path"
            else
                warn "  ⊘ Could not backup: $relative_path"
            fi
            
            rm -rf "$target" 2>/dev/null || warn "  ⚠ Could not remove: $relative_path"
        fi
        
        mkdir -p "$(dirname "$target")"
        
        local source_abs
        source_abs=$(realpath "$source")
        if ln -sf "$source_abs" "$target" 2>/dev/null; then
            log "  ✓ Linked: $relative_path"
        else
            warn "  ✗ Failed to link: $relative_path"
        fi
    }
    
    find "$configs_dir" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' item; do
        local item_name
        item_name=$(basename "$item")
        
        log "Processing: $item_name"
        
        if [ -d "$item" ] && [ ! -L "$item" ]; then
            local target_base="$config_home/$item_name"
            mkdir -p "$target_base"
            
            find "$item" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' subitem; do
                local subitem_name
                subitem_name=$(basename "$subitem")
                local target_path="$target_base/$subitem_name"
                local relative_path="$item_name/$subitem_name"
                
                symlink_item "$subitem" "$target_path" "$relative_path"
            done
        else
            local target_path="$config_home/$item_name"
            symlink_item "$item" "$target_path" "$item_name"
        fi
    done
    
    if [ -n "$CONFIGS_BACKUP_DIR" ] && [ -d "$CONFIGS_BACKUP_DIR" ]; then
        local backup_count=0
        backup_count=$(find "$CONFIGS_BACKUP_DIR" -type f 2>/dev/null | wc -l)
        
        if [ "$backup_count" -gt 0 ]; then
            log ""
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "✓ SAFETY BACKUP CREATED!"
            log "  Location: $CONFIGS_BACKUP_DIR"
            log "  Files backed up: $backup_count"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            warn "⚠ User configuration files have been backed up!"
        else
            rm -rf "$CONFIGS_BACKUP_DIR" 2>/dev/null || true
        fi
    fi
    
    log "Applying special configurations..."
    
    if [ -f "$config_home/.config/fastfetch/fastfetch.sh" ]; then
        chmod +x "$config_home/.config/fastfetch/fastfetch.sh"
    fi

    if [ -L "$config_home/.face" ]; then
        local face_target
        face_target=$(readlink -f "$config_home/.face")
        if [ -f "$face_target" ]; then
            chmod 644 "$face_target"
            log "✓ Set permissions for avatar target: $face_target"
        fi
    elif [ -f "$config_home/.face" ]; then
        chmod 644 "$config_home/.face"
    fi

    log "Configuring GDM avatar..."
    local username="$USER"
    local accountsservice_dir="/var/lib/AccountsService/users"
    local accountsservice_file="$accountsservice_dir/$username"

    if [ ! -d "/var/lib/AccountsService" ]; then
        sudo mkdir -p /var/lib/AccountsService || {
            warn "Failed to create /var/lib/AccountsService"
        }
    fi

    if [ ! -d "$accountsservice_dir" ]; then
        sudo mkdir -p "$accountsservice_dir" || {
            warn "Failed to create AccountsService users directory"
        }
        sudo chmod 755 "$accountsservice_dir"
        log "✓ Created AccountsService directory"
    fi

    local icon_path
    if [ -L "$config_home/.face" ]; then
        icon_path=$(readlink -f "$config_home/.face")
        log "Using symlink target for GDM: $icon_path"
    else
        icon_path="$config_home/.face"
    fi

    if [ -f "$accountsservice_file" ]; then
        if sudo grep -q "^\[User\]" "$accountsservice_file"; then
            if sudo grep -q "^Icon=" "$accountsservice_file"; then
                sudo sed -i "s|^Icon=.*|Icon=$icon_path|" "$accountsservice_file"
            else
                sudo sed -i "/^\[User\]/a Icon=$icon_path" "$accountsservice_file"
            fi
        else
            echo -e "\n[User]\nIcon=$icon_path" | sudo tee -a "$accountsservice_file" > /dev/null
        fi
        log "✓ Updated AccountsService file"
    else
        if sudo tee "$accountsservice_file" > /dev/null <<ACCOUNTSEOF
[User]
Icon=$icon_path
ACCOUNTSEOF
        then
            log "✓ Created AccountsService file"
        else
            warn "Failed to create AccountsService file"
        fi
    fi
    
    sudo chmod 644 "$accountsservice_file" || warn "Failed to set AccountsService file permissions"
    sudo chown root:root "$accountsservice_file" || warn "Failed to set AccountsService file owner"
    
    log "Ensuring GDM can access avatar file..."
    
    local current_dir
    current_dir=$(dirname "$icon_path")
    local dirs_to_fix=()

    while [ "$current_dir" != "/" ] && [ "$current_dir" != "/home" ]; do
        local perms
        perms=$(stat -c "%a" "$current_dir" 2>/dev/null || echo "000")
        local others_exec=${perms:2:1}
        
        if [ "$others_exec" -eq 0 ] || [ "$others_exec" -eq 2 ] || [ "$others_exec" -eq 4 ] || [ "$others_exec" -eq 6 ]; then
            dirs_to_fix+=("$current_dir")
        fi
        
        current_dir=$(dirname "$current_dir")
    done
    
    if [ ${#dirs_to_fix[@]} -gt 0 ]; then
        log "Adding execute permissions for GDM access..."
        for ((i=${#dirs_to_fix[@]}-1; i>=0; i--)); do
            local dir="${dirs_to_fix[$i]}"
            chmod o+x "$dir" 2>/dev/null || warn "Could not add execute permission to: $dir"
            log "  ✓ Fixed: $dir"
        done
    fi

    if sudo -u gdm test -r "$icon_path" 2>/dev/null; then
        log "✓ GDM avatar configured successfully"
    else
        warn "GDM user may not be able to read avatar file"
        warn "You may need to manually fix directory permissions"
    fi
    
    # Configure Fcitx5
    log "Configuring Fcitx5 input method..."
    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/fcitx5.conf" <<'FCITX5_ENV'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
FCITX5_ENV
    
    # Auto-start Fcitx5
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/fcitx5.desktop" <<'FCITX5_DESKTOP'
[Desktop Entry]
Type=Application
Name=Fcitx5
Exec=fcitx5
FCITX5_DESKTOP
    
    # DNS configuration
    local resolved_conf="/etc/systemd/resolved.conf"
    if [ -f "$resolved_conf" ]; then
        log "Updating DNS configuration..."
        backup_file "$resolved_conf"
        
        sudo tee "$resolved_conf" > /dev/null <<'DNS_CONF'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=9.9.9.9#dns.quad9.net 8.8.8.8#dns.google
DNSOverTLS=yes
DNSSEC=allow-downgrade
Cache=yes
DNSStubListener=yes
DNS_CONF
        
        sudo systemctl restart systemd-resolved.service
        log "✓ DNS configured"
    fi
    
    # Enable services
    log "Enabling system services..."
    sudo systemctl enable NetworkManager
    sudo systemctl enable iwd
    sudo systemctl enable bluetooth
    
    systemctl --user enable pipewire
    systemctl --user enable pipewire-pulse
    systemctl --user enable wireplumber
    
    # GTK bookmarks
    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/bookmarks" <<BOOKMARKS
file://$HOME/Downloads
file://$HOME/Documents
file://$HOME/Pictures
file://$HOME/Videos
file://$HOME/Music
file://$HOME/Projects
BOOKMARKS
    
    mark_completed "system_settings"
    log "✓ System settings configured"
}

# ===== MAIN =====

main() {
    show_banner
    init_state
    handle_conflicts
    install_helper
    clone_repo
    setup_system_update
    setup_nvidia_optimization
    setup_base_packages
    setup_docker
    setup_gaming
    setup_multimedia
    setup_ai_ml
    setup_streaming
    setup_system_optimization
    setup_dev
    setup_i2c_for_rgb
    setup_gdm
    setup_directories
    setup_configs
    
    # Done
    echo ""
    echo -e "${GREEN}"
    cat << "COMPLETE"
╔════════════════════════════════════════════════════════════╗
║           INSTALLATION COMPLETED SUCCESSFULLY!             ║
╚════════════════════════════════════════════════════════════╝
COMPLETE
    echo -e "${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo ""
    echo "1. Reboot your system:"
    echo "   ${YELLOW}sudo reboot${NC}"
    echo ""
    echo "2. At GDM login screen:"
    echo "   - Click the gear icon (⚙️) at bottom right"
    echo "   - Select 'Niri'"
    echo "   - Login with your credentials"
    echo ""
    echo "3. DankMaterialShell will auto-start!"
    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "• Default Niri config is at: ${CYAN}~/.config/niri/config.kdl${NC}"
    echo "• DMS provides its own status bar"
    echo "• You can customize keybindings in the config file"
    echo ""
    echo -e "${BLUE}Default Keybindings:${NC}"
    echo "  Super + T           → Open terminal"
    echo "  Super + Return      → Launcher (fuzzel)"
    echo "  Super + Space       → DMS Spotlight (if configured)"
    echo "  Super + A           → DMS Dashboard (if configured)"
    echo "  Super + Q           → Close window"
    echo "  Super + H/J/K/L     → Navigate windows (vim-style)"
    echo "  Super + 1-5         → Switch workspace"
    echo "  Print               → Screenshot"
    echo ""
    echo -e "${BLUE}Niri-Specific Features:${NC}"
    echo "  Super + BracketLeft/Right  → Navigate workspaces"
    echo "  Super + Shift + BracketLeft/Right → Move window to workspace"
    echo "  Super + Comma/Period  → Consume window into column"
    echo "  Super + R  → Switch preset column widths"
    echo "  Super + F  → Maximize column"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "  Niri: https://github.com/YaLTeR/niri"
    echo "  DMS:  https://danklinux.com/docs"
    echo ""
    echo "Logs saved to: ${CYAN}$LOG${NC}"
    echo "Config backup: ${CYAN}$BACKUP_DIR${NC}"
    echo ""
    echo -e "${GREEN}Enjoy your new Niri desktop! 🚀${NC}"
    echo ""
}

main "$@"
