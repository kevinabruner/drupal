#cloud-config
autoinstall:
  version: 1
  # ADD THIS: This tells the installer to never stop for user input
  interactive-sections:
    - none
  identity:
    hostname: packer-drupal
    password: "$6$HFFPPnhKmtgvZKvJ$HPlCLq8z9Dswz8nEJxUvtMsG3z4ZhriLpZiYirybfzy0vTb6boR//sErEIhZ0mhnyqIUrUrr6HYZjWRykCLXu/"
    username: kevin
  network:
    network:
      version: 2
      ethernets:
        ens18:
          dhcp4: true
  ssh:
    install-server: true
    authorized-keys:
      - ${ssh_key}
  storage:
    layout:
      name: direct
  user-data:
    package_upgrade: true
    packages:
      - qemu-guest-agent
    runcmd:
      - [ systemctl, enable, --now, qemu-guest-agent ]