#cloud-config
autoinstall:
  version: 1
  early-commands:
    # Force a wipe of all existing signatures and wait for the kernel to sync
    - wipefs -af /dev/sda
    - sgdisk --zap-all /dev/sda
    - partprobe /dev/sda
    - udevadm settle
    - sleep 2
  reboot: true
  interactive-sections:
    - none
  identity:
    hostname: packer-drupal
    username: kevin
    password: "$6$HFFPPnhKmtgvZKvJ$HPlCLq8z9Dswz8nEJxUvtMsG3z4ZhriLpZiYirybfzy0vTb6boR//sErEIhZ0mhnyqIUrUrr6HYZjWRykCLXu/"
  ssh:
    install-server: true
    authorized-keys:
      - |
        ${ssh_key}
  packages:
    - qemu-guest-agent
    - openssh-server
  storage:
    config:
      - type: disk
        id: disk-0
        # Matching by serial or name instead of path often bypasses the cache
        match:
          name: "sda"
        ptable: gpt
        wipe: superblock-recursive
        preserve: false
        grub_device: true
  late-commands:
    - curtin in-target -- systemctl enable qemu-guest-agent
    - ["curtin", "in-target", "--", "poweroff"]
  user-data:
    package_upgrade: true
    groups:
      - sudo
    users:
      - name: kevin
        groups: [sudo, video, render]
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${ssh_key}