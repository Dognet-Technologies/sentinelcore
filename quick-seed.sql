-- Quick seed data for testing

-- Insert a test team
INSERT INTO teams (id, name, description) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID, 'Security Team', 'Primary security team')
ON CONFLICT (id) DO NOTHING;

-- Insert test assets
INSERT INTO assets (id, name, asset_type, ip_address, hostname) VALUES
('00000001-0001-0001-0001-000000000001'::UUID, 'web-server-01', 'server', '192.168.1.100', 'web01.company.com'),
('00000002-0002-0002-0002-000000000002'::UUID, 'db-server-01', 'server', '192.168.1.101', 'db01.company.com'),
('00000003-0003-0003-0003-000000000003'::UUID, 'app-server-01', 'server', '192.168.1.102', 'app01.company.com')
ON CONFLICT (id) DO NOTHING;

-- Insert test vulnerabilities
INSERT INTO vulnerabilities (
    id, title, description, cvss_score, severity, status, ip_address,
    hostname, source, asset_id, assigned_team_id, discovered_at
) VALUES
('10000001-0001-0001-0001-000000000001'::UUID,
 'SQL Injection in Login Form',
 'The login form is vulnerable to SQL injection attacks',
 9.8, 'critical', 'open', '192.168.1.100',
 'web01.company.com', 'manual',
 '00000001-0001-0001-0001-000000000001'::UUID,
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
 NOW() - INTERVAL '5 days'),

('10000002-0002-0002-0002-000000000002'::UUID,
 'XSS Vulnerability',
 'Cross-site scripting vulnerability in user profile page',
 7.5, 'high', 'in_progress', '192.168.1.100',
 'web01.company.com', 'automated',
 '00000001-0001-0001-0001-000000000001'::UUID,
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
 NOW() - INTERVAL '3 days'),

('10000003-0003-0003-0003-000000000003'::UUID,
 'Outdated SSL/TLS Protocol',
 'Server supports outdated SSL/TLS protocols',
 5.3, 'medium', 'open', '192.168.1.100',
 'web01.company.com', 'automated',
 '00000001-0001-0001-0001-000000000001'::UUID,
 NULL,
 NOW() - INTERVAL '10 days'),

('10000004-0004-0004-0004-000000000004'::UUID,
 'Weak Database Password',
 'Database using weak default password',
 8.8, 'critical', 'open', '192.168.1.101',
 'db01.company.com', 'manual',
 '00000002-0002-0002-0002-000000000002'::UUID,
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
 NOW() - INTERVAL '2 days'),

('10000005-0005-0005-0005-000000000005'::UUID,
 'Missing Security Headers',
 'Important security headers are not configured',
 4.3, 'medium', 'resolved', '192.168.1.102',
 'app01.company.com', 'automated',
 '00000003-0003-0003-0003-000000000003'::UUID,
 NULL,
 NOW() - INTERVAL '15 days'),

('10000006-0006-0006-0006-000000000006'::UUID,
 'Unpatched Software',
 'Operating system has critical unpatched vulnerabilities',
 9.1, 'critical', 'open', '192.168.1.101',
 'db01.company.com', 'automated',
 '00000002-0002-0002-0002-000000000002'::UUID,
 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
 NOW() - INTERVAL '1 day')

ON CONFLICT (id) DO NOTHING;

SELECT 'Seed data inserted successfully!' as message;
