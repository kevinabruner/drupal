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

  # --- VM Hardware Settings ---
  node                 = "pve"
  vm_name              = "packer-drupal-iso-bake"
  iso_file             = "truenas-nfs/ubuntu-24.04-live-server-amd64.iso" # Ensure this path is correct in your PVE
  iso_storage_pool     = "truenas-nfs"
  
  cores                = 2
  memory               = 2048
  scsi_controller      = "virtio-scsi-pci"

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  disks {
    disk_size         = "8G"
    format            = "raw"
    storage_pool      = "truenas-nfs"
    type              = "virtio"
  }

  # --- Cloud-Init (The "Magic" Part) ---
  # This tells Packer to serve the user-data/meta-data over a temporary HTTP server
  http_directory = "packer" 
  boot_wait      = "5s"
  boot_command   = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot<enter>"
  ]

  ssh_username = "kevin"
  ssh_timeout  = "20m"
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