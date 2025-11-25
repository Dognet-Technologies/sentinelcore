-- populate-test-data.sql
-- Script completo per popolare il database SentinelCore con dati di test
-- Esegui con: psql -h localhost -U vlnman -d vulnerability_manager -f populate-test-data.sql

BEGIN;

-- Pulisci dati esistenti (opzionale - commenta se vuoi mantenere dati esistenti)
-- TRUNCATE TABLE audit_logs, notifications, reputation_events, user_api_keys,
--                user_notification_settings, user_permissions, user_sessions,
--                resolutions, remediation_tasks, device_vulnerabilities, network_links,
--                network_devices, network_scans, reports, vulnerabilities, assets,
--                team_members, teams, ip_whitelist, plugins, users CASCADE;

-- ============================================================================
-- USERS (5 utenti con ruoli diversi)
-- ============================================================================
INSERT INTO users (id, username, email, password_hash, role, is_locked, failed_login_attempts,
                   avatar_url, phone_number, two_factor_enabled, two_factor_secret,
                   reputation_score, created_at, updated_at)
VALUES
-- Password: Admin123!
('11111111-1111-1111-1111-111111111111', 'admin', 'admin@sentinelcore.com',
 '$argon2id$v=19$m=19456,t=2,p=1$VGhpc0lzQVNhbHQ$iL8xMJqq7K8xYqJqWqJqWqJqWqJqWqJqWqJqWqJqWqI',
 'admin', false, 0, '/uploads/avatars/admin.png', '+39 333 1234567', true,
 'JBSWY3DPEHPK3PXP', 1500, NOW() - INTERVAL '6 months', NOW()),

-- Password: User123!
('22222222-2222-2222-2222-222222222222', 'jdoe', 'john.doe@sentinelcore.com',
 '$argon2id$v=19$m=19456,t=2,p=1$VGhpc0lzQVNhbHQ$iL8xMJqq7K8xYqJqWqJqWqJqWqJqWqJqWqJqWqJqWqI',
 'team_leader', false, 0, '/uploads/avatars/jdoe.png', '+39 333 2345678', false, NULL,
 850, NOW() - INTERVAL '3 months', NOW()),

-- Password: User123!
('33333333-3333-3333-3333-333333333333', 'asmith', 'alice.smith@sentinelcore.com',
 '$argon2id$v=19$m=19456,t=2,p=1$VGhpc0lzQVNhbHQ$iL8xMJqq7K8xYqJqWqJqWqJqWqJqWqJqWqJqWqJqWqI',
 'user', false, 0, '/uploads/avatars/asmith.png', '+39 333 3456789', true,
 'KBSWY3DPEHPK3PXP', 320, NOW() - INTERVAL '2 months', NOW()),

-- Password: User123!
('44444444-4444-4444-4444-444444444444', 'bjones', 'bob.jones@sentinelcore.com',
 '$argon2id$v=19$m=19456,t=2,p=1$VGhpc0lzQVNhbHQ$iL8xMJqq7K8xYqJqWqJqWqJqWqJqWqJqWqJqWqJqWqI',
 'team_leader', false, 0, '/uploads/avatars/bjones.png', '+39 333 4567890', false, NULL,
 670, NOW() - INTERVAL '4 months', NOW()),

-- Password: User123!
('55555555-5555-5555-5555-555555555555', 'cdavis', 'carol.davis@sentinelcore.com',
 '$argon2id$v=19$m=19456,t=2,p=1$VGhpc0lzQVNhbHQ$iL8xMJqq7K8xYqJqWqJqWqJqWqJqWqJqWqJqWqJqWqI',
 'user', false, 0, '/uploads/avatars/cdavis.png', '+39 333 5678901', false, NULL,
 180, NOW() - INTERVAL '1 month', NOW());

-- ============================================================================
-- USER_SESSIONS (Sessioni attive)
-- ============================================================================
INSERT INTO user_sessions (id, user_id, token_hash, ip_address, user_agent, expires_at, created_at)
VALUES
('s1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 'hash_admin_session_1', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
 NOW() + INTERVAL '24 hours', NOW() - INTERVAL '2 hours'),
('s2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'hash_jdoe_session_1', '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
 NOW() + INTERVAL '24 hours', NOW() - INTERVAL '1 hour');

-- ============================================================================
-- USER_API_KEYS (API Keys per integrations)
-- ============================================================================
INSERT INTO user_api_keys (id, user_id, key_name, key_hash, expires_at, last_used_at, created_at)
VALUES
('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
 'Jenkins CI/CD', 'hash_jenkins_api_key', NOW() + INTERVAL '1 year', NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 months'),
('a2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
 'Automation Script', 'hash_automation_key', NOW() + INTERVAL '6 months', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 month');

-- ============================================================================
-- USER_NOTIFICATION_SETTINGS
-- ============================================================================
INSERT INTO user_notification_settings (user_id, email_enabled, push_enabled, new_vulnerability, status_change,
                                         assignment, report_ready, system_alert, created_at, updated_at)
VALUES
('11111111-1111-1111-1111-111111111111', true, true, true, true, true, true, true, NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', true, false, true, true, true, false, true, NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', true, true, true, false, true, true, false, NOW(), NOW()),
('44444444-4444-4444-4444-444444444444', true, false, true, true, false, false, true, NOW(), NOW()),
('55555555-5555-5555-5555-555555555555', false, false, false, false, true, false, false, NOW(), NOW());

-- ============================================================================
-- REPUTATION_EVENTS (Eventi reputazione utenti)
-- ============================================================================
INSERT INTO reputation_events (id, user_id, event_type, points_change, description, created_at)
VALUES
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'vulnerability_resolved', 50, 'Risolto CVE-2024-1234', NOW() - INTERVAL '1 day'),
(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'vulnerability_resolved', 30, 'Risolto CVE-2024-5678', NOW() - INTERVAL '2 days'),
(gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 'report_generated', 20, 'Report mensile generato', NOW() - INTERVAL '5 days'),
(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'vulnerability_found', 10, 'Trovata nuova vulnerabilità', NOW() - INTERVAL '1 week');

-- ============================================================================
-- TEAMS (4 team)
-- ============================================================================
INSERT INTO teams (id, name, description, contact_email, slack_webhook, telegram_chat_id, created_at, updated_at)
VALUES
('t1111111-1111-1111-1111-111111111111', 'Security Team', 'Team principale per sicurezza e vulnerability management',
 'security@sentinelcore.com', 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX',
 '-1001234567890', NOW() - INTERVAL '6 months', NOW()),

('t2222222-2222-2222-2222-222222222222', 'DevOps Team', 'Team DevOps per infrastruttura e deployment',
 'devops@sentinelcore.com', 'https://hooks.slack.com/services/T11111111/B11111111/YYYYYYYYYYYYYYYYYYYY',
 '-1001234567891', NOW() - INTERVAL '5 months', NOW()),

('t3333333-3333-3333-3333-333333333333', 'Network Team', 'Team per gestione rete e network security',
 'network@sentinelcore.com', NULL, '-1001234567892', NOW() - INTERVAL '4 months', NOW()),

('t4444444-4444-4444-4444-444444444444', 'Application Security', 'Team per sicurezza applicazioni',
 'appsec@sentinelcore.com', 'https://hooks.slack.com/services/T22222222/B22222222/ZZZZZZZZZZZZZZZZZZZZ',
 NULL, NOW() - INTERVAL '3 months', NOW());

-- ============================================================================
-- TEAM_MEMBERS (Assegnazione membri ai team)
-- ============================================================================
INSERT INTO team_members (team_id, user_id, joined_at)
VALUES
('t1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '6 months'),
('t1111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '3 months'),
('t1111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '2 months'),
('t2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '5 months'),
('t2222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '4 months'),
('t3333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', NOW() - INTERVAL '4 months'),
('t3333333-3333-3333-3333-333333333333', '55555555-5555-5555-5555-555555555555', NOW() - INTERVAL '1 month'),
('t4444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '2 months');

-- ============================================================================
-- ASSETS (12 asset IT diversi)
-- ============================================================================
INSERT INTO assets (id, name, type, ip_address, hostname, mac_address, os, os_version, location, owner, tags, notes, created_at, updated_at)
VALUES
('as111111-1111-1111-1111-111111111111', 'Web Server Production', 'server', '192.168.1.10', 'web-prod-01.local',
 '00:1A:2B:3C:4D:5E', 'Ubuntu', '22.04 LTS', 'Datacenter Rack A1', 'DevOps Team',
 ARRAY['production', 'web', 'nginx', 'critical'], 'Server web principale', NOW() - INTERVAL '1 year', NOW()),

('as222222-2222-2222-2222-222222222222', 'Database Server', 'server', '192.168.1.11', 'db-prod-01.local',
 '00:1A:2B:3C:4D:5F', 'PostgreSQL', '16.0', 'Datacenter Rack A2', 'DevOps Team',
 ARRAY['production', 'database', 'postgresql', 'critical'], 'Database principale', NOW() - INTERVAL '1 year', NOW()),

('as333333-3333-3333-3333-333333333333', 'Application Server', 'server', '192.168.1.12', 'app-prod-01.local',
 '00:1A:2B:3C:4D:60', 'Ubuntu', '22.04 LTS', 'Datacenter Rack A3', 'DevOps Team',
 ARRAY['production', 'application', 'nodejs'], 'Application server Node.js', NOW() - INTERVAL '8 months', NOW()),

('as444444-4444-4444-4444-444444444444', 'Firewall Gateway', 'network', '192.168.1.1', 'firewall-01.local',
 '00:1A:2B:3C:4D:61', 'pfSense', '2.7.0', 'Network Room', 'Network Team',
 ARRAY['network', 'firewall', 'gateway', 'critical'], 'Firewall principale', NOW() - INTERVAL '2 years', NOW()),

('as555555-5555-5555-5555-555555555555', 'Core Switch', 'network', '192.168.1.2', 'switch-core-01.local',
 '00:1A:2B:3C:4D:62', 'Cisco IOS', '15.2', 'Network Room', 'Network Team',
 ARRAY['network', 'switch', 'core'], 'Switch core principale', NOW() - INTERVAL '2 years', NOW()),

('as666666-6666-6666-6666-666666666666', 'Development Workstation', 'workstation', '192.168.1.50', 'dev-ws-01.local',
 '00:1A:2B:3C:4D:63', 'Windows', '11 Pro', 'Office Floor 2', 'John Doe',
 ARRAY['development', 'workstation', 'windows'], 'Workstation sviluppo', NOW() - INTERVAL '1 year', NOW()),

('as777777-7777-7777-7777-777777777777', 'Office Printer', 'iot', '192.168.1.100', 'printer-01.local',
 '00:1A:2B:3C:4D:64', 'Embedded Linux', '1.0', 'Office Floor 1', 'IT Department',
 ARRAY['iot', 'printer', 'office'], 'Stampante ufficio principale', NOW() - INTERVAL '3 years', NOW()),

('as888888-8888-8888-8888-888888888888', 'Cloud VM - API Gateway', 'cloud', '10.0.1.10', 'api-gateway-cloud',
 NULL, 'Ubuntu', '22.04 LTS', 'AWS eu-west-1', 'DevOps Team',
 ARRAY['cloud', 'aws', 'api', 'production'], 'API Gateway su AWS', NOW() - INTERVAL '6 months', NOW()),

('as999999-9999-9999-9999-999999999999', 'Docker Host', 'server', '192.168.1.20', 'docker-host-01.local',
 '00:1A:2B:3C:4D:65', 'Ubuntu', '22.04 LTS', 'Datacenter Rack B1', 'DevOps Team',
 ARRAY['container', 'docker', 'orchestration'], 'Host per container Docker', NOW() - INTERVAL '1 year', NOW()),

('as101010-1010-1010-1010-101010101010', 'Backup Server', 'server', '192.168.1.30', 'backup-01.local',
 '00:1A:2B:3C:4D:66', 'FreeBSD', '13.2', 'Datacenter Rack C1', 'IT Department',
 ARRAY['backup', 'storage', 'critical'], 'Server backup e archiviazione', NOW() - INTERVAL '2 years', NOW()),

('as111010-1110-1010-1010-101010101010', 'CCTV Camera', 'iot', '192.168.1.150', 'cctv-entrance.local',
 '00:1A:2B:3C:4D:67', 'Embedded', 'v2.4', 'Building Entrance', 'Security Team',
 ARRAY['iot', 'security', 'cctv'], 'Telecamera ingresso', NOW() - INTERVAL '1 year', NOW()),

('as121212-1212-1212-1212-121212121212', 'Load Balancer', 'network', '192.168.1.5', 'loadbalancer-01.local',
 '00:1A:2B:3C:4D:68', 'HAProxy', '2.8', 'Datacenter Rack A1', 'DevOps Team',
 ARRAY['network', 'loadbalancer', 'haproxy', 'critical'], 'Load balancer principale', NOW() - INTERVAL '1 year', NOW());

-- ============================================================================
-- VULNERABILITIES (25 vulnerabilità con vari stati e severità)
-- ============================================================================
INSERT INTO vulnerabilities (id, title, description, severity, cvss_score, epss_score, cve_id, cwe_id,
                             ip_address, hostname, port, protocol, status, asset_id, assigned_team_id,
                             remediation_instructions, discovered_at, created_at, updated_at)
VALUES
-- CRITICAL
('v1111111-1111-1111-1111-111111111111', 'SQL Injection in Login Form',
 'Vulnerabilità SQL Injection nella form di login che permette bypass autenticazione',
 'critical', 9.8, 0.89, 'CVE-2024-1234', 'CWE-89', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'open', 'as111111-1111-1111-1111-111111111111', 't1111111-1111-1111-1111-111111111111',
 'Implementare prepared statements e validazione input', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW()),

('v2222222-2222-2222-2222-222222222222', 'Remote Code Execution - Apache Struts',
 'RCE critico in Apache Struts 2.5.x che permette esecuzione codice remoto',
 'critical', 10.0, 0.95, 'CVE-2024-5678', 'CWE-20', '192.168.1.12', 'app-prod-01.local',
 8080, 'HTTP', 'in_progress', 'as333333-3333-3333-3333-333333333333', 't4444444-4444-4444-4444-444444444444',
 'Aggiornare Apache Struts alla versione 2.5.33 o successiva', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW()),

('v3333333-3333-3333-3333-333333333333', 'Unauthenticated Database Access',
 'Database PostgreSQL accessibile senza autenticazione da rete interna',
 'critical', 9.1, 0.75, NULL, 'CWE-306', '192.168.1.11', 'db-prod-01.local',
 5432, 'PostgreSQL', 'open', 'as222222-2222-2222-2222-222222222222', 't2222222-2222-2222-2222-222222222222',
 'Configurare pg_hba.conf per richiedere autenticazione', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW()),

-- HIGH
('v4444444-4444-4444-4444-444444444444', 'Privilege Escalation via Sudo Misconfiguration',
 'Configurazione sudo permette escalation privilegi a utente non autorizzato',
 'high', 8.8, 0.12, 'CVE-2024-9012', 'CWE-269', '192.168.1.10', 'web-prod-01.local',
 22, 'SSH', 'resolved', 'as111111-1111-1111-1111-111111111111', 't1111111-1111-1111-1111-111111111111',
 'Rivedere configurazione /etc/sudoers e rimuovere permessi eccessivi', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day'),

('v5555555-5555-5555-5555-555555555555', 'Cross-Site Scripting (XSS) in Comments',
 'XSS reflected nella sezione commenti che permette furto session cookie',
 'high', 7.5, 0.34, NULL, 'CWE-79', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'in_progress', 'as111111-1111-1111-1111-111111111111', 't4444444-4444-4444-4444-444444444444',
 'Sanitizzare input utente e implementare Content Security Policy', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW()),

('v6666666-6666-6666-6666-666666666666', 'Weak SSL/TLS Configuration',
 'Server supporta protocolli SSL/TLS obsoleti (TLS 1.0, TLS 1.1) e cipher deboli',
 'high', 7.4, 0.08, NULL, 'CWE-327', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'open', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Disabilitare TLS < 1.2 e configurare cipher suite moderni', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', NOW()),

('v7777777-7777-7777-7777-777777777777', 'Default Credentials on Printer',
 'Stampante di rete utilizza credenziali di default (admin/admin)',
 'high', 8.1, 0.45, NULL, 'CWE-798', '192.168.1.100', 'printer-01.local',
 80, 'HTTP', 'open', 'as777777-7777-7777-7777-777777777777', 't3333333-3333-3333-3333-333333333333',
 'Cambiare credenziali di default con password complessa', NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days', NOW()),

-- MEDIUM
('v8888888-8888-8888-8888-888888888888', 'Information Disclosure via Error Messages',
 'Messaggi di errore dettagliati espongono informazioni sensibili sul sistema',
 'medium', 5.3, 0.02, NULL, 'CWE-209', '192.168.1.12', 'app-prod-01.local',
 8080, 'HTTP', 'closed', 'as333333-3333-3333-3333-333333333333', 't4444444-4444-4444-4444-444444444444',
 'Implementare error handling generico per produzione', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days', NOW() - INTERVAL '5 days'),

('v9999999-9999-9999-9999-999999999999', 'Missing Security Headers',
 'Server web manca di security headers importanti (X-Frame-Options, HSTS, ecc.)',
 'medium', 5.0, 0.01, NULL, 'CWE-16', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'in_progress', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Configurare security headers in nginx/apache', NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days', NOW()),

('v1010101-1010-1010-1010-101010101010', 'Unencrypted HTTP Traffic',
 'Alcuni endpoint accessibili via HTTP non cifrato espongono dati in chiaro',
 'medium', 6.5, 0.15, NULL, 'CWE-319', '192.168.1.12', 'app-prod-01.local',
 80, 'HTTP', 'open', 'as333333-3333-3333-3333-333333333333', 't2222222-2222-2222-2222-222222222222',
 'Forzare redirect HTTP→HTTPS su tutti gli endpoint', NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days', NOW()),

('v1111101-1111-1010-1010-101010101010', 'Outdated Software Version - Nginx',
 'Nginx versione 1.18.0 contiene vulnerabilità note corrette in versioni successive',
 'medium', 5.9, 0.08, 'CVE-2023-44487', 'CWE-400', '192.168.1.10', 'web-prod-01.local',
 80, 'HTTP', 'open', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Aggiornare Nginx alla versione 1.24.0 o successiva', NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days', NOW()),

('v1212121-1212-1212-1212-121212121212', 'Directory Listing Enabled',
 'Directory listing abilitato su /uploads espone file caricati dagli utenti',
 'medium', 5.3, 0.03, NULL, 'CWE-548', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'resolved', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Disabilitare directory listing in configurazione web server', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days', NOW() - INTERVAL '10 days'),

-- LOW
('v1313131-1313-1313-1313-131313131313', 'Verbose Server Banner',
 'Server banner rivela versione esatta del software esposta negli header HTTP',
 'low', 3.7, 0.00, NULL, 'CWE-200', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'open', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Configurare server_tokens off in nginx', NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days', NOW()),

('v1414141-1414-1414-1414-141414141414', 'Missing Rate Limiting',
 'API endpoints non implementano rate limiting, possibile abuso',
 'low', 4.3, 0.01, NULL, 'CWE-770', '192.168.1.12', 'app-prod-01.local',
 8080, 'HTTP', 'open', 'as333333-3333-3333-3333-333333333333', 't4444444-4444-4444-4444-444444444444',
 'Implementare rate limiting a livello applicativo o reverse proxy', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days', NOW()),

('v1515151-1515-1515-1515-151515151515', 'Clickjacking Vulnerability',
 'Manca X-Frame-Options header, sito embeddabile in iframe malevolo',
 'low', 4.0, 0.01, NULL, 'CWE-1021', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'closed', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Aggiungere header X-Frame-Options: DENY o SAMEORIGIN', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days', NOW() - INTERVAL '15 days'),

-- INFO
('v1616161-1616-1616-1616-161616161616', 'Outdated jQuery Library',
 'jQuery 1.12.4 utilizzato, disponibile versione più recente 3.7.1',
 'info', 0.0, 0.00, NULL, 'CWE-1104', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'open', 'as111111-1111-1111-1111-111111111111', 't4444444-4444-4444-4444-444444444444',
 'Aggiornare jQuery a versione 3.x più recente', NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days', NOW()),

('v1717171-1717-1717-1717-171717171717', 'Robots.txt Information Disclosure',
 'File robots.txt espone path di directory sensibili',
 'info', 0.0, 0.00, NULL, 'CWE-200', '192.168.1.10', 'web-prod-01.local',
 443, 'HTTPS', 'open', 'as111111-1111-1111-1111-111111111111', 't2222222-2222-2222-2222-222222222222',
 'Rivedere robots.txt e rimuovere riferimenti a path sensibili', NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days', NOW()),

-- Altre vulnerabilità per altri asset
('v1818181-1818-1818-1818-181818181818', 'Weak Firewall Rule Configuration',
 'Regole firewall permettono traffico non necessario dalla WAN',
 'high', 7.2, 0.05, NULL, 'CWE-284', '192.168.1.1', 'firewall-01.local',
 443, 'HTTPS', 'in_progress', 'as444444-4444-4444-4444-444444444444', 't3333333-3333-3333-3333-333333333333',
 'Implementare principio least privilege nelle regole firewall', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', NOW()),

('v1919191-1919-1919-1919-191919191919', 'Unpatched Docker Host',
 'Docker host con kernel Linux non aggiornato, vulnerabile a container escape',
 'high', 8.0, 0.22, 'CVE-2024-3333', 'CWE-269', '192.168.1.20', 'docker-host-01.local',
 2376, 'Docker API', 'open', 'as999999-9999-9999-9999-999999999999', 't2222222-2222-2222-2222-222222222222',
 'Aggiornare kernel Linux e Docker Engine alla versione più recente', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', NOW()),

('v2020202-2020-2020-2020-202020202020', 'Exposed Docker API',
 'Docker API esposta senza autenticazione sulla rete',
 'critical', 9.8, 0.67, NULL, 'CWE-306', '192.168.1.20', 'docker-host-01.local',
 2376, 'Docker API', 'open', 'as999999-9999-9999-9999-999999999999', 't2222222-2222-2222-2222-222222222222',
 'Abilitare TLS e autenticazione su Docker API', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW()),

('v2121212-2121-2121-2121-212121212121', 'SNMP Community String Default',
 'Switch core utilizza community string SNMP di default (public)',
 'medium', 6.5, 0.12, NULL, 'CWE-798', '192.168.1.2', 'switch-core-01.local',
 161, 'SNMP', 'open', 'as555555-5555-5555-5555-555555555555', 't3333333-3333-3333-3333-333333333333',
 'Cambiare community string SNMP e abilitare SNMPv3', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days', NOW()),

('v2222212-2222-2121-2121-212121212121', 'Backup Files World-Readable',
 'File di backup su backup server hanno permessi 777 (world-readable)',
 'high', 7.5, 0.08, NULL, 'CWE-732', '192.168.1.30', 'backup-01.local',
 22, 'SSH', 'open', 'as101010-1010-1010-1010-101010101010', 't2222222-2222-2222-2222-222222222222',
 'Modificare permessi file backup a 600 e owner root', NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days', NOW()),

('v2323232-2323-2323-2323-232323232323', 'CCTV Camera Default Password',
 'Telecamera CCTV utilizza password di default del produttore',
 'high', 8.3, 0.55, NULL, 'CWE-798', '192.168.1.150', 'cctv-entrance.local',
 80, 'HTTP', 'open', 'as111010-1110-1010-1010-101010101010', 't1111111-1111-1111-1111-111111111111',
 'Cambiare password di default con password robusta', NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days', NOW()),

('v2424242-2424-2424-2424-242424242424', 'Load Balancer Health Check Exposed',
 'Endpoint health check del load balancer accessibile pubblicamente',
 'low', 4.2, 0.01, NULL, 'CWE-200', '192.168.1.5', 'loadbalancer-01.local',
 80, 'HTTP', 'open', 'as121212-1212-1212-1212-121212121212', 't2222222-2222-2222-2222-222222222222',
 'Limitare accesso health check a IP interni', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', NOW()),

('v2525252-2525-2525-2525-252525252525', 'Missing AWS Security Groups Config',
 'EC2 instance su AWS con security group troppo permissivo (0.0.0.0/0)',
 'high', 7.8, 0.18, NULL, 'CWE-284', '10.0.1.10', 'api-gateway-cloud',
 443, 'HTTPS', 'in_progress', 'as888888-8888-8888-8888-888888888888', 't2222222-2222-2222-2222-222222222222',
 'Restringere security group AWS a soli IP necessari', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW());

-- ============================================================================
-- RESOLUTIONS (Risoluzioni per vulnerabilità resolved/closed)
-- ============================================================================
INSERT INTO resolutions (id, vulnerability_id, resolved_by, resolution_notes, resolution_date, verified_by, verified_at, created_at)
VALUES
(gen_random_uuid(), 'v4444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111',
 'Configurazione sudo rivista, rimossi permessi NOPASSWD per utenti non autorizzati',
 NOW() - INTERVAL '1 day', '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), 'v8888888-8888-8888-8888-888888888888', '22222222-2222-2222-2222-222222222222',
 'Implementato error handler generico in produzione, rimossi stack trace',
 NOW() - INTERVAL '5 days', '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '4 days', NOW() - INTERVAL '5 days'),

(gen_random_uuid(), 'v1212121-1212-1212-1212-121212121212', '22222222-2222-2222-2222-222222222222',
 'Directory listing disabilitato in configurazione nginx',
 NOW() - INTERVAL '10 days', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '8 days', NOW() - INTERVAL '10 days'),

(gen_random_uuid(), 'v1515151-1515-1515-1515-151515151515', '33333333-3333-3333-3333-333333333333',
 'Aggiunto header X-Frame-Options: SAMEORIGIN',
 NOW() - INTERVAL '15 days', '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '14 days', NOW() - INTERVAL '15 days');

-- ============================================================================
-- NETWORK_SCANS (3 scan di rete)
-- ============================================================================
INSERT INTO network_scans (id, scan_name, scan_type, target_range, status, devices_found,
                           started_at, completed_at, created_by, created_at)
VALUES
('ns111111-1111-1111-1111-111111111111', 'Production Network Full Scan', 'nmap', '192.168.1.0/24',
 'completed', 12, NOW() - INTERVAL '1 day' - INTERVAL '5 minutes', NOW() - INTERVAL '1 day',
 '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day' - INTERVAL '10 minutes'),

('ns222222-2222-2222-2222-222222222222', 'Quick ARP Scan Office Network', 'arp', '192.168.1.0/24',
 'completed', 8, NOW() - INTERVAL '6 hours' - INTERVAL '2 minutes', NOW() - INTERVAL '6 hours',
 '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '6 hours' - INTERVAL '5 minutes'),

('ns333333-3333-3333-3333-333333333333', 'Datacenter Deep Scan', 'nmap', '192.168.1.0/28',
 'completed', 7, NOW() - INTERVAL '3 days' - INTERVAL '10 minutes', NOW() - INTERVAL '3 days',
 '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '3 days' - INTERVAL '20 minutes');

-- ============================================================================
-- NETWORK_DEVICES (12 dispositivi di rete scoperti)
-- ============================================================================
INSERT INTO network_devices (id, ip_address, mac_address, hostname, device_type, device_status,
                             vendor, os_name, os_version, open_ports, services,
                             first_seen, last_seen, created_at, updated_at)
VALUES
-- Servers
(gen_random_uuid(), '192.168.1.10'::inet, '00:1A:2B:3C:4D:5E', 'web-prod-01.local', 'server', 'online',
 'Dell Inc.', 'Ubuntu', '22.04', ARRAY[22, 80, 443],
 '{"22": {"name": "ssh", "version": "OpenSSH 8.9"}, "80": {"name": "http", "version": "nginx 1.18.0"}, "443": {"name": "https", "version": "nginx 1.18.0"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 hour'),

(gen_random_uuid(), '192.168.1.11'::inet, '00:1A:2B:3C:4D:5F', 'db-prod-01.local', 'server', 'online',
 'HP', 'Ubuntu', '22.04', ARRAY[22, 5432],
 '{"22": {"name": "ssh", "version": "OpenSSH 8.9"}, "5432": {"name": "postgresql", "version": "PostgreSQL 16.0"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 hours'),

(gen_random_uuid(), '192.168.1.12'::inet, '00:1A:2B:3C:4D:60', 'app-prod-01.local', 'server', 'online',
 'Dell Inc.', 'Ubuntu', '22.04', ARRAY[22, 80, 8080],
 '{"22": {"name": "ssh", "version": "OpenSSH 8.9"}, "80": {"name": "http"}, "8080": {"name": "http-alt", "version": "Node.js Express"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '3 days', NOW() - INTERVAL '30 minutes'),

(gen_random_uuid(), '192.168.1.20'::inet, '00:1A:2B:3C:4D:65', 'docker-host-01.local', 'server', 'online',
 'Supermicro', 'Ubuntu', '22.04', ARRAY[22, 2375, 2376],
 '{"22": {"name": "ssh", "version": "OpenSSH 8.9"}, "2375": {"name": "docker"}, "2376": {"name": "docker-tls"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 hour'),

(gen_random_uuid(), '192.168.1.30'::inet, '00:1A:2B:3C:4D:66', 'backup-01.local', 'server', 'online',
 'Dell Inc.', 'FreeBSD', '13.2', ARRAY[22],
 '{"22": {"name": "ssh", "version": "OpenSSH 9.3"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 hours'),

-- Network devices
(gen_random_uuid(), '192.168.1.1'::inet, '00:1A:2B:3C:4D:61', 'firewall-01.local', 'firewall', 'online',
 'Netgate', 'pfSense', '2.7.0', ARRAY[443, 8443],
 '{"443": {"name": "https", "version": "pfSense WebGUI"}, "8443": {"name": "https-alt"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 minutes'),

(gen_random_uuid(), '192.168.1.2'::inet, '00:1A:2B:3C:4D:62', 'switch-core-01.local', 'switch', 'online',
 'Cisco', 'IOS', '15.2', ARRAY[23, 80, 161],
 '{"23": {"name": "telnet"}, "80": {"name": "http"}, "161": {"name": "snmp"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '10 minutes', NOW() - INTERVAL '3 days', NOW() - INTERVAL '10 minutes'),

(gen_random_uuid(), '192.168.1.5'::inet, '00:1A:2B:3C:4D:68', 'loadbalancer-01.local', 'router', 'online',
 'HAProxy Technologies', 'Linux', '6.1', ARRAY[80, 443, 8404],
 '{"80": {"name": "http", "version": "HAProxy 2.8"}, "443": {"name": "https", "version": "HAProxy 2.8"}, "8404": {"name": "stats"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '3 days', NOW() - INTERVAL '15 minutes'),

-- IoT devices
(gen_random_uuid(), '192.168.1.100'::inet, '00:1A:2B:3C:4D:64', 'printer-01.local', 'printer', 'online',
 'HP', 'Embedded Linux', 'v1.0', ARRAY[80, 631, 9100],
 '{"80": {"name": "http"}, "631": {"name": "ipp"}, "9100": {"name": "jetdirect"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '3 days', NOW() - INTERVAL '1 hour'),

(gen_random_uuid(), '192.168.1.150'::inet, '00:1A:2B:3C:4D:67', 'cctv-entrance.local', 'iot', 'online',
 'Hikvision', 'Embedded', 'v2.4', ARRAY[80, 554],
 '{"80": {"name": "http"}, "554": {"name": "rtsp"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 hours'),

-- Workstations
(gen_random_uuid(), '192.168.1.50'::inet, '00:1A:2B:3C:4D:63', 'dev-ws-01.local', 'workstation', 'online',
 'Intel Corporation', 'Windows', '11 Pro', ARRAY[135, 139, 445],
 '{"135": {"name": "msrpc"}, "139": {"name": "netbios-ssn"}, "445": {"name": "microsoft-ds"}}'::jsonb,
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '3 days', NOW() - INTERVAL '30 minutes'),

(gen_random_uuid(), '192.168.1.51'::inet, '00:1A:2B:3C:4D:69', 'admin-laptop.local', 'workstation', 'online',
 'Apple Inc.', 'macOS', '14.0 Sonoma', ARRAY[88, 445, 548],
 '{"88": {"name": "kerberos"}, "445": {"name": "microsoft-ds"}, "548": {"name": "afp"}}'::jsonb,
 NOW() - INTERVAL '2 days', NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '2 days', NOW() - INTERVAL '45 minutes');

-- ============================================================================
-- NETWORK_LINKS (Collegamenti tra dispositivi - topologia star)
-- ============================================================================
-- Gateway (firewall) come hub centrale
INSERT INTO network_links (id, source_device_id, target_device_id, link_type, latency_ms, hop_count, created_at)
SELECT
    gen_random_uuid(),
    (SELECT id FROM network_devices WHERE hostname = 'firewall-01.local'),
    nd.id,
    'gateway',
    (RANDOM() * 10 + 1)::numeric(10,2),
    1,
    NOW() - INTERVAL '3 days'
FROM network_devices nd
WHERE nd.hostname != 'firewall-01.local'
LIMIT 11;

-- Switch collegato al firewall
INSERT INTO network_links (id, source_device_id, target_device_id, link_type, latency_ms, hop_count, created_at)
VALUES
(gen_random_uuid(),
 (SELECT id FROM network_devices WHERE hostname = 'firewall-01.local'),
 (SELECT id FROM network_devices WHERE hostname = 'switch-core-01.local'),
 'trunk',
 0.5,
 1,
 NOW() - INTERVAL '3 days');

-- ============================================================================
-- PLUGINS (4 plugin di esempio)
-- ============================================================================
INSERT INTO plugins (id, name, version, description, author, plugin_type, config, is_enabled,
                     file_path, installed_at, updated_at)
VALUES
(gen_random_uuid(), 'Nessus Importer', '1.2.0',
 'Import vulnerabilities from Tenable Nessus XML export files',
 'SentinelCore Team', 'import',
 '{"api_endpoint": "https://nessus.example.com", "auto_import": true, "scan_interval": 3600}'::jsonb,
 true, '/plugins/nessus_importer.so', NOW() - INTERVAL '6 months', NOW() - INTERVAL '1 month'),

(gen_random_uuid(), 'Slack Notifier', '2.0.1',
 'Send notifications to Slack channels for critical vulnerabilities',
 'SentinelCore Team', 'notification',
 '{"default_channel": "#security-alerts", "mention_users": ["@security-team"], "severity_threshold": "high"}'::jsonb,
 true, '/plugins/slack_notifier.so', NOW() - INTERVAL '5 months', NOW() - INTERVAL '2 weeks'),

(gen_random_uuid(), 'PDF Report Generator', '1.5.3',
 'Generate professional PDF reports with charts and statistics',
 'SentinelCore Team', 'export',
 '{"template": "corporate", "include_graphs": true, "page_size": "A4"}'::jsonb,
 true, '/plugins/pdf_generator.so', NOW() - INTERVAL '4 months', NOW() - INTERVAL '1 week'),

(gen_random_uuid(), 'CVSS Calculator', '1.0.0',
 'Calculate CVSS scores and EPSS probability for vulnerabilities',
 'Community', 'analysis',
 '{"cvss_version": "3.1", "auto_calculate": true}'::jsonb,
 false, '/plugins/cvss_calculator.so', NOW() - INTERVAL '2 months', NOW());

-- ============================================================================
-- REPORTS (5 report generati)
-- ============================================================================
INSERT INTO reports (id, name, report_type, export_format, status, file_path, filters,
                     generated_by, generated_at, created_at)
VALUES
(gen_random_uuid(), 'Monthly Security Report - November 2024', 'scan', 'pdf', 'completed',
 '/reports/monthly-nov-2024.pdf', '{"date_range": "2024-11-01 to 2024-11-30", "severity": ["critical", "high"]}'::jsonb,
 '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), 'Critical Vulnerabilities Export', 'manual', 'csv', 'completed',
 '/reports/critical-vulns-export.csv', '{"severity": "critical", "status": "open"}'::jsonb,
 '22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

(gen_random_uuid(), 'Executive Summary Q4 2024', 'export', 'pdf', 'completed',
 '/reports/executive-summary-q4-2024.pdf', '{"quarter": "Q4-2024", "include_trends": true}'::jsonb,
 '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '1 week', NOW() - INTERVAL '1 week'),

(gen_random_uuid(), 'Compliance Audit Report', 'scan', 'xml', 'completed',
 '/reports/compliance-audit-2024.xml', '{"standards": ["ISO27001", "GDPR"]}'::jsonb,
 '11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '2 weeks', NOW() - INTERVAL '2 weeks'),

(gen_random_uuid(), 'Network Topology Scan Results', 'scan', 'json', 'processing',
 NULL, '{"scan_id": "ns111111-1111-1111-1111-111111111111"}'::jsonb,
 '22222222-2222-2222-2222-222222222222', NULL, NOW() - INTERVAL '1 hour');

-- ============================================================================
-- IP_WHITELIST (3 IP whitelisted)
-- ============================================================================
INSERT INTO ip_whitelist (id, ip_address, subnet_mask, description, is_enabled,
                          added_by, expires_at, created_at, updated_at)
VALUES
(gen_random_uuid(), '192.168.1.0', 24, 'Internal Office Network', true,
 '11111111-1111-1111-1111-111111111111', NULL, NOW() - INTERVAL '1 year', NOW()),

(gen_random_uuid(), '10.0.0.0', 8, 'VPN Network Range', true,
 '11111111-1111-1111-1111-111111111111', NULL, NOW() - INTERVAL '6 months', NOW()),

(gen_random_uuid(), '203.0.113.50', 32, 'External Security Auditor', true,
 '11111111-1111-1111-1111-111111111111', NOW() + INTERVAL '30 days', NOW() - INTERVAL '10 days', NOW());

-- ============================================================================
-- USER_PERMISSIONS (Permessi granulari specifici)
-- ============================================================================
INSERT INTO user_permissions (id, user_id, resource_type, resource_id, permission, granted_by,
                              expires_at, reason, created_at)
VALUES
(gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 'vulnerability',
 'v1111111-1111-1111-1111-111111111111', 'write',
 '11111111-1111-1111-1111-111111111111', NOW() + INTERVAL '7 days',
 'Temporary permission to manage critical SQL injection vulnerability',
 NOW() - INTERVAL '2 days'),

(gen_random_uuid(), '55555555-5555-5555-5555-555555555555', 'asset',
 'as777777-7777-7777-7777-777777777777', 'read',
 '22222222-2222-2222-2222-222222222222', NULL,
 'Permission to view printer asset for documentation',
 NOW() - INTERVAL '1 week');

-- ============================================================================
-- NOTIFICATIONS (6 notifiche)
-- ============================================================================
INSERT INTO notifications (id, user_id, type, channel, recipient, subject, body, status,
                           error_message, sent_at, created_at)
VALUES
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'new_vulnerability', 'email',
 'admin@sentinelcore.com', 'New Critical Vulnerability Detected',
 'A new critical SQL injection vulnerability was detected on web-prod-01.local',
 'sent', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'assignment', 'email',
 'john.doe@sentinelcore.com', 'Vulnerability Assigned to Your Team',
 'CVE-2024-5678 has been assigned to your team for remediation',
 'sent', NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'system_alert', 'slack',
 '#security-alerts', 'Critical System Alert',
 'Database server is accessible without authentication', 'sent', NULL,
 NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),

(gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 'report_ready', 'email',
 'alice.smith@sentinelcore.com', 'Your Security Report is Ready',
 'Monthly Security Report - November 2024 is available for download',
 'sent', NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'status_change', 'email',
 'john.doe@sentinelcore.com', 'Vulnerability Status Changed',
 'Privilege Escalation vulnerability has been marked as resolved',
 'sent', NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), '44444444-4444-4444-4444-444444444444', 'new_vulnerability', 'telegram',
 '123456789', 'New High Severity Vulnerability',
 'Weak firewall rules detected on firewall-01.local', 'pending', NULL,
 NULL, NOW() - INTERVAL '6 hours');

-- ============================================================================
-- AUDIT_LOGS (10 log di audit)
-- ============================================================================
INSERT INTO audit_logs (id, user_id, action, entity_type, entity_id, old_values, new_values,
                        ip_address, user_agent, created_at)
VALUES
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'create', 'vulnerability',
 'v1111111-1111-1111-1111-111111111111',
 NULL,
 '{"title": "SQL Injection in Login Form", "severity": "critical"}'::jsonb,
 '192.168.1.100', 'Mozilla/5.0', NOW() - INTERVAL '2 days'),

(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'update', 'vulnerability',
 'v2222222-2222-2222-2222-222222222222',
 '{"status": "open"}'::jsonb,
 '{"status": "in_progress"}'::jsonb,
 '192.168.1.101', 'Mozilla/5.0', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'update', 'vulnerability',
 'v4444444-4444-4444-4444-444444444444',
 '{"status": "in_progress"}'::jsonb,
 '{"status": "resolved"}'::jsonb,
 '192.168.1.100', 'Mozilla/5.0', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'create', 'user',
 '55555555-5555-5555-5555-555555555555',
 NULL,
 '{"username": "cdavis", "role": "user"}'::jsonb,
 '192.168.1.100', 'Mozilla/5.0', NOW() - INTERVAL '1 month'),

(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'create', 'team',
 't4444444-4444-4444-4444-444444444444',
 NULL,
 '{"name": "Application Security"}'::jsonb,
 '192.168.1.101', 'Mozilla/5.0', NOW() - INTERVAL '3 months'),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'create', 'asset',
 'as888888-8888-8888-8888-888888888888',
 NULL,
 '{"name": "Cloud VM - API Gateway", "type": "cloud"}'::jsonb,
 '192.168.1.100', 'Mozilla/5.0', NOW() - INTERVAL '6 months'),

(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'update', 'asset',
 'as111111-1111-1111-1111-111111111111',
 '{"tags": ["production", "web"]}'::jsonb,
 '{"tags": ["production", "web", "nginx", "critical"]}'::jsonb,
 '192.168.1.101', 'Mozilla/5.0', NOW() - INTERVAL '1 week'),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'delete', 'user',
 '66666666-6666-6666-6666-666666666666',
 '{"username": "old_user", "role": "user"}'::jsonb,
 NULL,
 '192.168.1.100', 'Mozilla/5.0', NOW() - INTERVAL '2 months'),

(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'create', 'report',
 (SELECT id::text FROM reports WHERE name = 'Monthly Security Report - November 2024'),
 NULL,
 '{"name": "Monthly Security Report - November 2024", "format": "pdf"}'::jsonb,
 '192.168.1.101', 'Mozilla/5.0', NOW() - INTERVAL '1 day'),

(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'update', 'team',
 't1111111-1111-1111-1111-111111111111',
 '{"slack_webhook": null}'::jsonb,
 '{"slack_webhook": "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"}'::jsonb,
 '192.168.1.100', 'Mozilla/5.0', NOW() - INTERVAL '3 weeks');

-- ============================================================================
-- REMEDIATION_TASKS (3 task di remediation)
-- ============================================================================
INSERT INTO remediation_tasks (id, vulnerability_id, device_id, script_name, script_content, status,
                               scheduled_at, executed_at, output, error, created_at, updated_at)
VALUES
(gen_random_uuid(), 'v2222222-2222-2222-2222-222222222222',
 (SELECT id FROM network_devices WHERE hostname = 'app-prod-01.local'),
 'update_apache_struts.sh',
 E'#!/bin/bash\napt-get update\napt-get install -y apache-struts=2.5.33\nsystemctl restart tomcat',
 'pending', NOW() + INTERVAL '2 hours', NULL, NULL, NULL, NOW(), NOW()),

(gen_random_uuid(), 'v6666666-6666-6666-6666-666666666666',
 (SELECT id FROM network_devices WHERE hostname = 'web-prod-01.local'),
 'update_ssl_config.sh',
 E'#!/bin/bash\nsed -i "s/TLSv1.0/TLSv1.2/g" /etc/nginx/nginx.conf\nnginx -t && systemctl reload nginx',
 'completed', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '5 minutes',
 'Configuration file test successful\nnginx reloaded successfully', NULL,
 NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '5 minutes'),

(gen_random_uuid(), 'v7777777-7777-7777-7777-777777777777',
 (SELECT id FROM network_devices WHERE hostname = 'printer-01.local'),
 'change_printer_password.sh',
 E'#!/bin/bash\ncurl -X POST http://192.168.1.100/admin/password -d "new_password=SecureP@ss123"',
 'failed', NOW() - INTERVAL '1 week', NOW() - INTERVAL '1 week' + INTERVAL '30 seconds',
 NULL, 'Connection timeout: printer not responding', NOW() - INTERVAL '1 week', NOW() - INTERVAL '1 week' + INTERVAL '30 seconds');

COMMIT;

-- Visualizza statistiche dati inseriti
SELECT
    'Users' as table_name, COUNT(*) as records FROM users
UNION ALL SELECT 'Teams', COUNT(*) FROM teams
UNION ALL SELECT 'Assets', COUNT(*) FROM assets
UNION ALL SELECT 'Vulnerabilities', COUNT(*) FROM vulnerabilities
UNION ALL SELECT 'Network Devices', COUNT(*) FROM network_devices
UNION ALL SELECT 'Network Links', COUNT(*) FROM network_links
UNION ALL SELECT 'Network Scans', COUNT(*) FROM network_scans
UNION ALL SELECT 'Reports', COUNT(*) FROM reports
UNION ALL SELECT 'Plugins', COUNT(*) FROM plugins
UNION ALL SELECT 'Notifications', COUNT(*) FROM notifications
UNION ALL SELECT 'Audit Logs', COUNT(*) FROM audit_logs
UNION ALL SELECT 'Remediation Tasks', COUNT(*) FROM remediation_tasks
ORDER BY table_name;

-- Mostra le password per i test
\echo '========================================='
\echo 'TEST CREDENTIALS'
\echo '========================================='
\echo 'Username: admin    | Password: Admin123!'
\echo 'Username: jdoe     | Password: User123!'
\echo 'Username: asmith   | Password: User123!'
\echo 'Username: bjones   | Password: User123!'
\echo 'Username: cdavis   | Password: User123!'
\echo '========================================='
