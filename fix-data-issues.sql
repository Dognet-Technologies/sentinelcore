-- Fix Data Integrity Issues
-- Addresses problems found by validation tests

-- 1. Fix Severity-CVSS Mismatch
-- Vulnerability "Weak Database Password" has CVSS 8.8 but severity "critical"
-- CVSS 8.8 should be "high" (critical requires >= 9.0)

UPDATE vulnerabilities
SET severity = 'high'
WHERE id = '10000004-0004-0004-0004-000000000004'::UUID
  AND cvss_score = 8.8
  AND severity = 'critical';

SELECT 'Fixed severity for vulnerability with CVSS 8.8' as fix_1;

-- 2. Update Asset Vulnerability Counts
-- Create a function to recalculate and update all asset vulnerability counts

CREATE OR REPLACE FUNCTION update_asset_vulnerability_counts()
RETURNS void AS $$
BEGIN
    UPDATE assets
    SET vulnerability_count = (
        SELECT COUNT(*)
        FROM vulnerabilities
        WHERE vulnerabilities.asset_id = assets.id
          AND vulnerabilities.deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql;

-- Execute the function to fix all counts
SELECT update_asset_vulnerability_counts();

SELECT 'Updated all asset vulnerability counts' as fix_2;

-- 3. Verify the fixes
SELECT
    'Verification: Vulnerabilities with mismatched severity' as check_type,
    COUNT(*) as count
FROM vulnerabilities
WHERE (cvss_score >= 9.0 AND severity != 'critical')
   OR (cvss_score >= 7.0 AND cvss_score < 9.0 AND severity != 'high')
   OR (cvss_score >= 4.0 AND cvss_score < 7.0 AND severity != 'medium')
   OR (cvss_score > 0.0 AND cvss_score < 4.0 AND severity != 'low')
   OR (cvss_score = 0.0 AND severity != 'info');

SELECT
    'Verification: Assets with incorrect counts' as check_type,
    COUNT(*) as count
FROM assets a
WHERE (
    SELECT COUNT(*)
    FROM vulnerabilities v
    WHERE v.asset_id = a.id
      AND v.deleted_at IS NULL
) != COALESCE(a.vulnerability_count, 0);

-- Show updated asset counts
SELECT
    a.id,
    a.name,
    a.vulnerability_count as reported_count,
    COUNT(v.id) as actual_count
FROM assets a
LEFT JOIN vulnerabilities v ON v.asset_id = a.id AND v.deleted_at IS NULL
GROUP BY a.id, a.name, a.vulnerability_count
ORDER BY a.name;
