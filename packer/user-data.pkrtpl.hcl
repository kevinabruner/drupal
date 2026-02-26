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
    config:
      - {ptable: gpt, path: /dev/sda, wipe: superblock-recursive, type: disk, id: disk-sda}
      - {device: disk-sda, size: -1, wipe: superblock, flag: '', number: 1, preserve: false, type: partition, id: partition-0}
      - {fstype: ext4, volume: partition-0, preserve: false, type: format, id: format-0}
      - {device: format-0, path: /, type: mount, id: mount-0}
  user-data:
    package_upgrade: true
    packages:
      - qemu-guest-agent
    runcmd:
      - [ systemctl, enable, --now, qemu-guest-agent ]