# Scanner Integration Guide

SentinelCore supports importing vulnerability data from major security scanners through a plugin-based architecture.

## Supported Scanners

| Scanner | Format | Status | Notes |
|---------|--------|--------|-------|
| Qualys | XML | ✅ Fully Supported | QID-based reports |
| Nessus | .nessus XML | ✅ Fully Supported | Tenable Nessus Professional/Manager |
| Burp Suite | JSON | ✅ Fully Supported | Issue export format |
| OpenVAS/GVM | XML | ⚙️ In Development | Greenbone reports |
| Nexpose | XML | ⚙️ In Development | Rapid7 InsightVM |

## Import Methods

### Method 1: Web Interface

1. Log in as Admin or Team Leader
2. Navigate to **Scanners** > **Import**
3. Select scanner type
4. Upload scan file
5. Review imported vulnerabilities

### Method 2: API (JSON)

```bash
curl -X POST https://your-domain.com/api/scanners/import \
  -H "Content-Type: application/json" \
  -H "Cookie: auth_token=YOUR_TOKEN" \
  -d '{
    "scanner": "qualys",
    "format": "xml",
    "data": "<?xml version=\"1.0\"?>..."
  }'
```

### Method 3: API (File Upload)

```bash
curl -X POST https://your-domain.com/api/scanners/import/nessus/xml \
  -H "Cookie: auth_token=YOUR_TOKEN" \
  -F "file=@scan_results.nessus"
```

## Scanner-Specific Details

### Qualys

**Supported Formats:** XML (QualysGuard VM reports)

**Export from Qualys:**
1. Go to Reports > Scan Results
2. Select scan
3. Click **Export** > **XML**
4. Download file

**Import to SentinelCore:**
```bash
curl -X POST http://localhost:8080/api/scanners/import/qualys/xml \
  -H "Cookie: auth_token=..." \
  -F "file=@qualys_report.xml"
```

### Nessus

**Supported Formats:** .nessus XML

**Export from Nessus:**
1. Go to **Scans** > Select scan
2. Click **Export** > **.nessus**
3. Download file

**Import to SentinelCore:**
```bash
curl -X POST http://localhost:8080/api/scanners/import/nessus/xml \
  -H "Cookie: auth_token=..." \
  -F "file=@scan_results.nessus"
```

### Burp Suite

**Supported Formats:** JSON (issue export)

**Export from Burp Suite:**
1. Go to **Target** > **Site Map**
2. Right-click target > **Report Issues**
3. Select **JSON** format
4. Export

**Import to SentinelCore:**
```bash
curl -X POST http://localhost:8080/api/scanners/import/burp/json \
  -H "Cookie: auth_token=..." \
  -F "file=@burp_issues.json"
```

### OpenVAS/GVM (In Development)

**Supported Formats:** XML

**Export from OpenVAS:**
1. Go to **Scans** > **Results**
2. Click report
3. Download as **XML**

### Nexpose/InsightVM (In Development)

**Supported Formats:** XML

**Export from Nexpose:**
1. Go to **Reports**
2. Select scan
3. Export as **XML 2.0**

## API Response Format

### Successful Import

```json
{
  "success": true,
  "scanner": "nessus",
  "format": "xml",
  "vulnerabilities_found": 42,
  "vulnerabilities_imported": 42,
  "errors": []
}
```

### Failed Import

```json
{
  "success": false,
  "scanner": "qualys",
  "format": "xml",
  "vulnerabilities_found": 0,
  "vulnerabilities_imported": 0,
  "errors": [
    "Invalid XML format",
    "Missing required fields"
  ]
}
```

## Data Mapping

SentinelCore normalizes data from all scanners into a common format:

| SentinelCore Field | Qualys | Nessus | Burp |
|-------------------|--------|--------|------|
| Title | Title | Plugin Name | Issue Name |
| Description | Description | Description | Issue Detail |
| Severity | Severity | Risk Factor | Severity |
| Host | IP | Host | Host |
| Port | Port | Port | Port |
| CVE | CVE-ID | CVE | - |
| Solution | Solution | Solution | Remediation |

## Automation

### Scheduled Imports

Use cron jobs to automate imports:

```bash
#!/bin/bash
# /etc/cron.daily/import-scans.sh

# Get auth token
TOKEN=$(curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"scanner_user","password":"password"}' \
  | jq -r '.token')

# Import Nessus scans
for file in /scans/nessus/*.nessus; do
  curl -X POST http://localhost:8080/api/scanners/import/nessus/xml \
    -H "Cookie: auth_token=$TOKEN" \
    -F "file=@$file"
  
  # Archive processed file
  mv "$file" /scans/archive/
done
```

## Plugin Development

Want to add support for a new scanner? See [docs/development/PLUGINS.md](development/PLUGINS.md).

### Minimal Plugin Example

```rust
use async_trait::async_trait;
use anyhow::Result;

pub struct MyScanner {
    metadata: ScannerMetadata,
}

#[async_trait]
impl ScannerPlugin for MyScanner {
    fn metadata(&self) -> &ScannerMetadata {
        &self.metadata
    }

    async fn parse(&self, data: &[u8], format: &str) -> Result<Vec<ParsedVulnerability>> {
        // Parse your scanner's format here
        // Return standardized vulnerability data
        Ok(vec![])
    }

    fn validate(&self, data: &[u8], format: &str) -> Result<bool> {
        // Validate file format
        Ok(data.starts_with(b"<?xml"))
    }
}
```

## Troubleshooting

### "Unknown scanner" Error

Ensure you're using the correct scanner name:
- `qualys`
- `nessus`
- `burp`
- `openvas`
- `nexpose`

### "Invalid format" Error

Check that:
1. File format matches scanner type
2. File is not corrupted
3. XML/JSON is well-formed

### Import Hangs

Large scan files (>10MB) may take time to process. Check:
```bash
docker-compose logs -f backend
```

### Missing Vulnerabilities

Some vulnerabilities may be filtered out if:
- Severity is "Info" (configurable)
- Already exists in database (duplicate detection)
- Missing required fields

## Best Practices

1. **Regular Imports** - Schedule daily/weekly imports
2. **Deduplicate** - SentinelCore automatically deduplicates vulnerabilities
3. **Tag Scans** - Use tags to organize imported data
4. **Archive Files** - Keep original scan files for audit purposes
5. **Monitor Errors** - Check import logs regularly

## Support

For scanner integration issues:
- 🐛 [Report Bug](https://github.com/Dognet-Technologies/sentinelcore/issues/new?labels=scanner-integration)
- 📖 [API Documentation](API.md)
- 💬 [Discussions](https://github.com/Dognet-Technologies/sentinelcore/discussions)
