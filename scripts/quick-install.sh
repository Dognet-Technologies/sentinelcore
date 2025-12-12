#!/bin/bash
# quick-install.sh - SentinelCore One-Liner Installer
# Usage: curl -sSL https://raw.githubusercontent.com/Dognet-Technologies/sentinelcore/main/scripts/quick-install.sh | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << "EOF"
   ____             _   _            _  ____
  / ___|  ___ _ __ | |_(_)_ __   ___| |/ ___|___  _ __ ___
  \___ \ / _ \ '_ \| __| | '_ \ / _ \ | |   / _ \| '__/ _ \
   ___) |  __/ | | | |_| | | | |  __/ | |__| (_) | | |  __/
  |____/ \___|_| |_|\__|_|_| |_|\___|_|\____\___/|_|  \___|

  SentinelCore Quick Installer v1.0
  MicroCyber Security Suite
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Please run as root (use sudo)${NC}"
   exit 1
fi

# Get actual user (not root if using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
if [ "$ACTUAL_USER" = "root" ]; then
    echo -e "${YELLOW}Warning: Running as root user. Creating 'microcyber' user...${NC}"
    if ! id "microcyber" &>/dev/null; then
        useradd -m -s /bin/bash -G sudo microcyber
        echo "microcyber:microcyber" | chpasswd
        echo -e "${GREEN}✓ Created user 'microcyber' with password 'microcyber'${NC}"
        echo -e "${YELLOW}⚠ CHANGE PASSWORD AFTER INSTALLATION!${NC}"
    fi
    ACTUAL_USER="microcyber"
fi

echo -e "${GREEN}Installing as user: $ACTUAL_USER${NC}"
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS. Only Debian/Ubuntu supported.${NC}"
    exit 1
fi

echo -e "${BLUE}Detected OS: $OS $VERSION${NC}"

# Check supported OS
case "$OS" in
    debian|ubuntu)
        if [ "$OS" = "debian" ] && [ "${VERSION%%.*}" -lt 12 ]; then
            echo -e "${YELLOW}Warning: Debian < 12 detected. Recommended: Debian 12+${NC}"
        fi
        if [ "$OS" = "ubuntu" ] && [ "${VERSION%%.*}" -lt 22 ]; then
            echo -e "${YELLOW}Warning: Ubuntu < 22.04 detected. Recommended: Ubuntu 22.04+${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS. Only Debian/Ubuntu supported.${NC}"
        exit 1
        ;;
esac

# Installation directory
INSTALL_DIR="/opt/sentinelcore"

echo ""
echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠ SentinelCore already installed at $INSTALL_DIR${NC}"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled.${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Backing up existing installation...${NC}"
    mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Check internet connectivity
if ! ping -c 1 google.com &>/dev/null; then
    echo -e "${RED}No internet connection. Installation requires internet access.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"

echo ""
echo -e "${YELLOW}[2/8] Installing system packages...${NC}"

# Update package lists
apt-get update -qq

# Install base packages
apt-get install -y -qq \
    git curl wget build-essential \
    libpq-dev libssl-dev pkg-config \
    > /dev/null 2>&1

echo -e "${GREEN}✓ System packages installed${NC}"

echo ""
echo -e "${YELLOW}[3/8] Cloning SentinelCore repository...${NC}"

# Clone repository
mkdir -p /opt
chown $ACTUAL_USER:$ACTUAL_USER /opt
cd /opt

sudo -u $ACTUAL_USER git clone --quiet https://github.com/Dognet-Technologies/sentinelcore.git sentinelcore 2>/dev/null || {
    echo -e "${RED}Failed to clone repository. Check GitHub connectivity.${NC}"
    exit 1
}

echo -e "${GREEN}✓ Repository cloned${NC}"

echo ""
echo -e "${YELLOW}[4/8] Running full installation script...${NC}"
echo -e "${BLUE}This will take 15-20 minutes. Please be patient...${NC}"

# Make script executable and run
cd "$INSTALL_DIR"
chmod +x scripts/deployment/vm-setup-debian13.sh

# Run installation script
if ./scripts/deployment/vm-setup-debian13.sh; then
    echo -e "${GREEN}✓ SentinelCore installation completed successfully!${NC}"
else
    echo -e "${RED}✗ Installation failed. Check logs above for errors.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Access SentinelCore:${NC}"
echo -e "  Web UI: ${GREEN}http://$(hostname -I | awk '{print $1}')${NC}"
echo ""
echo -e "${BLUE}Default credentials:${NC}"
echo -e "  Email: ${YELLOW}admin@sentinelcore.local${NC}"
echo -e "  Password: ${YELLOW}admin${NC}"
echo ""
echo -e "${RED}⚠ IMPORTANT: Change default password immediately!${NC}"
echo ""
echo -e "${BLUE}Service commands:${NC}"
echo -e "  Status:  ${GREEN}sudo systemctl status sentinelcore${NC}"
echo -e "  Restart: ${GREEN}sudo systemctl restart sentinelcore${NC}"
echo -e "  Logs:    ${GREEN}sudo journalctl -u sentinelcore -f${NC}"
echo ""
echo -e "${BLUE}Update SentinelCore:${NC}"
echo -e "  ${GREEN}sudo $INSTALL_DIR/scripts/deployment/update_tools.sh${NC}"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "  ${GREEN}$INSTALL_DIR/docs/${NC}"
echo ""
echo -e "${GREEN}Happy vulnerability hunting! 🎯${NC}"
