#!/bin/bash
# Script per rigenerare la cache SQLx dopo modifiche ai query
# Richiede PostgreSQL in esecuzione
# Usage: Run from repository root: scripts/deployment/regenerate-sqlx-cache.sh

set -e

# Determine script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔄 Regenerating SQLx query cache..."
echo "📁 Repository root: $REPO_ROOT"
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL not set, using default..."
    export DATABASE_URL="postgresql://vlnman:DogNET@localhost:5432/vulnerability_manager"
    echo "   Using: $DATABASE_URL"
    echo ""
fi

# Check if PostgreSQL is running
echo "🔍 Checking PostgreSQL connection..."
if ! psql "$DATABASE_URL" -c "SELECT 1" > /dev/null 2>&1; then
    echo ""
    echo "❌ Cannot connect to PostgreSQL!"
    echo ""
    echo "Please ensure PostgreSQL is running and accessible:"
    echo "   1. Start PostgreSQL: sudo systemctl start postgresql"
    echo "   2. Create database: psql -U postgres -c \"CREATE DATABASE vulnerability_manager;\""
    echo "   3. Create user: psql -U postgres -c \"CREATE USER vlnman WITH PASSWORD 'changeme';\""
    echo "   4. Grant privileges: psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;\""
    echo ""
    echo "Or set DATABASE_URL environment variable to your connection string."
    exit 1
fi

echo "✅ PostgreSQL connection successful"
echo ""

# Change to backend directory
cd "$REPO_ROOT/vulnerability-manager"

# Install sqlx-cli if needed
echo "📊 Checking sqlx-cli..."
if ! cargo install sqlx-cli --no-default-features --features postgres 2>/dev/null; then
    echo "⚠️  sqlx-cli already installed or installation failed, continuing..."
fi

# Create database if it doesn't exist
sqlx database create 2>/dev/null || echo "Database already exists"

# Check if migrations have been applied
echo "🔍 Checking migration status..."
if psql "$DATABASE_URL" -c "SELECT 1 FROM users LIMIT 1" > /dev/null 2>&1; then
    echo "⚠️  Database tables already exist (migrations likely applied manually)"
    echo "Skipping migration run to avoid conflicts."
    echo ""
    echo "If you need to reapply migrations, either:"
    echo "  1. Drop and recreate the database, or"
    echo "  2. Manually verify migration state with: sqlx migrate info"
    echo ""
else
    echo "Running database migrations..."
    if ! sqlx migrate run; then
        echo ""
        echo "❌ Migration failed!"
        echo ""
        echo "This usually means migrations were partially applied."
        echo "Check migration status with: sqlx migrate info"
        echo "Or reset database: dropdb vulnerability_manager && createdb vulnerability_manager"
        exit 1
    fi
    echo "✅ Migrations complete"
fi

echo ""

# Prepare queries (generate cache)
echo "🔧 Generating query cache..."
cargo sqlx prepare -- --lib

echo ""
echo "✅ SQLx cache regenerated successfully!"
echo ""
echo "📁 Cache files saved in: vulnerability-manager/.sqlx/"
echo "💡 Now you can run: scripts/deployment/build-deb.sh"
echo ""
echo "Don't forget to commit the updated .sqlx/ directory:"
echo "   git add vulnerability-manager/.sqlx/"
echo "   git commit -m \"chore: Update SQLx query cache\""
echo ""
