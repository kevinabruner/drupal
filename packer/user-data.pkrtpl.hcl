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
    # Adding this 'grub' block at the same level as 'layout' 
    # tells the installer where to force the bootloader.
    grub:
      device: /dev/sda
    layout:
      name: direct
      # This is the magic flag for 24.04 to skip the 'Confirm' screen
      confirm: true 
    swap:
      size: 0
  # Using late-commands as a backup to ensure the agent starts
  late-commands:
    - curtin in-target -- target systemctl enable qemu-guest-agent