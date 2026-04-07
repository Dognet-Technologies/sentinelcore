#!/bin/bash

set -e

echo "🚀 SentinelCore Deployment Script"
echo "=================================="
echo ""

DEPLOYMENT_ENV=${1:-staging}
echo "📍 Deployment Environment: $DEPLOYMENT_ENV"
echo ""

if [ -z "$DATABASE_URL" ]; then
    echo "❌ ERROR: DATABASE_URL environment variable not set"
    echo "Usage: DATABASE_URL=postgres://... ./deploy.sh [staging|production]"
    exit 1
fi

PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
echo "📁 Project Root: $PROJECT_ROOT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Database Migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_ROOT/vulnerability-manager"

if ! command -v sqlx &> /dev/null; then
    echo "⚠️  sqlx CLI not found, installing..."
    cargo install sqlx-cli --no-default-features --features postgres
fi

echo "Running database migrations..."
if sqlx migrate run --database-url "$DATABASE_URL"; then
    echo "✅ Database migrations completed successfully"
else
    echo "❌ Database migration failed"
    exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Backend Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Building backend in release mode..."
if cargo build --release; then
    echo "✅ Backend build completed successfully"
    BACKEND_BINARY="$PROJECT_ROOT/vulnerability-manager/target/release/vulnerability-manager"
    echo "📦 Binary ready: $BACKEND_BINARY"
else
    echo "❌ Backend build failed"
    exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Frontend Build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_ROOT/vulnerability-manager-frontend"

echo "Building frontend..."
if npm run build; then
    echo "✅ Frontend build completed successfully"
    echo "📦 Build artifacts ready: $PROJECT_ROOT/vulnerability-manager-frontend/build"
else
    echo "❌ Frontend build failed"
    exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Running data integrity checks..."
cd "$PROJECT_ROOT/vulnerability-manager"

TEMP_CHECK=$(mktemp)
if psql "$DATABASE_URL" -f "$PROJECT_ROOT/vulnerability-manager/data-integrity-checks.sql" > "$TEMP_CHECK" 2>&1; then
    ISSUE_COUNT=$(grep -c "issue_count" "$TEMP_CHECK" || echo "0")
    if [ "$ISSUE_COUNT" -eq 0 ]; then
        echo "✅ Data integrity check passed"
    else
        echo "⚠️  Data integrity check found issues (review required)"
        grep "issue_count" "$TEMP_CHECK" || true
    fi
else
    echo "⚠️  Could not run data integrity check (non-critical)"
fi
rm -f "$TEMP_CHECK"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOYMENT READY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Next Steps:"
echo ""
echo "1. Backend deployment:"
echo "   $BACKEND_BINARY"
echo ""
echo "2. Frontend deployment (serve from):"
echo "   $PROJECT_ROOT/vulnerability-manager-frontend/build"
echo ""
echo "3. Environment variables needed:"
echo "   - DATABASE_URL=$DATABASE_URL"
echo "   - RUST_LOG=debug"
echo "   - (other app-specific vars)"
echo ""
echo "4. Smoke tests to run after deployment:"
echo "   - Test soft delete filtering"
echo "   - Test asset validation"
echo "   - Test cascading deletes"
echo "   - Test soft-deleted record protection"
echo ""
echo "📖 See DEPLOYMENT_CHECKLIST.md for full post-deployment verification"
echo ""

exit 0
