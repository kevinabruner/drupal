packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

locals {
  # Read your actual public key from your home directory
  my_public_key = trimspace(file("~/.ssh/id_rsa.pub"))
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = null 
}
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_api_url" { type = string }
#variable "proxmox_api_token_id" { type = string }

source "proxmox-iso" "drupal-base" {
  proxmox_url = var.proxmox_api_url
  username    = "terraform@pam!main_terraform"
  token       = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node    = "pve"
  vm_name = "packer-drupal-iso"


  # Use the modern boot_iso block
  boot_iso {
    type         = "scsi"
    iso_file     = "truenas-nfs:iso/ubuntu-24.04.4-live-server-amd64.iso"
    unmount      = true
  }

  # Simple disk definition - use type 'scsi' and ensure scsi_controller is set
  scsi_controller = "virtio-scsi-pci"
  disks {
    disk_size    = "20G"
    format       = "raw"
    storage_pool = "truenas-nfs"
    type         = "scsi"
  }

  cores  = 2
  memory = 2048

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  http_bind_address = "192.168.11.17"
  http_port_min     = 8795
  http_port_max     = 8795

  # --- Automation ---
  http_content = {
    "/user-data" = templatefile("user-data.pkrtpl.hcl", { ssh_key = local.my_public_key })
    "/meta-data" = ""
  }
# Give the VM plenty of time to reach the GRUB menu
  boot_wait = "5s" 
  
  boot_command = [
    "<esc><wait><esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ip=dhcp dev=ens18 cloud-init=enabled pkinst.wait_for_network=true --- <enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  ssh_username = "kevin"
  ssh_timeout  = "5m"
}

build {
  sources = ["source.proxmox-iso.drupal-base"]

  # Step 1: Ensure qemu-guest-agent is alive so Packer can find the IP
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent",
      "sudo systemctl enable --now qemu-guest-agent"
    ]
  }

  # Step 2: Run your existing Ansible roles
  provisioner "ansible" {
    playbook_file = "./playbooks/pb-packer-provision.yaml"
    user          = "kevin"
    use_proxy     = false
    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=./roles",
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
    # Pass variables if your roles need them during baking
    extra_arguments = [
      "--extra-vars", "is_packer_build=true"
    ]
  }

  # Step 3: Final Sanitization 
  # This prevents clones from having the same SSH host keys or Machine ID
  provisioner "shell" {
    inline = [
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt-get clean",
      "sudo sync"
    ]
  }
}