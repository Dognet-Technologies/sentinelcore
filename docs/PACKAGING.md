# Packaging and distribution

This document explains how to build packages for Debian 12 (.deb), RHEL/CentOS/Fedora (.rpm) and a VMDK image using Packer. It also references the helper scripts in scripts/deployment.

Prerequisites (Debian build host):
- Debian 12 (bookworm) or a compatible environment
- Rust toolchain (rustup) and cargo
- Node.js 20 and npm
- PostgreSQL 15 (for SQLx offline cache generation)
- build-essential, pkg-config, libssl-dev, libpq-dev
- fpm (optional, used for RPM packaging). Install with: sudo apt-get install -y ruby ruby-dev build-essential && sudo gem install --no-document fpm
- dpkg-deb (for .deb)
- packer (for VMDK)

Files / scripts provided:
- scripts/deployment/build-deb.sh  (already present)
- scripts/deployment/build-rpm.sh  (new)
- scripts/deployment/build-vmdk.sh (new)

Debian (.deb) build (Debian 12):
1. Ensure PostgreSQL is running and SQLx cache exists or regenerate it:
   export DATABASE_URL="postgresql://vlnman:CHANGE_THIS_PASSWORD@localhost:5432/vulnerability_manager"
   scripts/deployment/regenerate-sqlx-cache.sh
2. Run the provided script:
   scripts/deployment/build-deb.sh
3. The resulting .deb will be created in /tmp or as indicated by the script.

RPM (.rpm) build (RHEL / CentOS / Rocky / Alma / Fedora):
1. On an RPM-based build host (RHEL 8/9 or Fedora), install prerequisites, or use fpm on Debian host to produce RPMs:
   - Option A (native rpmbuild): install rpm-build, mock, and required dev packages, then use an rpm spec (not included) or adapt the build-deb contents.
   - Option B (recommended for simplicity): use fpm to package the same layout produced by build-deb.sh.

Example quick steps (fpm):

# Run build steps to produce directory layout
scripts/deployment/build-deb.sh
# fpm expects a directory to convert into an rpm
sudo gem install --no-document fpm || true
fpm -s dir -t rpm -n sentinelcore -v 1.0.0 --architecture amd64 \
  -C /tmp/sentinelcore-1.0.0 \
  --description "SentinelCore - Enterprise Vulnerability Management System" \
  --depends postgresql >= 15 --depends nginx \
  opt/ etc/ var/

The repository provides scripts/deployment/build-rpm.sh that wraps fpm and falls back to instructions to build on an RPM host.

VMDK (Packer)
The repo contains packer/ which already includes packer templates. Use the provided script to produce a VMDK:

scripts/deployment/build-vmdk.sh --version 1.0.0

This will call packer build with variables to output a VM disk in VMDK format. See packer/debian13-sentinelcore.pkr.hcl for details.

Docker Notice
-------------
See docs/DOCKER_NOTICE.md for a note about current Docker incompatibility with the Rust toolchain/dependency versions used by this project.