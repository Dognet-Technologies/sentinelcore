# SentinelCore User Guide

Complete guide for using SentinelCore vulnerability management system.

## Table of Contents

- [Getting Started](#getting-started)
- [Dashboard](#dashboard)
- [Vulnerabilities](#vulnerabilities)
- [Teams](#teams)
- [Reports](#reports)
- [Scanner Import](#scanner-import)
- [Settings](#settings)

## Getting Started

### First Login

1. Navigate to SentinelCore URL
2. Log in with credentials
3. **Change default password immediately!**
4. Complete profile setup

### Dashboard Overview

The dashboard provides an at-a-glance view of:

- Total vulnerabilities by severity
- Open vs. closed vulnerabilities
- Recent activity
- Team assignments
- Upcoming deadlines

## Vulnerabilities

### Viewing Vulnerabilities

**All Vulnerabilities (Admin/Team Leader)**
- Navigate to **Vulnerabilities** > **All**
- Use filters to narrow results:
  - Severity (Critical, High, Medium, Low)
  - Status (Open, In Progress, Resolved, Closed)
  - Team assignment
  - Date range

**My Assigned (All Users)**
- Navigate to **Vulnerabilities** > **My Assigned**
- View only vulnerabilities assigned to you
- Update status and add comments

### Vulnerability Details

Click any vulnerability to see:

- **Overview**
  - Title and description
  - CVSS score
  - CVE/CWE identifiers
  - Affected assets

- **Technical Details**
  - Proof of concept
  - Affected version
  - Remediation steps

- **Activity**
  - Status changes
  - Comments
  - Assignments

### Managing Vulnerabilities

**Create New (Admin/Team Leader)**
1. Click **+ New Vulnerability**
2. Fill in details:
   - Title
   - Description
   - Severity
   - Asset
   - CVE (if applicable)
3. Click **Save**

**Update Status**
1. Open vulnerability
2. Change status:
   - **Open** - Newly discovered
   - **In Progress** - Being worked on
   - **Resolved** - Fix implemented
   - **Closed** - Verified and closed
3. Add comment explaining change
4. Click **Update**

**Assign to User**
1. Open vulnerability
2. Click **Assign**
3. Select user
4. Click **Save**

## Teams

### View Teams

Navigate to **Teams** to see all teams and members.

### Create Team (Admin Only)

1. Click **+ New Team**
2. Enter team name
3. Add description
4. Click **Create**

### Manage Members (Admin/Team Leader)

1. Open team
2. Click **Add Member**
3. Select user
4. Choose role:
   - **Leader** - Can manage team
   - **Member** - Regular access
5. Click **Add**

## Reports

### Generate Report

1. Navigate to **Reports** > **Generate**
2. Select report type:
   - **Vulnerability Summary** - Overview of all vulnerabilities
   - **Team Performance** - Team metrics
   - **Executive Summary** - High-level KPIs
   - **Compliance** - Compliance-focused report
3. Configure options:
   - Date range
   - Team filter
   - Asset filter
4. Click **Generate**

### Export Report

1. Open generated report
2. Click **Export**
3. Choose format:
   - PDF
   - Excel (XLSX)
   - CSV
4. Download file

### Schedule Reports (Admin)

1. Navigate to **Reports** > **Schedule**
2. Click **+ New Schedule**
3. Configure:
   - Report type
   - Frequency (daily/weekly/monthly)
   - Recipients
   - Format
4. Click **Save**

Reports will be emailed automatically.

## Scanner Import

### Import Scan Results

**Via Web Interface:**

1. Navigate to **Scanners** > **Import**
2. Select scanner type:
   - Qualys
   - Nessus
   - Burp Suite
   - OpenVAS
   - Nexpose
3. Upload scan file
4. Click **Import**
5. Review imported vulnerabilities

**Via API:**

See [Scanner Integration Guide](SCANNER_INTEGRATION.md) for API details.

### View Import History

1. Navigate to **Scanners** > **History**
2. View past imports:
   - Date/time
   - Scanner type
   - Vulnerabilities imported
   - Status
3. Click any import to see details

## Settings

### Profile Settings

1. Click your name (top right)
2. Select **Profile**
3. Update:
   - Email
   - Phone
   - Notification preferences
4. Click **Save**

### Change Password

1. Profile > **Security**
2. Click **Change Password**
3. Enter current password
4. Enter new password (must meet requirements)
5. Confirm new password
6. Click **Update**

### Two-Factor Authentication (2FA)

1. Profile > **Security**
2. Click **Enable 2FA**
3. Scan QR code with authenticator app (Google Authenticator, Authy, etc.)
4. Enter verification code
5. Save backup codes securely
6. Click **Enable**

**To disable 2FA:**
1. Profile > **Security**
2. Click **Disable 2FA**
3. Enter verification code
4. Confirm

### Notification Settings

1. Profile > **Notifications**
2. Configure preferences:
   - Email notifications
   - In-app notifications
   - Slack/webhook integration
3. Click **Save**

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `g d` | Go to Dashboard |
| `g v` | Go to Vulnerabilities |
| `g t` | Go to Teams |
| `g r` | Go to Reports |
| `n` | Create new vulnerability |
| `/` | Focus search |
| `?` | Show keyboard shortcuts |

## Mobile App

SentinelCore is responsive and works on mobile devices. Use your browser to access the full interface on phones and tablets.

## Tips & Tricks

### Quick Filters

Use the search bar with prefixes:
- `severity:critical` - Critical vulnerabilities only
- `status:open` - Open vulnerabilities
- `team:security` - Security team's vulnerabilities
- `cve:2024-` - Specific CVE year

### Bulk Actions

Select multiple vulnerabilities (checkbox) to:
- Assign to team
- Change status
- Export selection
- Delete (Admin only)

### Custom Views

Save filter combinations as custom views:
1. Apply filters
2. Click **Save View**
3. Name your view
4. Access from sidebar

## Troubleshooting

### Can't Log In

1. Verify username/password
2. Check if account is locked (contact admin)
3. Clear browser cache
4. Try different browser

### Missing Vulnerabilities

1. Check filters (may be filtering out results)
2. Verify team assignment
3. Check date range
4. Contact admin if issue persists

### Import Failures

1. Verify file format matches scanner type
2. Check file isn't corrupted
3. Ensure file size < 50MB
4. Review error message
5. Contact support if needed

## Support

- 📖 [Full Documentation](https://docs.sentinelcore.io)
- 🐛 [Report Bug](https://github.com/Dognet-Technologies/sentinelcore/issues)
- 💬 [Community Forum](https://community.sentinelcore.io)
- 📧 Email: support@dognet.tech

## Training Resources

- [Video Tutorials](https://youtube.com/sentinelcore)
- [Webinars](https://sentinelcore.io/webinars)
- [Blog](https://blog.sentinelcore.io)
