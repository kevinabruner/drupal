packer {
  required_plugins {
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

locals {
  my_public_key = trimspace(file("~/.ssh/id_rsa.pub"))
}

variable "proxmox_vmid" {
  type        = string
  description = "Temporary VMID used to build the LXC container."
}

variable "env" {
  type        = string
  description = "Passed from bake.sh (e.g., dev or prod)"
}

variable "os_template" {
  type        = string
  description = "Source OS template path or storage ID."
  default     = "truenas-nfs:vztmpl/debian-13-golden.tar.zst"

  validation {
    condition     = length(var.os_template) > 0
    error_message = "The os_template variable cannot be empty."
  }
}

variable "output_template_name" {
  type        = string
  default     = "varnish-golden"
  description = "Base filename for the exported container template tarball."
}

variable "pve_nfs_storage" {
  type        = string
  default     = "truenas-nfs"
  description = "Proxmox storage ID configured for Container Templates (vztmpl)."
}

variable "pve_template_dir" {
  type        = string
  default     = "/mnt/pve/truenas-nfs/template/cache"
  description = "Target storage location on Proxmox host for the NFS template cache."
}

variable "playbook_file" {
  type        = string
  description = "Path to the Ansible playbook relative to execution root."
}

variable "target_app" {
  type    = string
  # No default, must be an argument
}

source "null" "lxc-base" {
  communicator = "none"
}

build {
  sources = ["null.lxc-base"]

  # 1: Create and start temporary build LXC container on Proxmox host
  provisioner "shell-local" {
    inline = [
      "echo 'Building VMID: ${var.proxmox_vmid} using base template: ${var.os_template}'",
      "ssh root@pve \"pct create ${var.proxmox_vmid} '${var.os_template}' --ostype debian --cores 4 --memory 4096 --swap 512 --rootfs local-zfs:8 --hostname build-ct-${var.proxmox_vmid} --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp --unprivileged 1 --start 1\"",
      "echo 'Waiting for LXC container to initialize network...'",
      "sleep 5"
    ]
  }

  # 2: Inject temporary SSH key, poll for IP, and execute Ansible playbook
  provisioner "shell-local" {
    inline = [
      "echo 'Injecting build SSH key into container...'",
      "ssh root@pve \"pct exec ${var.proxmox_vmid} -- mkdir -p /root/.ssh\"",
      "ssh root@pve \"pct exec ${var.proxmox_vmid} -- sh -c 'echo \"${local.my_public_key}\" >> /root/.ssh/authorized_keys'\"",
      "ssh root@pve \"pct exec ${var.proxmox_vmid} -- chmod 600 /root/.ssh/authorized_keys\"",

      "echo 'Waiting for container IP assignment...'",
      "CT_IP=''",
      "until [ -n \"$CT_IP\" ]; do CT_IP=$(ssh root@pve \"pct exec ${var.proxmox_vmid} -- hostname -I | cut -d' ' -f1\"); sleep 2; done",
      "echo \"Container IP resolved to: $CT_IP\"",

      "echo 'Waiting for container SSH daemon...'",
      "until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa root@$CT_IP 'echo ssh-ready'; do sleep 2; done",

      "ANSIBLE_FORCE_COLOR=1 DEBIAN_FRONTEND=noninteractive ansible-playbook -i \"$CT_IP,\" -u root --private-key=~/.ssh/id_rsa --extra-vars \"target_app=${var.target_app} env=${var.env} \" ${var.playbook_file}"  
    ]
  }


  # 3:  sanitize template rootfs
  provisioner "shell-local" {
    inline = [
      "echo 'Sanitizing container rootfs...'",
      "ssh root@pve 'pct exec ${var.proxmox_vmid} -- apt-get clean'",
      "ssh root@pve 'pct exec ${var.proxmox_vmid} -- rm -rf /tmp/* /var/tmp/*'",
      "ssh root@pve 'pct exec ${var.proxmox_vmid} -- rm -f /root/.ssh/authorized_keys'",
      "ssh root@pve 'pct exec ${var.proxmox_vmid} -- rm -f /etc/ssh/ssh_host_*'",
      "ssh root@pve 'pct exec ${var.proxmox_vmid} -- rm -f /etc/machine-id'",
      "ssh root@pve 'pct exec ${var.proxmox_vmid} -- truncate -s 0 /etc/machine-id'",
      "ssh root@pve 'pct stop ${var.proxmox_vmid}'"
    ]
  }

  # 4: Export to ZSTD tarball on NFS storage and cleanup temporary container
  post-processor "shell-local" {
    inline = [
      "echo 'Exporting container rootfs directly to NFS storage...'",
      "ssh root@pve 'vzdump ${var.proxmox_vmid} --mode stop --compress zstd --dumpdir ${var.pve_template_dir}'",
      
      "echo 'Renaming backup archive to ${var.output_template_name}.tar.zst...'",
      "ssh root@pve 'mv ${var.pve_template_dir}/vzdump-lxc-${var.proxmox_vmid}-*.tar.zst ${var.pve_template_dir}/${var.output_template_name}.tar.zst'",
      
      "echo 'Destroying temporary build container ${var.proxmox_vmid}...'",
      "ssh root@pve 'pct destroy ${var.proxmox_vmid} --purge'",
      
      "echo 'Template successfully created on NFS at ${var.pve_template_dir}/${var.output_template_name}.tar.zst'",
      "echo 'Available in PVE CLI/GUI as: ${var.pve_nfs_storage}:vztmpl/${var.output_template_name}.tar.zst'"
    ]
  }
}