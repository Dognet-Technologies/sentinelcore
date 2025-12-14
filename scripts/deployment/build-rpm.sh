#!/usr/bin/env bash
set -euo pipefail

# Wrapper to create an RPM package for SentinelCore using fpm (recommended) or instructions for native rpmbuild.
PKG_NAME="sentinelcore"
VERSION="1.0.0"
ARCH="x86_64"
BUILD_DIR="/tmp/${PKG_NAME}-${VERSION}-rpm"

echo "📦 Preparing packaging layout in ${BUILD_DIR}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Reuse the layout created by build-deb.sh: run it but copy the BUILD_DIR
# Run build-deb.sh to populate /tmp/sentinelcore-<version> or adjust as needed
if [[ -x scripts/deployment/build-deb.sh ]]; then
  echo "🔁 Running build-deb.sh to prepare files (will create /tmp/sentinelcore_1.0.0_amd64.deb and staging)"
  scripts/deployment/build-deb.sh
fi

# If a staging dir exists from build-deb.sh, use it; otherwise instruct the user
STAGING_DIR="/tmp/${PKG_NAME}-${VERSION}"
if [[ ! -d "${STAGING_DIR}" ]]; then
  echo "⚠️  Staging directory ${STAGING_DIR} not found. Please run build-deb.sh or prepare the directory layout at ${STAGING_DIR}"
  exit 1
fi

# Ensure fpm available
if ! command -v fpm &> /dev/null; then
  echo "ℹ️  fpm not found. Trying to install via gem (requires ruby & gem)"
  if command -v gem &> /dev/null; then
    sudo gem install --no-document fpm || true
  else
    echo "Please install fpm (gem install fpm) or use native rpmbuild on an RPM host"
    exit 1
  fi
fi

echo "🔨 Building RPM with fpm..."
# Build RPM from directory
fpm -s dir -t rpm -n "${PKG_NAME}" -v "${VERSION}" --architecture "${ARCH}" \
  -C "${STAGING_DIR}" \
  --description "SentinelCore - Enterprise Vulnerability Management System" \
  --depends "postgresql >= 15" --depends "nginx" --depends "libpq" \
  opt/ etc/ var/

echo "✅ RPM build finished."