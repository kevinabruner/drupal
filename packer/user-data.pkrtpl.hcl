#cloud-config
autoinstall:
  version: 1
  interactive-sections:
    - none
  identity:
    hostname: packer-drupal
    password: "$6$HFFPPnhKmtgvZKvJ$HPlCLq8z9Dswz8nEJxUvtMsG3z4ZhriLpZiYirybfzy0vTb6boR//sErEIhZ0mhnyqIUrUrr6HYZjWRykCLXu/"
    username: kevin
  network:
    version: 2
    ethernets:
      ens18:
        dhcp4: true
  ssh:
    install-server: true
    authorized-keys:
      - ${ssh_key}
  # Packages and runcmd must be top-level under autoinstall
  package_upgrade: true
  packages:
    - qemu-guest-agent
  runcmd:
    - [ systemctl, enable, --now, qemu-guest-agent ]
  storage:
    grub:
      reinstall_grub: true
    config:
      - type: disk
        id: disk-0
        path: /dev/sda
        ptable: gpt
        overwrite: true
        wipe: superblock-recursive
      - type: partition
        id: partition-0
        device: disk-0
        size: -1
        wipe: superblock
      - type: format
        id: format-0
        fstype: ext4
        volume: partition-0
      - type: mount
        id: mount-0
        device: format-0
        path: /