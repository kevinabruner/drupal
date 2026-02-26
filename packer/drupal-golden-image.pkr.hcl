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

  # --- Automation ---
  http_directory = "packer" 
# Give the VM plenty of time to reach the GRUB menu
  boot_wait = "30s" 
  
  boot_command = [
    # 1. Escape out of any initial splash menus
    "<esc><wait><esc><wait>", 
    
    # 2. Enter GRUB command line mode
    "c<wait>", 
    
    # 3. Type the boot instruction. 
    # Note: We use 'seed' and 'autoinstall' to ensure it doesn't stop.
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<enter><wait>",
    
    # 4. Load the ramdisk
    "initrd /casper/initrd<enter><wait>",
    
    # 5. Kick off the boot
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