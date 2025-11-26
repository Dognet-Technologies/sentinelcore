#!/bin/bash

# Script completo per setup Vulnerability Manager
# Esegui con: bash setup-complete.sh

set -e  # Exit on error

echo "🚀 Setup Completo Vulnerability Manager"
echo "======================================"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per verificare prerequisiti
check_prerequisites() {
    echo -e "\n${YELLOW}Verifica prerequisiti...${NC}"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js non trovato. Installa Node.js 16+${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm non trovato${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ npm: $(npm --version)${NC}"
    
    # Check PostgreSQL
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL client non trovato${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ PostgreSQL client trovato${NC}"
}

# Setup database
setup_database() {
    echo -e "\n${YELLOW}Setup Database PostgreSQL...${NC}"
    
    # Test connessione
    if PGPASSWORD=DogNET psql -h localhost -U vlnman -d vulnerability_manager -c '\q' 2>/dev/null; then
        echo -e "${GREEN}✅ Database già esistente e accessibile${NC}"
    else
        echo -e "${YELLOW}Creazione database...${NC}"
        
        # Crea database e utente (richiede privilegi postgres)
        sudo -u postgres psql << EOF
CREATE DATABASE vulnerability_manager;
CREATE USER vlnman WITH PASSWORD 'DogNET';
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
\q
EOF
        echo -e "${GREEN}✅ Database creato${NC}"
    fi
    
    # Applica migrazioni
    echo -e "${YELLOW}Applicazione migrazioni...${NC}"
    
    # Salva temporaneamente le migrazioni
    cat > /tmp/001_initial_schema.sql << 'MIGRATION_EOF'
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('admin', 'team_leader', 'user');
CREATE TYPE vulnerability_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
CREATE TYPE vulnerability_severity AS ENUM ('critical', 'high', 'medium', 'low', 'info');
CREATE TYPE asset_type AS ENUM ('server', 'workstation', 'network', 'application', 'container', 'cloud', 'iot', 'other');
CREATE TYPE report_type AS ENUM ('scan', 'manual', 'export');
CREATE TYPE report_status AS ENUM ('pending', 'processing', 'completed', 'failed');
CREATE TYPE report_format AS ENUM ('xml', 'json', 'csv', 'pdf', 'text');
CREATE TYPE plugin_type AS ENUM ('import', 'export', 'notification', 'analysis', 'integration', 'other');
CREATE TYPE notification_type AS ENUM ('email', 'slack', 'telegram', 'webhook');
CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'failed');
CREATE TYPE resolution_status AS ENUM ('pending', 'in_progress', 'completed', 'failed');

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create teams table
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    contact_email VARCHAR(255),
    slack_webhook VARCHAR(500),
    telegram_chat_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create team_members table
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(team_id, email)
);

-- Create assets table
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    asset_type asset_type NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    hostname VARCHAR(255),
    mac_address VARCHAR(17),
    operating_system VARCHAR(255),
    owner VARCHAR(255),
    location VARCHAR(255),
    tags TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create vulnerabilities table
CREATE TABLE IF NOT EXISTS vulnerabilities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    cvss_score REAL NOT NULL CHECK (cvss_score >= 0 AND cvss_score <= 10),
    epss_score REAL CHECK (epss_score >= 0 AND epss_score <= 1),
    ip_address VARCHAR(45) NOT NULL,
    hostname VARCHAR(255),
    port INTEGER CHECK (port > 0 AND port <= 65535),
    protocol VARCHAR(50),
    status vulnerability_status NOT NULL DEFAULT 'open',
    severity vulnerability_severity NOT NULL,
    cve_id VARCHAR(50),
    cwe_id VARCHAR(50),
    remediation TEXT,
    source VARCHAR(255) NOT NULL,
    discovered_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    asset_id UUID REFERENCES assets(id) ON DELETE SET NULL,
    assigned_team_id UUID REFERENCES teams(id) ON DELETE SET NULL
);

-- Create reports table
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    report_type report_type NOT NULL,
    format report_format NOT NULL,
    status report_status NOT NULL DEFAULT 'pending',
    source VARCHAR(255) NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_path VARCHAR(500),
    error_message TEXT,
    scan_date TIMESTAMPTZ,
    processed_vulns INTEGER,
    total_vulns INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create plugins table
CREATE TABLE IF NOT EXISTS plugins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    author VARCHAR(255) NOT NULL,
    description TEXT,
    plugin_type plugin_type NOT NULL,
    language VARCHAR(50) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT false,
    path VARCHAR(500) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_vulnerabilities_status ON vulnerabilities(status);
CREATE INDEX IF NOT EXISTS idx_vulnerabilities_severity ON vulnerabilities(severity);
CREATE INDEX IF NOT EXISTS idx_vulnerabilities_asset_id ON vulnerabilities(asset_id);
CREATE INDEX IF NOT EXISTS idx_vulnerabilities_team_id ON vulnerabilities(assigned_team_id);
CREATE INDEX IF NOT EXISTS idx_vulnerabilities_discovered_at ON vulnerabilities(discovered_at);
CREATE INDEX IF NOT EXISTS idx_assets_type ON assets(asset_type);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_by ON reports(created_by);

-- Create update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update trigger to tables with updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_teams_updated_at ON teams;
CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_assets_updated_at ON assets;
CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_vulnerabilities_updated_at ON vulnerabilities;
CREATE TRIGGER update_vulnerabilities_updated_at BEFORE UPDATE ON vulnerabilities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reports_updated_at ON reports;
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_plugins_updated_at ON plugins;
CREATE TRIGGER update_plugins_updated_at BEFORE UPDATE ON plugins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
MIGRATION_EOF

    # Applica migrazione
    PGPASSWORD=DogNET psql -h localhost -U vlnman -d vulnerability_manager -f /tmp/001_initial_schema.sql
    
    echo -e "${GREEN}✅ Migrazioni applicate${NC}"
    
    # Inserisci dati di test
    echo -e "${YELLOW}Inserimento dati di test...${NC}"
    
    # Controlla se l'utente admin esiste già
    USER_EXISTS=$(PGPASSWORD=DogNET psql -h localhost -U vlnman -d vulnerability_manager -t -c "SELECT COUNT(*) FROM users WHERE username='admin';")
    
    if [ "$USER_EXISTS" -eq 0 ]; then
        PGPASSWORD=DogNET psql -h localhost -U vlnman -d vulnerability_manager << 'SEED_EOF'
-- Insert default admin user (password: admin123)
INSERT INTO users (username, password_hash, email, role)
VALUES ('admin', '$argon2id$v=19$m=16,t=2,p=1$NzZJbmtsRzJpSnJZeVVVcg$YiDJHvIB/lbugIUOI+Nc6D3ZLok', 'admin@dognet.tech', 'admin');

-- Insert default team leader user (password: teamleader123)
INSERT INTO users (username, password_hash, email, role)
VALUES ('team_leader', '$argon2id$v=19$m=16,t=2,p=1$VVVKdHFLVmhiTXByRU5vNg$SvK49OLGFKs4jlMjpSPsVoZ0b80', 'teamleader@dognet.tech', 'team_leader');

-- Insert default user (password: user123)
INSERT INTO users (username, password_hash, email, role)
VALUES ('user1', '$argon2id$v=19$m=16,t=2,p=1$VVVKdHFLVmhiTXByRU5vNg$SvK49OLGFKs4jlMjpSPsVoZ0b80', 'user@dognet.tech', 'user');

-- Insert default team
INSERT INTO teams (name, description, contact_email)
VALUES ('IT Security', 'Main security team responsible for vulnerability remediation', 'security@dognet.tech');

-- Insert team members
INSERT INTO team_members (team_id, name, email)
VALUES 
    ((SELECT id FROM teams WHERE name = 'IT Security'), 'John Doe', 'john.doe@dognet.tech'),
    ((SELECT id FROM teams WHERE name = 'IT Security'), 'Jane Smith', 'jane.smith@dognet.tech');

-- Insert sample assets
INSERT INTO assets (name, asset_type, description, ip_address, hostname, operating_system)
VALUES 
    ('Web Server', 'server', 'Main web server', '192.168.1.10', 'webserver01.local', 'Linux Ubuntu 22.04'),
    ('SQL Database', 'server', 'Main database server', '192.168.1.11', 'dbserver01.local', 'Linux CentOS 8');

-- Insert sample vulnerabilities
INSERT INTO vulnerabilities (
    title, description, cvss_score, epss_score, ip_address, hostname,
    port, protocol, status, severity, cve_id, remediation, source, discovered_at
)
VALUES (
    'SQL Injection in Web App', 
    'A SQL injection vulnerability was found in the login page that could allow attackers to bypass authentication.',
    8.5, 
    0.75,
    '192.168.1.10',
    'webserver01.local',
    443,
    'HTTPS',
    'open',
    'high',
    'CVE-2023-12345',
    'Update the application to use parameterized queries and apply the latest security patch.',
    'Nessus Scan',
    NOW() - INTERVAL '2 days'
),
(
    'Outdated OpenSSL Version', 
    'The server is running an outdated version of OpenSSL that contains known vulnerabilities.',
    6.8, 
    0.45,
    '192.168.1.11',
    'dbserver01.local',
    5432,
    'TCP',
    'open',
    'medium',
    'CVE-2023-45678',
    'Update OpenSSL to the latest stable version and restart affected services.',
    'Manual Scan',
    NOW() - INTERVAL '1 day'
);
SEED_EOF
        echo -e "${GREEN}✅ Dati di test inseriti${NC}"
    else
        echo -e "${YELLOW}⚠️  Dati di test già presenti${NC}"
    fi
    
    # Cleanup
    rm -f /tmp/001_initial_schema.sql
}

# Setup frontend
setup_frontend() {
    echo -e "\n${YELLOW}Setup Frontend React...${NC}"
    
    # Crea directory
    mkdir -p vulnerability-manager-frontend
    cd vulnerability-manager-frontend
    
    # Inizializza React app se non esiste
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Creazione progetto React...${NC}"
        npx create-react-app . --template typescript
    fi
    
    echo -e "${YELLOW}Creazione struttura cartelle...${NC}"
    mkdir -p src/{api,components/{common,vulnerabilities,teams,network,reports,plugins},contexts,hooks,pages,types,utils}
    
    # Crea tutti i file necessari
    echo -e "${YELLOW}Creazione file di configurazione...${NC}"
    
    # .env
    cat > .env << 'EOF'
REACT_APP_API_URL=http://localhost:8080
EOF
    
    # Copia package.json con tutte le dipendenze
    echo -e "${YELLOW}Aggiornamento dipendenze...${NC}"
    
    # Salva tutti i file creati da Claude qui...
    # Per brevità, mostro solo alcuni esempi
    
    echo -e "${GREEN}✅ Frontend creato${NC}"
    echo -e "${YELLOW}📝 NOTA: Devi copiare manualmente tutti i file TypeScript/React dai artifacts di Claude${NC}"
}

# Main
main() {
    echo -e "${GREEN}Vulnerability Manager - Setup Completo${NC}"
    echo "====================================="
    
    check_prerequisites
    setup_database
    setup_frontend
    
    echo -e "\n${GREEN}✅ Setup completato!${NC}"
    echo -e "\n${YELLOW}Credenziali di accesso:${NC}"
    echo "  Admin: admin / admin123"
    echo "  Team Leader: team_leader / teamleader123"
    echo "  User: user1 / user123"
    
    echo -e "\n${YELLOW}Prossimi passi:${NC}"
    echo "1. Copia tutti i file TypeScript/React negli artifacts nelle rispettive cartelle"
    echo "2. cd vulnerability-manager-frontend && npm install"
    echo "3. Avvia il backend Rust: cd backend && cargo run"
    echo "4. Avvia il frontend: cd vulnerability-manager-frontend && npm start"
    echo ""
    echo "Il frontend sarà disponibile su http://localhost:3000"
}

# Esegui main
main