## SentinelCore VM Builder

Automated VM image builder using HashiCorp Packer. Creates ready-to-use SentinelCore virtual machines for VirtualBox and KVM/QEMU.

## Prerequisites

### Install Packer

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/packer

# Linux (Debian/Ubuntu)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Verify installation
packer version
```

### Install Virtualization Software

**For VirtualBox:**
```bash
# Ubuntu/Debian
sudo apt-get install virtualbox

# macOS
brew install --cask virtualbox
```

**For KVM/QEMU:**
```bash
# Ubuntu/Debian
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

## Building the VM

### 1. Initialize Packer

```bash
cd packer
packer init debian13-sentinelcore.pkr.hcl
```

### 2. Validate Configuration

```bash
packer validate debian13-sentinelcore.pkr.hcl
```

### 3. Build VirtualBox Image

```bash
packer build -only=virtualbox-iso.sentinelcore debian13-sentinelcore.pkr.hcl
```

Output: `output-virtualbox/sentinelcore-debian13-virtualbox-1.0.0.ova`

### 4. Build QEMU/KVM Image

```bash
packer build -only=qemu.sentinelcore debian13-sentinelcore.pkr.hcl
```

Output: `output-qemu/sentinelcore-debian13-qemu-1.0.0.qcow2`

### 5. Build All Formats

```bash
packer build debian13-sentinelcore.pkr.hcl
```

## Build Options

### Custom Version

```bash
packer build -var 'version=1.0.1' debian13-sentinelcore.pkr.hcl
```

### Custom Resources

```bash
packer build \
  -var 'memory=16384' \
  -var 'cpus=8' \
  -var 'disk_size=102400' \
  debian13-sentinelcore.pkr.hcl
```

### Parallel Builds

```bash
packer build -parallel-builds=2 debian13-sentinelcore.pkr.hcl
```

## Build Time

Estimated build times (varies by hardware):

- **VirtualBox**: ~45-60 minutes
- **QEMU/KVM**: ~40-55 minutes
- **Both**: ~60-75 minutes

Breakdown:
- Base OS installation: ~10-15 min
- System updates: ~5-10 min
- Dependencies install: ~10-15 min
- Rust compilation: ~15-20 min
- Frontend build: ~5 min
- Cleanup: ~5 min

## Importing the VM

### VirtualBox

```bash
# Import OVA
VBoxManage import sentinelcore-debian13-virtualbox-1.0.0.ova

# Or use GUI: File > Import Appliance
```

### KVM/QEMU

```bash
# Copy image
sudo cp sentinelcore-debian13-qemu-1.0.0.qcow2 /var/lib/libvirt/images/

# Create VM
virt-install \
  --name sentinelcore \
  --memory 8192 \
  --vcpus 4 \
  --disk /var/lib/libvirt/images/sentinelcore-debian13-qemu-1.0.0.qcow2 \
  --import \
  --os-variant debian11 \
  --network bridge=virbr0 \
  --graphics vnc,listen=0.0.0.0
```

### VMware

```bash
# Convert qcow2 to vmdk
qemu-img convert -f qcow2 -O vmdk \
  sentinelcore-debian13-qemu-1.0.0.qcow2 \
  sentinelcore-debian13.vmdk

# Or extract from OVA and import in VMware Workstation/Fusion
```

## First Boot Configuration

### Default Credentials

- **SSH User**: `microcyber`
- **SSH Password**: `microcyber` (change immediately!)
- **Web Admin**: `admin@sentinelcore.local`
- **Web Password**: `admin` (change immediately!)

### Run Configuration Wizard

```bash
ssh microcyber@<vm-ip>
sudo sentinelcore-first-boot
```

The wizard will guide you through:
1. Hostname configuration
2. Network setup (static IP)
3. Admin account creation
4. Database security
5. SSL/TLS setup (optional)
6. Email notifications (optional)

### Manual Configuration

Edit environment file:
```bash
sudo nano /opt/sentinelcore/.env
```

Restart service:
```bash
sudo systemctl restart sentinelcore
```

## VM Specifications

### Default Resources

- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 50 GB (thin provisioned)
- **Network**: NAT (bridged recommended for production)

### Installed Software

- Debian 13 (Trixie)
- PostgreSQL 15
- Nginx
- Node.js 20 LTS
- Rust (latest stable)
- SentinelCore (latest from main branch)

### Ports

- **22**: SSH
- **80**: HTTP (Nginx → SentinelCore)
- **443**: HTTPS (if configured)
- **8080**: SentinelCore API (internal)

### Services

```bash
# Check services
sudo systemctl status sentinelcore
sudo systemctl status postgresql
sudo systemctl status nginx

# View logs
sudo journalctl -u sentinelcore -f

# Application logs
sudo tail -f /var/log/sentinelcore/app.log
```

## Troubleshooting

### Build Fails

**Check Packer logs:**
```bash
PACKER_LOG=1 packer build debian13-sentinelcore.pkr.hcl
```

**Common issues:**
- ISO download timeout: Increase `boot_wait` or use local ISO
- SSH timeout: Check network configuration
- Out of disk space: Increase host disk space
- Virtualization disabled: Enable VT-x/AMD-V in BIOS

### VM Won't Boot

1. Check virtualization is enabled
2. Verify adequate resources (8GB RAM, 4 CPUs)
3. Check boot order in VM settings
4. View VM console for errors

### Service Won't Start

```bash
# Check service status
sudo systemctl status sentinelcore

# Check logs
sudo journalctl -u sentinelcore -n 50

# Verify database connection
sudo -u sentinelcore psql -d vulnerability_manager -c "SELECT version();"

# Check configuration
sudo cat /opt/sentinelcore/.env
```

## Customization

### Modify Provisioning

Edit `scripts/provision.sh` to customize:
- Installed packages
- Configuration defaults
- Database setup
- Security settings

### Preseed Configuration

Edit `http/preseed.cfg` to change:
- Partitioning scheme
- Package selection
- Locale settings
- User accounts

### Build Variables

Edit variables in `debian13-sentinelcore.pkr.hcl`:
```hcl
variable "version" {
  default = "1.0.0"
}

variable "memory" {
  default = 8192
}

variable "cpus" {
  default = 4
}
```

## Distribution

### Compress Images

```bash
# Compress OVA
gzip sentinelcore-debian13-virtualbox-1.0.0.ova

# Compress QCOW2
gzip sentinelcore-debian13-qemu-1.0.0.qcow2
```

### Generate Checksums

```bash
sha256sum sentinelcore-*.ova > checksums.txt
sha256sum sentinelcore-*.qcow2 >> checksums.txt
```

### Upload to Release

```bash
# Create GitHub release and upload artifacts
gh release create v1.0.0 \
  sentinelcore-debian13-virtualbox-1.0.0.ova.gz \
  sentinelcore-debian13-qemu-1.0.0.qcow2.gz \
  checksums.txt \
  --title "SentinelCore VM v1.0.0" \
  --notes "Ready-to-use VM images for VirtualBox and KVM"
```

## Security Notes

- Default passwords MUST be changed on first boot
- Run first-boot wizard to generate secure secrets
- Configure firewall for production use
- Enable SSL/TLS for production deployments
- Keep system updated: `sudo apt-get update && sudo apt-get upgrade`

## Updates

To update SentinelCore in existing VM:

```bash
cd /opt/sentinelcore
git pull
sudo scripts/deployment/regenerate-sqlx-cache.sh
sudo scripts/deployment/build-deb.sh
sudo dpkg -i /tmp/sentinelcore_1.0.0_amd64.deb
sudo systemctl restart sentinelcore
```

## Support

- Documentation: `/opt/sentinelcore/docs/`
- Issues: https://github.com/Dognet-Technologies/sentinelcore/issues
- Logs: `/var/log/sentinelcore/`

## License

See LICENSE file in repository root.
