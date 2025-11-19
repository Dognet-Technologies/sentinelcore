#!/usr/bin/env python3
import os
import re

def fix_report_handler():
    """Fix report.rs syntax error"""
    filepath = "src/handlers/report.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix the missing comma
    content = content.replace(
        "    Json\n    Extension,",
        "    Json,\n    Extension,"
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print("✓ Fixed report.rs syntax")

def fix_user_handler():
    """Fix user.rs get_current_user function"""
    filepath = "src/handlers/user.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix the get_user call in get_current_user
    content = re.sub(
        r'get_user\(State\(state\), Path\(user_id\)\)\.await',
        'get_user(Extension(pool), Path(user_id)).await',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print("✓ Fixed user.rs")

def fix_plugins_mod():
    """Fix plugins/mod.rs"""
    filepath = "src/plugins/mod.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Add HashMap import
    if 'use std::collections::HashMap;' not in content:
        content = "use std::collections::HashMap;\n" + content
    
    # Fix the new function to match the struct
    content = re.sub(
        r'plugins: RwLock::new\(HashMap::new\(\)\),\s*directory: config\.directory,',
        'config,',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print("✓ Fixed plugins/mod.rs")

def fix_main_rs():
    """Fix main.rs"""
    filepath = "src/main.rs"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix plugin manager initialization
    content = re.sub(
        r'let plugin_manager = Arc::new\(PluginManager::new\(&config\.plugins\.directory\)\);',
        'let plugin_manager = Arc::new(PluginManager::new(config.plugins.clone()));',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    print("✓ Fixed main.rs")

def remove_unused_imports():
    """Remove unused imports from all handlers"""
    handlers = [
        "src/handlers/vulnerability.rs",
        "src/handlers/team.rs", 
        "src/handlers/asset.rs",
        "src/handlers/report.rs",
        "src/handlers/plugin.rs"
    ]
    
    for filepath in handlers:
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Remove unused State import when using Extension
            if 'Extension(' in content and ', State,' in content:
                content = content.replace(', State,', ',')
                content = content.replace(', State}', '}')
            
            with open(filepath, 'w') as f:
                f.write(content)
    
    print("✓ Cleaned unused imports")

def main():
    print("Applying final fixes...\n")
    
    fix_report_handler()
    fix_user_handler()
    fix_plugins_mod()
    fix_main_rs()
    remove_unused_imports()
    
    print("\n✅ All fixes applied!")
    print("\nNext steps:")
    print("1. Make sure PostgreSQL is running")
    print("2. Make sure the database 'vulnerability_manager' exists")
    print("3. Run: cargo check")

if __name__ == "__main__":
    main()