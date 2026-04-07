# SentinelCore VM - Quick Start Guide

Ready-to-use virtual machine with SentinelCore pre-installed.

## Download

Get the latest VM image from GitHub releases:
- **VirtualBox (.ova)**: For VirtualBox, VMware Workstation/Fusion
- **KVM/QEMU (.qcow2)**: For KVM, Proxmox, OpenStack

## Import VM

### VirtualBox

1. Download `sentinelcore-debian13-virtualbox-X.X.X.ova.gz`
2. Extract: `gunzip sentinelcore-debian13-virtualbox-X.X.X.ova.gz`
3. Import:
   - Open VirtualBox
   - File → Import Appliance
   - Select the .ova file
   - Review settings (8GB RAM, 4 CPUs recommended)
   - Click Import

### VMware Workstation/Fusion

1. Download `sentinelcore-debian13-virtualbox-X.X.X.ova.gz`
2. Extract: `gunzip sentinelcore-debian13-virtualbox-X.X.X.ova.gz`
3. Import:
   - File → Open
   - Select the .ova file
   - Accept license agreements
   - Wait for import to complete

### KVM/QEMU (virt-manager)

1. Download `sentinelcore-debian13-qemu-X.X.X.qcow2.gz`
2. Extract: `gunzip sentinelcore-debian13-qemu-X.X.X.qcow2.gz`
3. Copy to libvirt images:
   ```bash
   sudo cp sentinelcore-debian13-qemu-X.X.X.qcow2 /var/lib/libvirt/images/sentinelcore.qcow2
   ```
4. Create VM in virt-manager:
   - New VM → Import existing disk image
   - Browse → Select sentinelcore.qcow2
   - OS: Debian 11 or later
   - RAM: 8192 MB, CPUs: 4
   - Finish

### Proxmox VE

1. Upload qcow2 to Proxmox:
   ```bash
   scp sentinelcore-debian13-qemu-X.X.X.qcow2 root@proxmox:/var/lib/vz/images/
   ```

2. Create VM:
   ```bash
   # On Proxmox host
   qm create 100 --name sentinelcore --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0
   qm importdisk 100 /var/lib/vz/images/sentinelcore-debian13-qemu-X.X.X.qcow2 local-lvm
   qm set 100 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-100-disk-0
   qm set 100 --boot c --bootdisk scsi0
   qm set 100 --ide2 local-lvm:cloudinit
   qm set 100 --serial0 socket --vga serial0
   ```

## First Boot

### 1. Start VM and Login

**Default SSH credentials:**
- Username: `microcyber`
- Password: `microcyber`

```bash
ssh microcyber@<vm-ip>
```

### 2. Run Configuration Wizard

**IMPORTANT**: Change default passwords immediately!

```bash
sudo sentinelcore-first-boot
```

The wizard will configure:
- ✅ Hostname
- ✅ Network (static IP optional)
- ✅ Admin credentials (CHANGE PASSWORD!)
- ✅ Database security
- ✅ SSL/TLS (optional)
- ✅ Email notifications (optional)

### 3. Access Web Interface

After configuration:

```
http://<vm-ip>
```

**Login:**
- Email: (the one you configured)
- Password: (the one you set)

## Network Configuration

### Recommended Setup

1. **Change network adapter** from NAT to Bridged:
   - VirtualBox: Settings → Network → Adapter 1 → Bridged Adapter
   - VMware: VM Settings → Network Adapter → Bridged
   - KVM: virt-manager → NIC → Source: Bridge (br0 or virbr0)

2. **Configure static IP** via first-boot wizard or manually:
   ```bash
   sudo nano /etc/netplan/50-sentinelcore.yaml
   sudo netplan apply
   ```

### Port Forwarding (NAT mode)

If using NAT, forward these ports:

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH | 2222 | 22 |
| HTTP | 8080 | 80 |
| HTTPS | 8443 | 443 |

**VirtualBox:**
Settings → Network → Advanced → Port Forwarding

## Security Checklist

- [ ] Change default SSH password (`passwd`)
- [ ] Change admin web password (first-boot wizard)
- [ ] Configure firewall (already enabled with UFW)
- [ ] Set up SSL/TLS for production
- [ ] Update system: `sudo apt-get update && sudo apt-get upgrade`
- [ ] Review `/opt/sentinelcore/.env` configuration
- [ ] Enable automatic security updates

## Common Tasks

### Check Service Status

```bash
sudo systemctl status sentinelcore
sudo systemctl status postgresql
sudo systemctl status nginx
```

### View Logs

```bash
# Real-time logs
sudo journalctl -u sentinelcore -f

# Application logs
sudo tail -f /var/log/sentinelcore/app.log

# Error logs
sudo tail -f /var/log/sentinelcore/error.log
```

### Restart Services

```bash
sudo systemctl restart sentinelcore
sudo systemctl restart nginx
```

### Update SentinelCore

```bash
cd /opt/sentinelcore
git pull
sudo scripts/deployment/regenerate-sqlx-cache.sh
sudo scripts/deployment/build-deb.sh
sudo dpkg -i /tmp/sentinelcore_1.0.0_amd64.deb
sudo systemctl restart sentinelcore
```

### Backup Database

```bash
sudo -u postgres pg_dump vulnerability_manager > backup-$(date +%Y%m%d).sql
```

### Restore Database

```bash
sudo -u postgres psql vulnerability_manager < backup-20241208.sql
```

## Troubleshooting

### Can't Access Web Interface

1. Check service is running:
   ```bash
   sudo systemctl status sentinelcore
   ```

2. Check firewall:
   ```bash
   sudo ufw status
   ```

3. Verify network connectivity:
   ```bash
   curl http://localhost
   ```

### Database Connection Errors

1. Check PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```

2. Verify credentials in `/opt/sentinelcore/.env`

3. Test connection:
   ```bash
   sudo -u postgres psql -d vulnerability_manager -c "SELECT version();"
   ```

### SSH Connection Refused

1. Verify VM is running and booted
2. Check IP address: `ip addr show`
3. Test from VM console: `sudo systemctl status ssh`
4. Check firewall: `sudo ufw allow 22/tcp`

### Out of Disk Space

1. Check disk usage:
   ```bash
   df -h
   sudo du -sh /var/* | sort -h
   ```

2. Clean up logs:
   ```bash
   sudo journalctl --vacuum-time=7d
   ```

3. Resize disk (requires VM shutdown):
   - VirtualBox: `VBoxManage modifymedium disk <uuid> --resize 102400`
   - KVM: `qemu-img resize sentinelcore.qcow2 +50G`
   - Then expand filesystem inside VM

## VM Specifications

### Default Resources

- **OS**: Debian 13 (Trixie)
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 50 GB (expandable)
- **Network**: NAT/Bridged

### Installed Software

- PostgreSQL 15
- Nginx
- Node.js 20 LTS
- Rust (latest stable)
- SentinelCore v1.0.0+

### Default Accounts

| Service | Username | Default Password |
|---------|----------|------------------|
| SSH | microcyber | microcyber |
| Web Admin | admin@sentinelcore.local | admin |
| PostgreSQL | vlnman | (random, see .env) |

**⚠️  CHANGE ALL DEFAULT PASSWORDS IMMEDIATELY!**

## Performance Tuning

### Increase Resources

For better performance with large datasets:

- **RAM**: 16 GB or more
- **CPU**: 8 cores or more
- **Disk**: SSD storage recommended

### PostgreSQL Tuning

Edit `/etc/postgresql/15/main/postgresql.conf`:

```conf
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 20MB
maintenance_work_mem = 512MB
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

## Advanced Configuration

### Enable HTTPS with Let's Encrypt

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### Configure Email Notifications

Edit `/opt/sentinelcore/.env`:

```bash
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@sentinelcore.local
```

Restart service:
```bash
sudo systemctl restart sentinelcore
```

### Custom PostgreSQL Configuration

```bash
sudo -u postgres psql
\c vulnerability_manager
-- Your SQL commands here
\q
```

## Support

- **Documentation**: `/opt/sentinelcore/docs/`
- **GitHub**: https://github.com/Dognet-Technologies/sentinelcore
- **Issues**: https://github.com/Dognet-Technologies/sentinelcore/issues

## Uninstall/Remove

### Remove SentinelCore Service

```bash
sudo systemctl stop sentinelcore
sudo systemctl disable sentinelcore
sudo rm /etc/systemd/system/sentinelcore.service
sudo systemctl daemon-reload
```

### Delete VM

- **VirtualBox**: Right-click VM → Remove → Delete all files
- **VMware**: Right-click VM → Delete from Disk
- **KVM**: `virsh destroy sentinelcore && virsh undefine sentinelcore --remove-all-storage`

## License

See LICENSE file in /opt/sentinelcore/
