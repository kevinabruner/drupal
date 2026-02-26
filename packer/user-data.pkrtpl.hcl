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
    grub:
      reinstall_grub: true
    config:
      - type: disk
        id: disk-0
        path: /dev/sda
        ptable: gpt
        overwrite: true
        wipe: superblock-recursive
      # 1. BIOS Boot Partition (1MB, no filesystem)
      - type: partition
        id: partition-bios
        device: disk-0
        size: 1M
        flag: bios_grub
      # 2. Add an EFI partition (Even if not using UEFI, Subiquity 24.04 often expects it for GPT)
      - type: partition
        id: partition-efi
        device: disk-0
        size: 512M
        flag: boot
      # 3. Root Partition
      - type: partition
        id: partition-root
        device: disk-0
        size: -1
      # 4. Formats
      - type: format
        id: format-efi
        fstype: fat32
        volume: partition-efi
      - type: format
        id: format-root
        fstype: ext4
        volume: partition-root
      # 5. Mounts
      - type: mount
        id: mount-root
        device: format-root
        path: /
      - type: mount
        id: mount-efi
        device: format-efi
        path: /boot/efi
  # Using late-commands as a backup to ensure the agent starts
  late-commands:
    - curtin in-target -- target systemctl enable qemu-guest-agent