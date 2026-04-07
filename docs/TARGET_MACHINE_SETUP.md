# SentinelCore - Configurazione Macchine Target

Guida per preparare macchine Linux/Windows per la scansione e scoperta da parte di SentinelCore.

**Nota:** SentinelCore non richiede installazione di agent sulle macchine target. Utilizza scansioni di rete (nmap) e importazione dati da scanner esistenti (Nessus, OpenVAS, Qualys).

---

## Indice

1. [Panoramica Architettura](#1-panoramica-architettura)
2. [Preparazione Macchine Linux Target](#2-preparazione-macchine-linux-target)
3. [Preparazione Macchine Windows Target](#3-preparazione-macchine-windows-target)
4. [Configurazione Network Discovery](#4-configurazione-network-discovery)
5. [Setup Scanner Esterni](#5-setup-scanner-esterni)
6. [Credenziali per Scansioni Autenticate](#6-credenziali-per-scansioni-autenticate)
7. [Firewall e Porte Necessarie](#7-firewall-e-porte-necessarie)
8. [Best Practices Sicurezza](#8-best-practices-sicurezza)

---

## 1. Panoramica Architettura

### Come Funziona SentinelCore

```
┌─────────────────┐
│ SentinelCore    │
│ Server          │
│                 │
│ - Network Scan  │──┐
│ - Import Data   │  │
└─────────────────┘  │
                     │
                     ├──────> Nmap Discovery Scan
                     │        (ping, port scan)
                     │
                     ├──────> Scanner Esterni
                     │        (Nessus/OpenVAS/Qualys)
                     │
                     └──────> Import Risultati
                              (XML/JSON)

┌──────────────────────────────────────┐
│ Network Target Machines              │
│                                      │
│ ┌─────────┐  ┌─────────┐  ┌────────┐│
│ │ Linux   │  │ Windows │  │ Router ││
│ │ Server  │  │ Desktop │  │ Switch ││
│ └─────────┘  └─────────┘  └────────┘│
└──────────────────────────────────────┘
```

### Metodi di Scoperta

1. **Network Discovery (nmap)**
   - Scan ping per scoprire host attivi
   - Port scan per identificare servizi
   - OS detection
   - Service version detection

2. **Scanner Integration**
   - Nessus Professional/Essentials
   - OpenVAS / Greenbone
   - Qualys VMDR
   - Tenable.io

3. **Manual Import**
   - Upload file XML/JSON da scanner
   - Import CVE da database pubblici

---

## 2. Preparazione Macchine Linux Target

### 2.1 Requisiti Base

Le macchine Linux target **NON richiedono alcun software SentinelCore installato**.

Devono solo essere:
- **Raggiungibili via rete** dal server SentinelCore
- **Rispondere a ping ICMP** (opzionale ma consigliato)
- **Avere porte aperte** per i servizi che si vogliono monitorare

### 2.2 Configurazione Firewall Linux (iptables/ufw)

#### Per permettere scansione base (discovery):

```bash
# Permetti ICMP ping (consigliato per network discovery)
sudo ufw allow from <SENTINELCORE_SERVER_IP> to any proto icmp

# Esempio: server SentinelCore ha IP 192.168.1.100
sudo ufw allow from 192.168.1.100 to any proto icmp
```

#### Per permettere port scan dei servizi:

```bash
# Se vuoi che SentinelCore veda servizi SSH, HTTP, ecc.
# NON serve fare nulla - le porte già aperte saranno scoperte

# Esempio: se SSH è già esposto
sudo ufw status | grep 22  # Verifica che 22/tcp sia allowed
```

### 2.3 Configurazione per Scansioni Autenticate (Opzionale)

Le scansioni autenticate permettono a scanner come Nessus/OpenVAS di:
- Identificare pacchetti installati
- Rilevare vulnerabilità locali
- Verificare patch level

#### Setup Utente SSH per Scanner

```bash
# 1. Crea utente dedicato per scansioni
sudo useradd -m -s /bin/bash scanuser
sudo passwd scanuser  # Imposta password sicura

# 2. Configura sudo NOPASSWD per comandi scanner (SOLO se necessario)
sudo visudo
# Aggiungi:
scanuser ALL=(ALL) NOPASSWD: /usr/bin/dpkg, /usr/bin/rpm, /bin/cat /etc/*-release

# 3. Setup SSH key-based authentication (più sicuro)
# Sul server SentinelCore o scanner:
ssh-keygen -t ed25519 -f ~/.ssh/scanuser_key -C "Scanner credentials"

# Copia chiave pubblica sulla macchina target:
ssh-copy-id -i ~/.ssh/scanuser_key.pub scanuser@<target_ip>

# 4. Test connessione
ssh -i ~/.ssh/scanuser_key scanuser@<target_ip> "uname -a"
```

#### Hardening SSH per Scanner

```bash
sudo nano /etc/ssh/sshd_config
```

Aggiungi restrizioni per utente scanner:
```conf
# Permetti scanuser solo da IP specifici
Match User scanuser
    PasswordAuthentication no
    PubkeyAuthentication yes
    AllowTcpForwarding no
    X11Forwarding no
    AllowAgentForwarding no
    PermitTTY yes
    # Limita comandi
    ForceCommand /usr/local/bin/scan-restricted-shell.sh
```

```bash
sudo systemctl reload sshd
```

### 2.4 Servizi Comuni da Esporre per Scansione

| Servizio | Porta | Protocollo | Scopo Scanner |
|----------|-------|------------|---------------|
| SSH      | 22    | TCP        | Autenticazione, version detection |
| HTTP     | 80    | TCP        | Web vulnerability scan |
| HTTPS    | 443   | TCP        | Web vulnerability scan |
| MySQL    | 3306  | TCP        | Database vulnerability scan |
| PostgreSQL | 5432 | TCP      | Database vulnerability scan |

**IMPORTANTE:** Esponi solo porte necessarie. Usa regole firewall per limitare accesso solo da IP scanner.

---

## 3. Preparazione Macchine Windows Target

### 3.1 Requisiti Base

Similmente a Linux, macchine Windows **NON richiedono agent SentinelCore**.

### 3.2 Configurazione Windows Firewall

#### Permetti ICMP Ping

```powershell
# Esegui come Administrator in PowerShell
New-NetFirewallRule -DisplayName "Allow ICMPv4 from Scanner" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -RemoteAddress <SENTINELCORE_SERVER_IP> `
    -Action Allow

# Esempio con IP specifico
New-NetFirewallRule -DisplayName "Allow ICMPv4 from Scanner" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -RemoteAddress 192.168.1.100 `
    -Action Allow
```

#### Permetti WMI per Scansioni Autenticate (Nessus/OpenVAS)

```powershell
# Abilita WMI firewall rules
Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"

# Oppure specifico per scanner IP
New-NetFirewallRule -DisplayName "WMI-In from Scanner" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135,139,445 `
    -RemoteAddress 192.168.1.100 `
    -Action Allow
```

### 3.3 Setup Credenziali per Scansioni Autenticate Windows

#### Metodo 1: Utente Locale (Small Networks)

```powershell
# 1. Crea utente locale per scanner
net user scanuser P@ssw0rd123! /add
net localgroup Administrators scanuser /add

# 2. Abilita accesso amministrativo remoto
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

# 3. Abilita Remote Registry
sc config RemoteRegistry start= auto
net start RemoteRegistry
```

#### Metodo 2: Domain Account (Enterprise)

```powershell
# Usa account Active Directory con privilegi Domain Admin o Local Admin su target machines
# Configura nel scanner:
# Username: DOMAIN\scanuser
# Password: <password>
```

### 3.4 Configurazione WinRM per Scanner Avanzati

```powershell
# Abilita WinRM
winrm quickconfig -q

# Configura TrustedHosts (solo per scanner IP)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.100" -Force

# Verifica configurazione
winrm get winrm/config
```

### 3.5 Porte Windows Comuni per Scansione

| Servizio | Porta | Protocollo | Scopo |
|----------|-------|------------|-------|
| SMB      | 445   | TCP        | File sharing, vulnerability scan |
| RPC      | 135   | TCP        | WMI, remote management |
| NetBIOS  | 139   | TCP        | SMB over NetBIOS |
| WinRM    | 5985  | TCP        | HTTP remote management |
| WinRM SSL| 5986  | TCP        | HTTPS remote management |
| RDP      | 3389  | TCP        | Remote Desktop (version detection) |

---

## 4. Configurazione Network Discovery

### 4.1 Definizione Range di Rete in SentinelCore

Una volta installato SentinelCore, configura i range di rete da scansionare:

1. **Login** a SentinelCore: `https://sentinelcore.yourdomain.com`

2. **Vai a:** Network Discovery → Network Ranges

3. **Aggiungi Range:**
   ```
   Nome: LAN Interna Ufficio
   CIDR: 192.168.1.0/24
   Descrizione: Rete ufficio principale
   Tipo: Local Network
   ```

4. **Trigger Scansione:**
   - **Discovery Scan:** Ping sweep + basic port scan
   - **Deep Scan:** Full port scan + version detection + OS detection

### 4.2 Tipi di Scansione Nmap

#### Discovery Scan (Veloce)
```bash
# Eseguito automaticamente da SentinelCore
nmap -sn -PE -PP -PS21,22,23,25,80,443 192.168.1.0/24

# Risultato: lista host attivi + MAC address
```

#### Deep Scan (Completo)
```bash
# Eseguito su host specifici
nmap -sS -sV -O -A -T4 192.168.1.10

# Risultato:
# - Porte aperte
# - Versioni servizi
# - OS detection
# - Script NSE
```

### 4.3 Scheduling Scansioni Automatiche

In SentinelCore UI:
```
Network Ranges → Select Range → Schedule
- Frequency: Daily / Weekly / Monthly
- Time: 02:00 AM (off-hours)
- Type: Discovery + Deep Scan
```

---

## 5. Setup Scanner Esterni

SentinelCore si integra con scanner professionali per vulnerability assessment approfondito.

### 5.1 Nessus Professional

#### Installazione Nessus (su server separato o stesso server SentinelCore)

```bash
# Download Nessus da tenable.com
wget https://www.tenable.com/downloads/api/v1/public/pages/nessus/downloads/.../Nessus-10.x.x-debian10_amd64.deb

# Installa
sudo dpkg -i Nessus-*.deb

# Avvia Nessus
sudo systemctl start nessusd
sudo systemctl enable nessusd

# Accedi: https://localhost:8834
```

#### Configurazione Scan Policy per SentinelCore

1. **Policies → New Policy → Advanced Scan**
2. **Settings:**
   ```
   Name: SentinelCore Full Scan
   Description: Comprehensive vulnerability scan for SentinelCore import
   ```
3. **Credentials:**
   - Add SSH credentials (Linux)
   - Add Windows credentials (WMI/SMB)
4. **Save & Scan**

#### Export per SentinelCore

```bash
# Dopo scan completato:
# Nessus UI → Scans → Select Scan → Export → Nessus (XML)
# Salva file: sentinelcore_scan_2025-01-25.nessus

# Upload in SentinelCore:
# UI → Scanner Integration → Import Nessus → Upload File
```

### 5.2 OpenVAS (Greenbone)

#### Installazione OpenVAS

```bash
# Install OpenVAS su Debian
sudo apt install -y openvas

# Setup iniziale
sudo gvm-setup

# Avvia servizi
sudo gvm-start

# Ottieni password admin
sudo gvm-feed-update
```

#### Scan Configuration

```bash
# Crea target
gvm-cli socket --socketpath /var/run/gvmd.sock --xml \
  "<create_target><name>SentinelCore Targets</name><hosts>192.168.1.0/24</hosts></create_target>"

# Crea task di scan
gvm-cli socket --socketpath /var/run/gvmd.sock --xml \
  "<create_task><name>Weekly Full Scan</name><target id='target-uuid'/></create_task>"

# Export risultati
# WebUI → Scans → Export → XML
```

### 5.3 Qualys VMDR (Cloud-Based)

Qualys è cloud-based, richiede:

1. **Account Qualys** su qualysguard.com
2. **Deploy Qualys Scanner Appliance** (virtual o cloud connector)
3. **Configure Scan:**
   - Option Profiles → Authentication Records
   - Asset Groups → Add Target IPs
   - Scans → New Scan
4. **Export:**
   - Reports → Scan Results → Export XML
   - Import in SentinelCore

---

## 6. Credenziali per Scansioni Autenticate

### 6.1 Gestione Sicura Credenziali

**IMPORTANTE:** Credenziali scanner hanno privilegi elevati. Proteggile adeguatamente.

#### Best Practices

1. **Usa Vault Manager:**
   - HashiCorp Vault
   - CyberArk
   - AWS Secrets Manager

2. **Rotazione Password:**
   ```bash
   # Cambia password scanner ogni 90 giorni
   # Usa script automatizzato
   ```

3. **Least Privilege:**
   - Linux: sudo solo per comandi necessari
   - Windows: Local Admin (non Domain Admin se possibile)

4. **Audit Logging:**
   ```bash
   # Monitora accessi scanner user
   sudo ausearch -ua scanuser
   ```

### 6.2 Template Credenziali per Scanner

#### Linux SSH Credentials
```yaml
Username: scanuser
Authentication: SSH Key (ed25519)
Private Key: /path/to/scanuser_key
Privilege Escalation: sudo
Sudo Password: (none - NOPASSWD configured)
```

#### Windows WMI Credentials
```yaml
Username: DOMAIN\scanuser
Password: <secure-password>
Authentication Method: WMI
Admin Privileges: Local Administrator
```

---

## 7. Firewall e Porte Necessarie

### 7.1 Tabella Completa Porte

#### Dal Server SentinelCore verso Target Machines

| Fonte | Destinazione | Porta | Protocollo | Scopo |
|-------|--------------|-------|------------|-------|
| SentinelCore | Target Linux | 22 | TCP | SSH credentialed scan |
| SentinelCore | Target Linux | ICMP | - | Ping discovery |
| SentinelCore | Target Linux | 1-65535 | TCP | Port scanning |
| SentinelCore | Target Windows | 135 | TCP | RPC/WMI |
| SentinelCore | Target Windows | 139 | TCP | NetBIOS |
| SentinelCore | Target Windows | 445 | TCP | SMB |
| SentinelCore | Target Windows | 5985/5986 | TCP | WinRM |
| SentinelCore | Target Windows | ICMP | - | Ping discovery |

#### Da Scanner Esterni (Nessus/OpenVAS) verso Targets

Stesse porte sopra + eventuali porte custom per servizi specifici (database, web apps, ecc.)

### 7.2 Esempio Configurazione UFW (Linux Target)

```bash
# Allow from SentinelCore server
sudo ufw allow from 192.168.1.100 to any port 22 proto tcp comment 'Scanner SSH'
sudo ufw allow from 192.168.1.100 proto icmp comment 'Scanner Ping'

# Allow from Nessus scanner
sudo ufw allow from 192.168.1.101 to any port 22 proto tcp comment 'Nessus SSH'
sudo ufw allow from 192.168.1.101 proto icmp comment 'Nessus Ping'

# Block everything else
sudo ufw default deny incoming
sudo ufw enable
```

### 7.3 Esempio Configurazione Windows Firewall (Target)

```powershell
# Allow WMI from scanner
New-NetFirewallRule -DisplayName "Scanner WMI Access" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 135,139,445 `
    -RemoteAddress 192.168.1.100,192.168.1.101 `
    -Action Allow

# Allow ICMP
New-NetFirewallRule -DisplayName "Scanner ICMP" `
    -Direction Inbound `
    -Protocol ICMPv4 `
    -RemoteAddress 192.168.1.100,192.168.1.101 `
    -Action Allow
```

---

## 8. Best Practices Sicurezza

### 8.1 Network Segmentation

```
┌─────────────────────────────────────┐
│ Management VLAN (192.168.100.0/24)  │
│ - SentinelCore Server               │
│ - Nessus Scanner                    │
│ - OpenVAS                           │
└─────────────────────────────────────┘
         │
         │ Firewall Rules
         │ (Allow scan traffic only)
         ↓
┌─────────────────────────────────────┐
│ Production Networks                 │
│ - DMZ (192.168.1.0/24)             │
│ - Internal LAN (192.168.10.0/24)   │
│ - Database Tier (192.168.20.0/24)  │
└─────────────────────────────────────┘
```

### 8.2 Monitoring Attività Scanner

```bash
# Linux: Monitora accessi SSH da scanner
sudo tail -f /var/log/auth.log | grep scanuser

# Windows: Monitora eventi Security Log
Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4624}
```

### 8.3 Rate Limiting per Scanner

```bash
# Limita frequenza scan per evitare DoS
# In SentinelCore UI:
Settings → Network Discovery → Rate Limiting
- Max Concurrent Scans: 5
- Scan Interval: 60 seconds between scans
```

### 8.4 Compliance Considerations

- **PCI-DSS:** Scan quarterly, credenziali scanner criptate
- **ISO 27001:** Audit log scansioni, review periodica
- **GDPR:** Documenta data processing (vulnerability data)

---

## Verifica Configurazione

### Test 1: Ping Discovery

```bash
# Dal server SentinelCore
ping -c 4 <target_machine_ip>

# Dovrebbe rispondere
64 bytes from 192.168.1.10: icmp_seq=1 ttl=64 time=0.5 ms
```

### Test 2: Port Scan

```bash
# Test nmap manuale
nmap -sS -p 22,80,443 <target_machine_ip>

# Output dovrebbe mostrare porte aperte
PORT    STATE SERVICE
22/tcp  open  ssh
80/tcp  open  http
```

### Test 3: SSH Authentication (Linux)

```bash
# Test SSH key
ssh -i /path/to/scanuser_key scanuser@<target_ip> "echo 'Scanner access OK'"

# Output: Scanner access OK
```

### Test 4: WMI Access (Windows)

```bash
# Da Linux con impacket
wmiexec.py DOMAIN/scanuser:'password'@<target_ip> "ipconfig"

# Dovrebbe mostrare output ipconfig
```

---

## Prossimi Passi

1. **Configure Scanner Integration in SentinelCore**
   - Vedi: `/docs/SCANNER_INTEGRATION.md`

2. **Setup Automated Scanning Schedule**
   - Network Discovery: Daily
   - Deep Scans: Weekly
   - Credentialed Scans: Monthly

3. **Import Vulnerability Data**
   - Upload XML da Nessus/OpenVAS
   - Automatic processing in SentinelCore

4. **Review & Remediate**
   - Dashboard → Vulnerabilities
   - Generate Remediation Plans
   - Track SLA compliance

---

## Supporto

- **Documentazione:** `/docs/`
- **Scanner Integration Guide:** `SCANNER_INTEGRATION.md`
- **Issues:** https://github.com/Dognet-Technologies/sentinelcore/issues

---

**Versione Documento:** 1.0
**Ultima Modifica:** 2025-01-25
**Compatibilità:** Debian 10+, Ubuntu 18.04+, Windows Server 2016+, Windows 10+
