#!/usr/bin/env python3
import os
import re
import sys

def fix_handler_file(filepath):
    """Corregge un file handler per usare AppState invece di Arc<PgPool>"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Rimuovi import non necessari e aggiungi AppState
    content = re.sub(
        r'use sqlx::PgPool;\s*\n\s*use std::sync::Arc;\s*\n',
        '',
        content
    )
    
    # Aggiungi import AppState dopo le altre use statements di axum
    if 'use crate::api::AppState;' not in content:
        # Trova il posto giusto dopo gli import di axum
        axum_import_pattern = r'(use axum::[^;]+;\s*\n)'
        match = re.search(axum_import_pattern, content)
        if match:
            insert_pos = match.end()
            content = content[:insert_pos] + "use crate::api::AppState;\n" + content[insert_pos:]
    
    # 2. Sostituisci State<Arc<PgPool>> con State<AppState>
    content = re.sub(
        r'State\(pool\):\s*State<Arc<PgPool>>',
        'State(state): State<AppState>',
        content
    )
    
    # 3. Sostituisci State<Arc<Auth>> con accesso tramite state
    # Prima rimuovi il parametro State<Arc<Auth>> dalle funzioni
    content = re.sub(
        r',\s*State\(auth\):\s*State<Arc<Auth>>',
        '',
        content
    )
    
    # 4. Sostituisci &**pool o &*pool con &*state.pool
    content = re.sub(
        r'&\*\*?pool\b',
        '&*state.pool',
        content
    )
    
    # 5. Sostituisci auth. con state.auth.
    content = re.sub(
        r'\bauth\.',
        'state.auth.',
        content
    )
    
    # 6. Fix per handlers speciali che usano solo pool
    # Per funzioni che non hanno auth, sostituisci State(pool) con State(state)
    content = re.sub(
        r'State\(pool\):\s*State<[^>]+>',
        'State(state): State<AppState>',
        content
    )
    
    # 7. Rimuovi use crate::auth::Auth se presente e non più necessario
    if 'state.auth' in content and 'Auth;' in content:
        # Mantieni Auth solo se è usato per il tipo, non per state
        if not re.search(r'Auth[^;]*\{', content):  # Se Auth non è usato come tipo struct
            content = re.sub(r'use crate::auth::Auth;\s*\n', '', content)
    
    # 8. Fix per create_report che usa Claims
    if 'create_report' in content:
        # Aggiungi Extension import se necessario
        if 'Extension(' in content and 'use axum::Extension;' not in content:
            axum_import = re.search(r'(use axum::\{[^}]+)\}', content)
            if axum_import:
                imports = axum_import.group(1)
                if 'Extension' not in imports:
                    content = content.replace(
                        axum_import.group(0),
                        imports + ', Extension}'
                    )
    
    # 9. Gestisci i casi dove Claims è usato come parametro
    if 'claims: Claims' in content or 'Claims,' in content:
        # Assicurati che Claims sia importato
        if 'use crate::auth::Claims;' not in content and 'use crate::auth::{' not in content:
            # Aggiungi import Claims
            if 'use crate::auth::' in content:
                content = re.sub(
                    r'use crate::auth::([^;]+);',
                    r'use crate::auth::{Claims, \1};',
                    content
                )
            else:
                # Aggiungi dopo AppState import
                content = re.sub(
                    r'(use crate::api::AppState;\s*\n)',
                    r'\1use crate::auth::Claims;\n',
                    content
                )
    
    # Salva solo se ci sono modifiche
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"✓ Fixed: {filepath}")
        return True
    else:
        print(f"  No changes needed: {filepath}")
        return False

def fix_auth_handler(filepath):
    """Fix specifico per auth.rs che non usa AppState"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Per auth.rs manteniamo State<Arc<PgPool>>
    # Solo correggiamo &**pool in &*pool
    content = re.sub(r'&\*\*pool\b', '&*pool', content)
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"✓ Fixed: {filepath}")
        return True
    else:
        print(f"  No changes needed: {filepath}")
        return False

def main():
    handlers_dir = "src/handlers"
    
    if not os.path.exists(handlers_dir):
        print(f"Error: Directory {handlers_dir} not found!")
        print("Make sure you run this script from the project root directory.")
        sys.exit(1)
    
    print("Fixing handler files...\n")
    
    fixed_count = 0
    
    # Lista dei file handler da correggere
    handler_files = [
        "user.rs",
        "vulnerability.rs", 
        "team.rs",
        "asset.rs",
        "report.rs",
        "plugin.rs"
    ]
    
    # Correggi ogni handler
    for filename in handler_files:
        filepath = os.path.join(handlers_dir, filename)
        if os.path.exists(filepath):
            if fix_handler_file(filepath):
                fixed_count += 1
        else:
            print(f"⚠ Warning: {filepath} not found")
    
    # Fix speciale per auth.rs
    auth_filepath = os.path.join(handlers_dir, "auth.rs")
    if os.path.exists(auth_filepath):
        if fix_auth_handler(auth_filepath):
            fixed_count += 1
    
    print(f"\n✅ Fixed {fixed_count} files")
    
    # Crea anche il file handlers/mod.rs se non esiste
    mod_filepath = os.path.join(handlers_dir, "mod.rs")
    if not os.path.exists(mod_filepath):
        with open(mod_filepath, 'w') as f:
            f.write("""pub mod auth;
pub mod user;
pub mod vulnerability;
pub mod team;
pub mod asset;
pub mod report;
pub mod plugin;
""")
        print(f"✓ Created: {mod_filepath}")

if __name__ == "__main__":
    main()
