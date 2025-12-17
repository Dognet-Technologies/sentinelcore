# Network Scanning Setup Guide

This document explains how to configure SentinelCore for network discovery and vulnerability scanning.

## Required Tools

SentinelCore uses the following external tools for network scanning:

### Required Tools

1. **arp-scan** - ARP-based network device discovery
2. **nmap** - Port scanning and service detection

### Optional Tools

3. **traceroute** - Network path discovery
4. **ip** - Network interface information

## Installation

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y arp-scan nmap traceroute iproute2
```

### RHEL/CentOS/Fedora

```bash
sudo yum install -y arp-scan nmap traceroute iproute
```

### macOS

```bash
brew install arp-scan nmap
```

## Privilege Requirements

Network scanning requires elevated privileges for certain operations:

- **ARP scanning** requires raw socket access
- **OS detection** (nmap -O flag) requires root privileges

### Option 1: Run as Root (Simple but less secure)

```bash
sudo ./vulnerability-manager
```

### Option 2: Grant Capabilities (Recommended for Production)

Grant specific capabilities without running the entire application as root:

```bash
# Find the tool paths
which arp-scan  # Usually /usr/bin/arp-scan or /usr/sbin/arp-scan
which nmap      # Usually /usr/bin/nmap

# Grant CAP_NET_RAW capability to arp-scan
sudo setcap cap_net_raw+ep /usr/bin/arp-scan
# or
sudo setcap cap_net_raw+ep /usr/sbin/arp-scan

# Grant CAP_NET_RAW capability to nmap
sudo setcap cap_net_raw+ep /usr/bin/nmap
```

**Note**: After setting capabilities, the application can run as a normal user.

### Verify Capabilities

Check if capabilities are set correctly:

```bash
getcap /usr/bin/arp-scan
getcap /usr/bin/nmap
```

You should see output like:
```
/usr/bin/arp-scan = cap_net_raw+ep
/usr/bin/nmap = cap_net_raw+ep
```

## Verification

SentinelCore automatically verifies system requirements on startup. Check the logs:

```
✅ Found: arp-scan
✅ Found: nmap
✅ Running with root privileges
✅ System is ready for network scanning
```

If requirements are not met, you'll see warnings like:

```
⚠️  Not running with root privileges
⚠️  Network scanning requires root privileges or CAP_NET_RAW capability
⚠️  To fix: Run as root or set capabilities: sudo setcap cap_net_raw+ep /usr/bin/arp-scan
```

## Troubleshooting

### "Operation not permitted" errors

**Cause**: Insufficient privileges for raw socket access

**Solution**:
1. Check if tools have CAP_NET_RAW capability: `getcap /usr/bin/arp-scan`
2. If not set, grant capability: `sudo setcap cap_net_raw+ep /usr/bin/arp-scan`
3. Or run application as root: `sudo ./vulnerability-manager`

### "command not found" errors

**Cause**: Required tools not installed

**Solution**: Install missing tools (see Installation section above)

### ARP scan finds no devices

**Possible causes**:
1. Wrong network interface selected
2. Target range incorrect
3. Firewall blocking ARP packets
4. Running in Docker without host network mode

**Solutions**:
- Check network interface: `ip addr` or `ifconfig`
- Verify target range matches your network (e.g., 192.168.1.0/24)
- If using Docker: run with `--network host` flag
- Check firewall rules: `sudo iptables -L`

### Nmap OS detection not working

**Cause**: OS detection requires root privileges even with CAP_NET_RAW

**Solution**: Run application as root when OS detection is needed

## Security Considerations

### Capability-based Approach (Recommended)

✅ **Pros**:
- Application runs as normal user
- Only specific tools have elevated privileges
- Follows principle of least privilege

❌ **Cons**:
- Requires manual setup
- Capabilities are lost when tools are updated

### Running as Root

✅ **Pros**:
- Simple setup
- No capability configuration needed

❌ **Cons**:
- Entire application runs with elevated privileges
- Higher security risk if application is compromised
- Not recommended for production

## Docker Deployment

When deploying in Docker, you have two options:

### Option 1: Host Network Mode

```bash
docker run --network host --cap-add=NET_RAW your-image
```

### Option 2: Grant Capabilities in Dockerfile

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y arp-scan nmap

# Grant capabilities to tools
RUN setcap cap_net_raw+ep /usr/bin/arp-scan && \
    setcap cap_net_raw+ep /usr/bin/nmap

# Run as non-root user
USER appuser
```

Then run without special flags:
```bash
docker run your-image
```

## Testing

To verify your setup is working:

1. Start the application
2. Check startup logs for verification messages
3. Try a network scan via the API:

```bash
curl -X POST http://localhost:8080/api/network/scan \
  -H "Content-Type: application/json" \
  -d '{
    "target_range": "192.168.1.0/24",
    "interface": "eth0",
    "include_os_detection": false
  }'
```

4. Check for devices in the response
5. Review logs for any permission errors

## Additional Resources

- [Linux Capabilities Man Page](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Nmap Documentation](https://nmap.org/book/man.html)
- [ARP-scan Documentation](https://github.com/royhills/arp-scan)

## Support

If you encounter issues:

1. Check application logs for detailed error messages
2. Verify all requirements using the checklist above
3. Report issues with full error logs and system information
