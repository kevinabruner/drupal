#cloud-config
autoinstall:
  version: 1
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
    grub:
      reinstall_grub: true
    config:
      - type: disk
        id: disk-sda
        path: /dev/sda
        ptable: gpt
        # Forces the installer to wipe everything without asking
        preserve: false
        wipe: superblock-recursive
        grub_device: true
      - type: partition
        id: partition-0
        device: disk-sda
        size: 1M
        flag: bios_grub
      - type: partition
        id: partition-1
        device: disk-sda
        size: -1
        preserve: false
      - type: format
        id: format-0
        fstype: ext4
        volume: partition-1
        preserve: false
      - type: mount
        id: mount-0
        device: format-0
        path: /
  late-commands:
    - curtin in-target -- systemctl enable qemu-guest-agent
    - curtin in-target -- systemctl start qemu-guest-agent