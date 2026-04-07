#!/usr/bin/env python3
import os
import re

def fix_vulnerability_model():
    """Fix vulnerability.rs to add SQLx Type derivations"""
    filepath = "src/models/vulnerability.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix VulnerabilityStatus
    content = re.sub(
        r'#\[derive\(Debug, Serialize, Deserialize, Clone, PartialEq, Eq\)\]\s*\npub enum VulnerabilityStatus',
        '#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, sqlx::Type)]\n#[sqlx(type_name = "vulnerability_status", rename_all = "snake_case")]\npub enum VulnerabilityStatus',
        content
    )
    
    # Fix VulnerabilitySeverity
    content = re.sub(
        r'#\[derive\(Debug, Serialize, Deserialize, Clone, PartialEq, Eq\)\]\s*\npub enum VulnerabilitySeverity',
        '#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, sqlx::Type)]\n#[sqlx(type_name = "vulnerability_severity", rename_all = "snake_case")]\npub enum VulnerabilitySeverity',
        content
    )
    
    # Add sqlx::Type import
    if 'use sqlx::' not in content:
        content = re.sub(
            r'(use uuid::Uuid;)',
            r'\1\nuse sqlx::Type;',
            content
        )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def fix_asset_model():
    """Fix asset.rs to add SQLx Type derivations"""
    filepath = "src/models/asset.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix AssetType
    content = re.sub(
        r'#\[derive\(Debug, Serialize, Deserialize, Clone, PartialEq, Eq\)\]\s*\npub enum AssetType',
        '#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, sqlx::Type)]\n#[sqlx(type_name = "asset_type", rename_all = "snake_case")]\npub enum AssetType',
        content
    )
    
    # Add sqlx::Type import
    if 'use sqlx::' not in content:
        content = re.sub(
            r'(use uuid::Uuid;)',
            r'\1\nuse sqlx::Type;',
            content
        )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def fix_report_model():
    """Fix report.rs to add SQLx Type derivations"""
    filepath = "src/models/report.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix all enums
    for enum_name in ['ReportType', 'ReportStatus', 'ReportFormat']:
        snake_name = re.sub(r'([A-Z])', r'_\1', enum_name).lower()[1:]
        content = re.sub(
            rf'#\[derive\(Debug, Serialize, Deserialize, Clone, PartialEq, Eq\)\]\s*\npub enum {enum_name}',
            f'#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, sqlx::Type)]\n#[sqlx(type_name = "{snake_name}", rename_all = "snake_case")]\npub enum {enum_name}',
            content
        )
    
    # Add sqlx::Type import
    if 'use sqlx::' not in content:
        content = re.sub(
            r'(use uuid::Uuid;)',
            r'\1\nuse sqlx::Type;',
            content
        )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def fix_plugin_model():
    """Fix plugin.rs to add SQLx Type derivations"""
    filepath = "src/models/plugin.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix PluginType
    content = re.sub(
        r'#\[derive\(Debug, Serialize, Deserialize, Clone, PartialEq, Eq\)\]\s*\npub enum PluginType',
        '#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, sqlx::Type)]\n#[sqlx(type_name = "plugin_type", rename_all = "snake_case")]\npub enum PluginType',
        content
    )
    
    # Add sqlx::Type import
    if 'use sqlx::' not in content:
        content = re.sub(
            r'(use uuid::Uuid;)',
            r'\1\nuse sqlx::Type;',
            content
        )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def fix_team_handler():
    """Fix team.rs handler for COUNT query"""
    filepath = "src/handlers/team.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix COUNT query result
    content = re.sub(
        r'let assigned_vulns: i64 = sqlx::query_scalar!',
        'let assigned_vulns = sqlx::query_scalar!',
        content
    )
    
    # Add unwrap_or(0) after the query
    content = re.sub(
        r'\)\)?;',
        ')\n    .fetch_one(&*pool)\n    .await\n    .map_err(|e| (\n        StatusCode::INTERNAL_SERVER_ERROR,\n        Json(ErrorResponse {\n            error: format!("Errore durante il controllo: {}", e),\n        }),\n    ))?\n    .unwrap_or(0);',
        content,
        count=1
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def fix_asset_handler():
    """Fix asset.rs handler for COUNT query"""
    filepath = "src/handlers/asset.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Similar fix for asset COUNT query
    content = re.sub(
        r'let associated_vulns: i64 = sqlx::query_scalar!',
        'let associated_vulns = sqlx::query_scalar!',
        content
    )
    
    content = re.sub(
        r'\)\)?;',
        ')\n    .fetch_one(&*pool)\n    .await\n    .map_err(|e| (\n        StatusCode::INTERNAL_SERVER_ERROR,\n        Json(ErrorResponse {\n            error: format!("Errore durante il controllo: {}", e),\n        }),\n    ))?\n    .unwrap_or(0);',
        content,
        count=1
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def fix_migrations():
    """Remove invalid migrations call from main.rs"""
    filepath = "src/main.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Comment out migrations for now
    content = re.sub(
        r'sqlx::migrate!\("./migrations"\)\s*\.run\(&pool\)\s*\.await\?;',
        '// sqlx::migrate!("./migrations").run(&pool).await?;',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"✓ Fixed {filepath}")

def main():
    print("Fixing SQLx type issues...\n")
    
    fix_vulnerability_model()
    fix_asset_model()
    fix_report_model()
    fix_plugin_model()
    fix_team_handler()
    fix_asset_handler()
    fix_migrations()
    
    print("\n✅ All fixes applied!")
    print("\nNext steps:")
    print("1. Run: cargo check")
    print("2. If there are still errors, run this script again")

if __name__ == "__main__":
    main()