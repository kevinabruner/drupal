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

source "proxmox-clone" "drupal-base" {
  proxmox_url = var.proxmox_api_url
  username    = "terraform@pam!main_terraform"
  token       = var.proxmox_api_token_secret
  
  # Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "truenas-nfs"

  # Point to the local files we just created
  # Usingabspath() ensures Packer finds them regardless of where you run the command
  cloud_init_user_data_file    = "packer/user-data"
  cloud_init_network_data_file = "packer/network-config"

  # --- Clone Settings ---
  node     = "pve"
  clone_vm = "ubuntu-2404-cloud"
  vm_name  = "packer-drupal-bake"
  
  ssh_username = "kevin"
  qemu_agent   = true
  ssh_timeout  = "15m"
}

build {
  sources = ["source.proxmox-clone.drupal-base"]

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
    user          = "ubuntu"
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