#cloud-config
autoinstall:
  version: 1
  early-commands:
    # 1. Kill the signatures
    - wipefs -af /dev/sda
    # 2. Zap the GPT/MBR tables
    - sgdisk --zap-all /dev/sda
    # 3. FORCE the kernel to reload the empty partition table
    - partprobe /dev/sda
    # 4. Give the hardware a 2-second breather to settle
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
    layout:
      name: direct
      confirm: true
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