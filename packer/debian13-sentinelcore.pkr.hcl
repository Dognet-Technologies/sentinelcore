# Packer template for SentinelCore VM - Debian 13 (Trixie)
# Builds ready-to-use VM images with SentinelCore pre-installed

packer {
  required_version = ">= 1.9.0"
  required_plugins {
    virtualbox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

# Variables
variable "version" {
  type    = string
  default = "1.0.0"
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/debian-cd/12.8.0/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c9d35acd27b848c5cf7537053e6ebc55c19d31b43346fb776fb5f8a9e2cf7f14"
}

variable "vm_name" {
  type    = string
  default = "sentinelcore-debian12"
}

variable "disk_size" {
  type    = number
  default = 51200 # 50GB
}

variable "memory" {
  type    = number
  default = 8192 # 8GB RAM
}

variable "cpus" {
  type    = number
  default = 4
}

variable "ssh_username" {
  type    = string
  default = "microcyber"
}

variable "ssh_password" {
  type    = string
  default = "microcyber"
  sensitive = true
}

# VirtualBox builder
source "virtualbox-iso" "sentinelcore" {
  guest_os_type = "Debian_64"
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum

  vm_name              = "${var.vm_name}-virtualbox-${var.version}"
  disk_size            = var.disk_size
  hard_drive_interface = "sata"

  memory = var.memory
  cpus   = var.cpus

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--vram", "128"],
    ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"],
    ["modifyvm", "{{.Name}}", "--audio", "none"],
  ]

  # Network
  vboxmanage_post = [
    ["modifyvm", "{{.Name}}", "--nic1", "nat"],
    ["modifyvm", "{{.Name}}", "--natpf1", "ssh,tcp,,2222,,22"],
    ["modifyvm", "{{.Name}}", "--natpf1", "http,tcp,,8080,,8080"],
    ["modifyvm", "{{.Name}}", "--natpf1", "https,tcp,,8443,,8443"],
  ]

  # Boot configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname=${var.vm_name} <wait>",
    "netcfg/get_domain=local <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "<enter><wait>"
  ]

  http_directory = "http"

  # SSH configuration
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_timeout          = "30m"
  ssh_handshake_attempts = 20

  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"

  # Export settings
  format           = "ova"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "SentinelCore ${var.version} - Enterprise Vulnerability Management System",
    "--version", var.version
  ]

  output_directory = "output-virtualbox"
}

# QEMU builder (for KVM/QEMU)
source "qemu" "sentinelcore" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  vm_name      = "${var.vm_name}-qemu-${var.version}"
  disk_size    = var.disk_size
  format       = "qcow2"

  memory       = var.memory
  cpus         = var.cpus

  accelerator  = "kvm"

  # Network
  net_device = "virtio-net"
  disk_interface = "virtio"

  # Boot configuration
  boot_wait = "5s"
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname=${var.vm_name} <wait>",
    "netcfg/get_domain=local <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "<enter><wait>"
  ]

  http_directory = "http"

  # SSH configuration
  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"

  output_directory = "output-qemu"
}

# Build configuration
build {
  name = "sentinelcore-vm"

  sources = [
    "source.virtualbox-iso.sentinelcore",
    "source.qemu.sentinelcore"
  ]

  # Update system
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init/system to be ready...'",
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }

  # Run main provisioning script
  provisioner "shell" {
    script = "scripts/provision.sh"
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  # Copy first-boot configuration script
  provisioner "file" {
    source      = "scripts/first-boot.sh"
    destination = "/tmp/first-boot.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/first-boot.sh /usr/local/bin/sentinelcore-first-boot",
      "sudo chmod +x /usr/local/bin/sentinelcore-first-boot"
    ]
  }

  # Cleanup
  provisioner "shell" {
    script = "scripts/cleanup.sh"
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  # Post-processor: create checksums
  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "{{.BuildName}}_{{.ChecksumType}}.checksum"
  }

  # Post-processor: compress
  post-processor "compress" {
    output = "{{.BuildName}}-${var.version}.tar.gz"
    only   = ["qemu.sentinelcore"]
  }
}
