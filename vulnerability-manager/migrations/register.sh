#!/bin/bash
psql -U vlnman -d vulnerability_manager << 'EOF'
INSERT INTO _sqlx_migrations (version, description, installed_on, success, checksum, execution_time) VALUES
(13, 'risk_scoring_and_sla', NOW(), true, decode('', 'hex'), 0),
(14, 'comments_system', NOW(), true, decode('', 'hex'), 0),
(15, 'notification_routing', NOW(), true, decode('', 'hex'), 0),
(16, 'jira_integration', NOW(), true, decode('', 'hex'), 0),
(17, 'soar_webhooks', NOW(), true, decode('', 'hex'), 0),
(18, 'compliance_reports', NOW(), true, decode('', 'hex'), 0)
ON CONFLICT DO NOTHING;
EOF