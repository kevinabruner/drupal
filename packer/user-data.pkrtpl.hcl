#cloud-config
autoinstall:
  version: 1
  interactive-sections:
    - none
  identity:
    hostname: packer-drupal
    username: kevin
    password: "$6$HFFPPnhKmtgvZKvJ$HPlCLq8z9Dswz8nEJxUvtMsG3z4ZhriLpZiYirybfzy0vTb6boR//sErEIhZ0mhnyqIUrUrr6HYZjWRykCLXu/"
  # In 24.04, it is safest to put the key directly in the ssh section like this
  ssh:
    install-server: true
    authorized-keys:
      - |
        ${ssh_key}
  # Moved to the top level of autoinstall
  packages:
    - qemu-guest-agent
    - openssh-server
  storage:
    # This 'grub' section tells the installer where to write the bootloader
    grub:
      reinstall_grub: true
    config:
      - type: disk
        id: disk-sda
        path: /dev/sda
        ptable: gpt
        # These three lines together bypass the 'Confirm' prompt
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
    - curtin in-target -- target systemctl enable qemu-guest-agent