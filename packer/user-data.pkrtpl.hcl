#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: packer-drupal
    password: "$6$HFFPPnhKmtgvZKvJ$HPlCLq8z9Dswz8nEJxUvtMsG3z4ZhriLpZiYirybfzy0vTb6boR//sErEIhZ0mhnyqIUrUrr6HYZjWRykCLXu/" # 'ubuntu' or your hashed pass
    username: kevin
  # Networking configuration moved inside autoinstall
  network:
    network:
      version: 2
      ethernets:
        enp1s0: # Ubuntu 24.04 usually names the first VirtIO slot enp1s0
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

