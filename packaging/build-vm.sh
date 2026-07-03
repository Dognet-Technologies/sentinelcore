#!/usr/bin/env bash
#
# SentinelCore — VM appliance builder
#
# Produce in dist/:
#   sentinelcore-<versione>-linux-x86_64.qcow2   (KVM / Proxmox)
#   sentinelcore-<versione>-linux-x86_64.ova      (VirtualBox / VMware)
#
# Il tarball binario (dist/*.tar.gz) deve esistere prima di chiamare questo
# script. Eseguilo su un host Linux x86_64 con KVM per tempi ragionevoli.
#
# Uso:
#   packaging/build-vm.sh [versione]   # versione default = git describe
#
# Dipendenze sul build host (una tantum):
#   sudo apt-get install qemu-system-x86 qemu-utils cloud-image-utils
#   (genisoimage o mkisofs come fallback per il cloud-init ISO)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-$(git describe --tags --always 2>/dev/null || echo v0.0.0)}"
ARCH="linux-x86_64"
TARBALL_NAME="sentinelcore-${VERSION}-${ARCH}.tar.gz"
TARBALL="$REPO_ROOT/dist/$TARBALL_NAME"
OUT="$REPO_ROOT/dist"
VM_NAME="sentinelcore-${VERSION}-${ARCH}"

# Immagine base: Debian 13 (trixie) generic cloud, sovrascrivibile via env
DEBIAN_IMG_URL="${DEBIAN_CLOUD_IMG_URL:-https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2}"
IMG_CACHE="${DEBIAN_CLOUD_IMG_CACHE:-$HOME/.cache/sentinelcore-build/debian-13-cloud-amd64.qcow2}"

VM_RAM=2048    # MB
VM_CPUS=2
DISK_SIZE=20G
BUILD_TIMEOUT=900   # secondi — l'install.sh non compila nulla, ~3 min attesi
HTTP_PORT=18080

log() { echo -e "\n\033[1;36m▶  $*\033[0m"; }
die() { echo -e "\033[1;31mERRORE: $*\033[0m" >&2; exit 1; }

# ── Prerequisiti ─────────────────────────────────────────────────────────────
log "Controllo prerequisiti"

[ -f "$TARBALL" ] || die "Tarball non trovato: $TARBALL
       Esegui prima: packaging/build-release.sh $VERSION"

for cmd in qemu-system-x86_64 qemu-img wget python3; do
    command -v "$cmd" >/dev/null || die "Comando non trovato: $cmd
       sudo apt-get install qemu-system-x86 qemu-utils"
done

ISO_CMD=""
for c in cloud-localds genisoimage mkisofs; do
    command -v "$c" >/dev/null && { ISO_CMD="$c"; break; }
done
[ -n "$ISO_CMD" ] || die "Serve cloud-localds, genisoimage o mkisofs per il cloud-init ISO.
       sudo apt-get install cloud-image-utils"

KVM_FLAGS=""
if [ -w /dev/kvm ]; then
    KVM_FLAGS="-enable-kvm -cpu host"
    echo "  KVM disponibile — build veloce"
else
    echo "  ⚠️  KVM non disponibile — build solo software (può richiedere 20+ min)"
fi

# ── Workspace ────────────────────────────────────────────────────────────────
WORK_DIR="$(mktemp -d)"
HTTP_PID=""
QEMU_PID=""

cleanup() {
    [ -n "$HTTP_PID"  ] && kill "$HTTP_PID"  2>/dev/null || true
    [ -n "$QEMU_PID"  ] && kill "$QEMU_PID"  2>/dev/null || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ── 1. Immagine base Debian 13 ───────────────────────────────────────────────
log "1/7  Immagine base Debian 13"
mkdir -p "$(dirname "$IMG_CACHE")"
if [ ! -f "$IMG_CACHE" ]; then
    echo "  Download: $DEBIAN_IMG_URL"
    wget --tries=3 --timeout=120 --progress=bar:force \
        -O "$IMG_CACHE.tmp" "$DEBIAN_IMG_URL" && mv "$IMG_CACHE.tmp" "$IMG_CACHE"
fi
cp "$IMG_CACHE" "$WORK_DIR/disk.qcow2"
qemu-img resize "$WORK_DIR/disk.qcow2" "$DISK_SIZE" >/dev/null
echo "  Disco pronto: $(qemu-img info "$WORK_DIR/disk.qcow2" | grep 'virtual size')"

# ── 2. HTTP server locale ────────────────────────────────────────────────────
log "2/7  HTTP server locale (build host → VM via NAT 10.0.2.2)"
python3 -m http.server --directory "$REPO_ROOT" "$HTTP_PORT" >/dev/null 2>&1 &
HTTP_PID=$!
echo "  PID $HTTP_PID   http://10.0.2.2:${HTTP_PORT}/dist/${TARBALL_NAME}"

# ── 3. Cloud-init ISO ────────────────────────────────────────────────────────
log "3/7  Cloud-init ISO"
CIDIR="$WORK_DIR/cidata"
mkdir -p "$CIDIR"

cat > "$CIDIR/meta-data" <<META
instance-id: sentinelcore-build-$(date +%s)
local-hostname: sentinelcore
META

# user-data: scarica e lancia provision.sh; le variabili sono espanse da bash
cat > "$CIDIR/user-data" <<CLOUDINIT
#cloud-config
write_files:
  - path: /tmp/build-env.sh
    permissions: '0644'
    content: |
      export TARBALL_NAME="${TARBALL_NAME}"
      export HTTP_BASE="http://10.0.2.2:${HTTP_PORT}"
runcmd:
  - 'wget -q "http://10.0.2.2:${HTTP_PORT}/packaging/appliance/provision.sh" -O /tmp/provision.sh && chmod +x /tmp/provision.sh'
  - 'bash -c ". /tmp/build-env.sh && /tmp/provision.sh" > /var/log/sentinelcore-provision.log 2>&1'
CLOUDINIT

case "$ISO_CMD" in
    cloud-localds)
        cloud-localds "$WORK_DIR/cidata.iso" "$CIDIR/user-data" "$CIDIR/meta-data"
        ;;
    genisoimage|mkisofs)
        "$ISO_CMD" -output "$WORK_DIR/cidata.iso" -volid cidata -joliet -rock \
            "$CIDIR/user-data" "$CIDIR/meta-data" 2>/dev/null
        ;;
esac
echo "  ISO: $WORK_DIR/cidata.iso"

# ── 4. Boot QEMU per il provisioning ────────────────────────────────────────
log "4/7  Provisioning VM (attendi ~5 min con KVM)"
# shellcheck disable=SC2086
qemu-system-x86_64 \
    -name "sentinelcore-vm-build" \
    -m "$VM_RAM" \
    -smp "$VM_CPUS" \
    $KVM_FLAGS \
    -drive "file=$WORK_DIR/disk.qcow2,format=qcow2,if=virtio" \
    -drive "file=$WORK_DIR/cidata.iso,format=raw,if=virtio,readonly=on" \
    -netdev "user,id=net0,hostfwd=tcp::10022-:22" \
    -device "virtio-net-pci,netdev=net0" \
    -display none \
    -serial "file:$WORK_DIR/qemu-console.log" \
    -no-reboot \
    >/dev/null 2>&1 &
QEMU_PID=$!

echo -n "  Avanzamento: "
WAITED=0
while kill -0 "$QEMU_PID" 2>/dev/null; do
    sleep 5; WAITED=$((WAITED + 5))
    echo -n "."
    if [ "$WAITED" -ge "$BUILD_TIMEOUT" ]; then
        echo ""
        echo "TIMEOUT (${BUILD_TIMEOUT}s). Log VM: $WORK_DIR/qemu-console.log"
        # Copia log prima del cleanup
        cp "$WORK_DIR/qemu-console.log" "$OUT/build-vm-console.log" 2>/dev/null || true
        kill "$QEMU_PID" 2>/dev/null || true
        die "Build VM non terminata. Controlla: $OUT/build-vm-console.log"
    fi
done
wait "$QEMU_PID" 2>/dev/null || true
echo " fatto"

# Copia log di provisioning per debug
cp "$WORK_DIR/qemu-console.log" "$OUT/build-vm-console.log" 2>/dev/null || true

# ── 5. qcow2 compresso ──────────────────────────────────────────────────────
log "5/7  Compressione immagine qcow2"
QCOW2_OUT="$OUT/${VM_NAME}.qcow2"
qemu-img convert -f qcow2 -O qcow2 -c \
    "$WORK_DIR/disk.qcow2" "$QCOW2_OUT"
echo "  $(ls -lh "$QCOW2_OUT" | awk '{print $5}')"

# ── 6. OVA (VirtualBox / VMware) ────────────────────────────────────────────
log "6/7  Conversione OVA"
VMDK="$WORK_DIR/${VM_NAME}.vmdk"
OVF="$WORK_DIR/${VM_NAME}.ovf"
MF="$WORK_DIR/${VM_NAME}.mf"
OVA_OUT="$OUT/${VM_NAME}.ova"

echo "  Conversione VMDK (streamOptimized)..."
qemu-img convert -f qcow2 -O vmdk -o subformat=streamOptimized \
    "$QCOW2_OUT" "$VMDK"

VMDK_SIZE="$(stat -c%s "$VMDK")"
DISK_CAP_BYTES="$(qemu-img info --output=json "$QCOW2_OUT" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin)["virtual-size"])')"

echo "  Generazione OVF..."
cat > "$OVF" <<OVFXML
<?xml version="1.0" encoding="UTF-8"?>
<Envelope ovf:version="1.0" xml:lang="en-US"
          xmlns="http://schemas.dmtf.org/ovf/envelope/1"
          xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1"
          xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData"
          xmlns:vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData">

  <References>
    <File ovf:href="${VM_NAME}.vmdk" ovf:id="file1" ovf:size="${VMDK_SIZE}"/>
  </References>

  <DiskSection>
    <Info>Virtual disk information</Info>
    <Disk ovf:capacity="${DISK_CAP_BYTES}" ovf:capacityAllocationUnits="byte"
          ovf:diskId="vmdisk1" ovf:fileRef="file1"
          ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"/>
  </DiskSection>

  <NetworkSection>
    <Info>Network adapters</Info>
    <Network ovf:name="NAT">
      <Description>NAT — l'IP assegnato appare in /etc/motd al primo avvio.</Description>
    </Network>
  </NetworkSection>

  <VirtualSystem ovf:id="SentinelCore">
    <Info>SentinelCore Vulnerability Management Appliance</Info>
    <Name>SentinelCore ${VERSION}</Name>

    <ProductSection>
      <Info>Product information</Info>
      <Product>SentinelCore</Product>
      <Vendor>Dognet Technologies</Vendor>
      <Version>${VERSION}</Version>
      <FullVersion>${VERSION} (Debian 13 amd64)</FullVersion>
    </ProductSection>

    <AnnotationSection>
      <Info>Usage notes</Info>
      <Annotation>Credenziali iniziali e URL in /etc/motd al primo avvio. CPU: 2 core min, RAM: 2 GB min, disco: 20 GB.</Annotation>
    </AnnotationSection>

    <VirtualHardwareSection>
      <Info>Hardware minimo consigliato</Info>
      <System>
        <vssd:ElementName>Virtual Hardware Family</vssd:ElementName>
        <vssd:InstanceID>0</vssd:InstanceID>
        <vssd:VirtualSystemIdentifier>SentinelCore</vssd:VirtualSystemIdentifier>
        <vssd:VirtualSystemType>vmx-13 virtualbox-2.2</vssd:VirtualSystemType>
      </System>
      <Item>
        <rasd:ElementName>2 virtual CPUs</rasd:ElementName>
        <rasd:InstanceID>1</rasd:InstanceID>
        <rasd:ResourceType>3</rasd:ResourceType>
        <rasd:VirtualQuantity>2</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:AllocationUnits>MegaBytes</rasd:AllocationUnits>
        <rasd:ElementName>2048 MB of memory</rasd:ElementName>
        <rasd:InstanceID>2</rasd:InstanceID>
        <rasd:ResourceType>4</rasd:ResourceType>
        <rasd:VirtualQuantity>2048</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:ElementName>SCSI Controller</rasd:ElementName>
        <rasd:InstanceID>3</rasd:InstanceID>
        <rasd:ResourceSubType>lsilogic</rasd:ResourceSubType>
        <rasd:ResourceType>6</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:ElementName>Disk Image</rasd:ElementName>
        <rasd:HostResource>ovf:/disk/vmdisk1</rasd:HostResource>
        <rasd:InstanceID>4</rasd:InstanceID>
        <rasd:Parent>3</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:AutomaticAllocation>true</rasd:AutomaticAllocation>
        <rasd:Connection>NAT</rasd:Connection>
        <rasd:ElementName>Ethernet adapter</rasd:ElementName>
        <rasd:InstanceID>5</rasd:InstanceID>
        <rasd:ResourceSubType>E1000</rasd:ResourceSubType>
        <rasd:ResourceType>10</rasd:ResourceType>
      </Item>
    </VirtualHardwareSection>
  </VirtualSystem>
</Envelope>
OVFXML

echo "  Generazione manifest SHA256..."
OVF_HASH="$(sha256sum "$OVF"  | awk '{print $1}')"
VMDK_HASH="$(sha256sum "$VMDK" | awk '{print $1}')"
cat > "$MF" <<MF
SHA256(${VM_NAME}.ovf)= ${OVF_HASH}
SHA256(${VM_NAME}.vmdk)= ${VMDK_HASH}
MF

echo "  Bundle OVA (tar, senza compressione — standard OVA)..."
( cd "$WORK_DIR" && tar --format=gnu -cf "$OVA_OUT" \
    "${VM_NAME}.ovf" "${VM_NAME}.vmdk" "${VM_NAME}.mf" )
echo "  $(ls -lh "$OVA_OUT" | awk '{print $5}')"

# ── 7. Checksum finali ───────────────────────────────────────────────────────
log "7/7  Checksum artefatti VM"
( cd "$OUT" && sha256sum "${VM_NAME}.qcow2" "${VM_NAME}.ova" \
    > "${VM_NAME}.sha256" )

# Firma GPG (non fatale se assente)
if gpg --list-secret-keys >/dev/null 2>&1; then
    ( cd "$OUT" && gpg --armor --detach-sign --output "${VM_NAME}.sha256.asc" \
        "${VM_NAME}.sha256" ) && echo "  Firmato: ${VM_NAME}.sha256.asc"
else
    echo "  (nessuna chiave GPG — firma saltata)"
fi

# ── Riepilogo ────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════════"
echo " Artefatti VM in: $OUT/"
ls -lh "$OUT/${VM_NAME}".{qcow2,ova,sha256} 2>/dev/null | awk '{printf "  %-8s %s\n", $5, $9}'
echo ""
echo " Build log VM:  $OUT/build-vm-console.log"
echo ""
echo " KVM/Proxmox:   $OUT/${VM_NAME}.qcow2"
echo " VirtualBox:    $OUT/${VM_NAME}.ova   (importa con File → Importa appliance)"
echo " VMware:        $OUT/${VM_NAME}.ova   (File → Open...)"
echo ""
echo " Al primo avvio: first-boot rigenera tutti i segreti e stampa"
echo " credenziali admin + URL in /etc/motd (SSH o console VM)."
echo "════════════════════════════════════════════════════════════════"
