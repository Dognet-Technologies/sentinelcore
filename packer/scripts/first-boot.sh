#!/bin/bash
# SentinelCore First-Boot Configuration Wizard
# Run this script after first boot to customize your installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║         SentinelCore First-Boot Configuration            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (sudo sentinelcore-first-boot)${NC}"
  exit 1
fi

# Check if already configured
if [ -f "/etc/sentinelcore/.configured" ]; then
    echo -e "${YELLOW}This system has already been configured.${NC}"
    read -p "Do you want to reconfigure? (yes/no): " RECONFIG
    if [ "$RECONFIG" != "yes" ]; then
        exit 0
    fi
fi

echo ""
echo "This wizard will help you configure SentinelCore for your environment."
echo ""

# 1. Hostname configuration
echo -e "${GREEN}[1/6] Hostname Configuration${NC}"
CURRENT_HOSTNAME=$(hostname)
echo "Current hostname: $CURRENT_HOSTNAME"
read -p "Enter new hostname (or press Enter to keep current): " NEW_HOSTNAME
if [ -n "$NEW_HOSTNAME" ]; then
    hostnamectl set-hostname "$NEW_HOSTNAME"
    echo "127.0.0.1 $NEW_HOSTNAME" >> /etc/hosts
    echo -e "${GREEN}✓ Hostname updated to: $NEW_HOSTNAME${NC}"
fi

# 2. Network configuration
echo ""
echo -e "${GREEN}[2/6] Network Configuration${NC}"
ip addr show | grep "inet " | grep -v "127.0.0.1"
echo ""
read -p "Configure static IP? (yes/no): " STATIC_IP
if [ "$STATIC_IP" = "yes" ]; then
    read -p "IP address (e.g., 192.168.1.100/24): " IP_ADDR
    read -p "Gateway (e.g., 192.168.1.1): " GATEWAY
    read -p "DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4): " DNS_SERVERS

    # Create netplan configuration
    cat > /etc/netplan/50-sentinelcore.yaml << EOF
network:
  version: 2
  ethernets:
    $(ip -o -4 route show to default | awk '{print $5}'):
      addresses:
        - ${IP_ADDR}
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [${DNS_SERVERS}]
EOF
    netplan apply
    echo -e "${GREEN}✓ Static IP configured${NC}"
fi

# 3. Admin user configuration
echo ""
echo -e "${GREEN}[3/6] Administrator Account${NC}"
echo -e "${YELLOW}WARNING: Default password is 'admin' - you MUST change it!${NC}"
read -p "Enter new admin email (default: admin@sentinelcore.local): " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@sentinelcore.local}

read -s -p "Enter new admin password: " ADMIN_PASSWORD
echo ""
read -s -p "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
echo ""

if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Passwords don't match!${NC}"
    exit 1
fi

# Hash password using argon2
ADMIN_PASSWORD_HASH=$(echo -n "$ADMIN_PASSWORD" | argon2 $(openssl rand -hex 16) -id -t 2 -m 19 -p 1 -l 32 -e)

# Update admin user in database
sudo -u postgres psql -d vulnerability_manager << EOF
UPDATE users
SET email = '${ADMIN_EMAIL}',
    password_hash = '${ADMIN_PASSWORD_HASH}'
WHERE role = 'admin';
\q
EOF

echo -e "${GREEN}✓ Admin account configured${NC}"

# 4. Database password
echo ""
echo -e "${GREEN}[4/6] Database Security${NC}"
read -p "Generate new database password? (yes/no): " GEN_DB_PASS
if [ "$GEN_DB_PASS" = "yes" ]; then
    NEW_DB_PASSWORD=$(openssl rand -base64 32)

    # Update PostgreSQL password
    sudo -u postgres psql << EOF
ALTER USER vlnman WITH PASSWORD '${NEW_DB_PASSWORD}';
\q
EOF

    # Update .env file
    sed -i "s|postgresql://vlnman:[^@]*@|postgresql://vlnman:${NEW_DB_PASSWORD}@|" /opt/sentinelcore/.env

    echo -e "${GREEN}✓ Database password updated${NC}"
fi

# 5. SSL/TLS configuration
echo ""
echo -e "${GREEN}[5/6] SSL/TLS Configuration${NC}"
read -p "Configure SSL with Let's Encrypt? (requires valid domain) (yes/no): " CONFIGURE_SSL
if [ "$CONFIGURE_SSL" = "yes" ]; then
    read -p "Enter your domain name (e.g., sentinelcore.example.com): " DOMAIN_NAME
    read -p "Enter email for Let's Encrypt notifications: " LE_EMAIL

    # Install certbot
    apt-get update
    apt-get install -y certbot python3-certbot-nginx

    # Update nginx config with domain
    sed -i "s|server_name _|server_name ${DOMAIN_NAME}|" /etc/nginx/sites-available/sentinelcore
    systemctl reload nginx

    # Get certificate
    certbot --nginx -d "$DOMAIN_NAME" --email "$LE_EMAIL" --agree-tos --non-interactive

    echo -e "${GREEN}✓ SSL configured for ${DOMAIN_NAME}${NC}"
fi

# 6. Email notifications (optional)
echo ""
echo -e "${GREEN}[6/6] Email Notifications (Optional)${NC}"
read -p "Configure email notifications? (yes/no): " CONFIGURE_EMAIL
if [ "$CONFIGURE_EMAIL" = "yes" ]; then
    read -p "SMTP server (e.g., smtp.gmail.com): " SMTP_SERVER
    read -p "SMTP port (default: 587): " SMTP_PORT
    SMTP_PORT=${SMTP_PORT:-587}
    read -p "SMTP username: " SMTP_USERNAME
    read -s -p "SMTP password: " SMTP_PASSWORD
    echo ""
    read -p "From email address: " SMTP_FROM

    # Update .env file
    cat >> /opt/sentinelcore/.env << EOF

# Email notifications
SMTP_SERVER=${SMTP_SERVER}
SMTP_PORT=${SMTP_PORT}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_FROM=${SMTP_FROM}
EOF

    echo -e "${GREEN}✓ Email notifications configured${NC}"
fi

# Restart services
echo ""
echo -e "${GREEN}Restarting services...${NC}"
systemctl restart sentinelcore
systemctl restart nginx

# Mark as configured
mkdir -p /etc/sentinelcore
touch /etc/sentinelcore/.configured
date > /etc/sentinelcore/.configured

# Show summary
echo ""
echo -e "${GREEN}"
cat << EOF
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║            Configuration Complete! ✓                     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

SentinelCore is now running!

Access the web interface:
$([ -n "$DOMAIN_NAME" ] && echo "  https://${DOMAIN_NAME}" || echo "  http://$(hostname -I | awk '{print $1}')")

Login credentials:
  Email: ${ADMIN_EMAIL}
  Password: (the one you just set)

Services status:
  - SentinelCore: $(systemctl is-active sentinelcore)
  - PostgreSQL: $(systemctl is-active postgresql)
  - Nginx: $(systemctl is-active nginx)

Useful commands:
  - View logs: sudo journalctl -u sentinelcore -f
  - Restart service: sudo systemctl restart sentinelcore
  - Check status: sudo systemctl status sentinelcore

Documentation: /opt/sentinelcore/docs/

EOF
echo -e "${NC}"
