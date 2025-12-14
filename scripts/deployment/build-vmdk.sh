#!/usr/bin/env bash
set -euo pipefail

# Simple wrapper to run packer and produce a VMDK (VMware) output.
PACKER_TEMPLATE="packer/debian13-sentinelcore.pkr.hcl"
VERSION="1.0.0"
OUT_DIR="output-vmware"

if ! command -v packer &> /dev/null; then
  echo "❌ packer is not installed. Please install packer (https://www.packer.io/downloads)"
  exit 1
fi

echo "📦 Building VMDK with packer template ${PACKER_TEMPLATE}"
packer build -var "version=${VERSION}" -var "output_directory=${OUT_DIR}" "${PACKER_TEMPLATE}"

echo "✅ VMDK build finished. Check ${OUT_DIR} for artifacts."