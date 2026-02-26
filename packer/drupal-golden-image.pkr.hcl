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
  
  # Cloud-Init Settings for proxmox-clone
  cloud_init              = true
  cloud_init_storage_pool = "truenas-nfs"

  # Direct arguments (No cloud_init_def block needed)
  user_data = <<-EOF
    #cloud-config
    user: kevin
    ssh_authorized_keys:
      - ${file("~/.ssh/id_rsa.pub")}
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable --now qemu-guest-agent
  EOF

  network_data = <<-EOF
    version: 2
    ethernets:
      eth0:
        dhcp4: true
  EOF



  
# --- Clone Settings ---
  node                 = "pve" # The Proxmox node name
  clone_vm             = "ubuntu-2404-cloud" # Your existing template name
  vm_name              = "packer-drupal-bake"
  template_description = "Drupal Golden Image created on ${formatdate("YYYY-MM-DD", timestamp())}"

  # --- VM Specs for the build process ---
  cores  = 2
  memory = 1024

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