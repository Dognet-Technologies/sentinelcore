#!/usr/bin/env python3
import os
import re
import sys

def revert_handler_file(filepath):
    """Ripristina handler per usare Extension invece di AppState"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Rimuovi AppState e aggiungi Extension
    content = re.sub(
        r'use crate::api::AppState;\s*\n',
        '',
        content
    )
    
    # Aggiungi Extension agli import axum se non presente
    if 'Extension' not in content and 'State(state)' in content:
        # Trova import axum esistente
        axum_import = re.search(r'use axum::\{([^}]+)\}', content)
        if axum_import:
            imports = axum_import.group(1)
            if 'Extension' not in imports:
                new_imports = imports.rstrip() + ', Extension'
                content = content.replace(
                    f'use axum::{{{imports}}}',
                    f'use axum::{{{new_imports}}}'
                )
    
    # 2. Sostituisci State(state): State<AppState> con Extension
    # Per pool
    content = re.sub(
        r'State\(state\):\s*State<AppState>',
        'Extension(pool): Extension<Arc<PgPool>>',
        content
    )
    
    # 3. Aggiungi Extension per auth dove necessario
    # Cerca funzioni che usano state.auth
    if 'state.auth.' in content:
        # Trova le funzioni che usano auth
        functions = re.findall(r'pub async fn (\w+)[^{]+\{[^}]+state\.auth\.[^}]+\}', content, re.DOTALL)
        for func in functions:
            # Aggiungi Extension(auth) dopo Extension(pool)
            pattern = rf'(pub async fn {func}[^{{]+Extension\(pool\): Extension<Arc<PgPool>>)'
            replacement = r'\1,\n    Extension(auth): Extension<Arc<Auth>>'
            content = re.sub(pattern, replacement, content)
    
    # 4. Sostituisci state.pool con pool
    content = re.sub(r'&\*state\.pool\b', '&*pool', content)
    
    # 5. Sostituisci state.auth con auth
    content = re.sub(r'state\.auth\.', 'auth.', content)
    
    # 6. Aggiungi imports necessari
    if '&*pool' in content and 'use sqlx::PgPool;' not in content:
        # Aggiungi dopo gli import axum
        axum_import_match = re.search(r'(use axum::[^;]+;\s*\n)', content)
        if axum_import_match:
            insert_pos = axum_import_match.end()
            content = content[:insert_pos] + "use sqlx::PgPool;\nuse std::sync::Arc;\n" + content[insert_pos:]
    
    # 7. Assicurati che Auth sia importato se necessario
    if 'auth.' in content and 'Auth' not in content:
        if 'use crate::auth::Claims;' in content:
            content = content.replace(
                'use crate::auth::Claims;',
                'use crate::auth::{Auth, Claims};'
            )
        else:
            # Aggiungi import
            content = re.sub(
                r'(use std::sync::Arc;\s*\n)',
                r'\1use crate::auth::Auth;\n',
                content
            )
    
    # Salva solo se ci sono modifiche
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"✓ Reverted: {filepath}")
        return True
    else:
        print(f"  No changes needed: {filepath}")
        return False

def main():
    handlers_dir = "src/handlers"
    
    if not os.path.exists(handlers_dir):
        print(f"Error: Directory {handlers_dir} not found!")
        sys.exit(1)
    
    print("Reverting handler files to use Extension...\n")
    
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
            if revert_handler_file(filepath):
                fixed_count += 1
    
    print(f"\n✅ Reverted {fixed_count} files")

if __name__ == "__main__":
    main()