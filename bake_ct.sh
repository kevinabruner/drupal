#!/bin/bash
app_name="$1"
OS_TEMPLATE="truenas-nfs:vztmpl/debian-13-golden.tar.zst"
VMID="9000"
env="$2"        # 'dev' or 'prod'
OUTPUT="${app_name}-${env}-golden"
PLAYBOOK="playbooks/_packer-build.yaml"

set -euo pipefail

if [[ -z "$env" ]]; then
    echo "Must provide \"dev\" or \"prod\" as arg"
fi

# Clean up old temp VM, if it exists
ssh root@pve "pct status $VMID >/dev/null 2>&1 && pct destroy $VMID --purge --force" || true

# Load and export variables from /etc/environment
#source /etc/environment

echo "--- Doing a git pull because you probably forgot to ---"
git pull || { echo "Git pull failed"; exit 1; }

echo "--- Baking golden container template for: $app_name ---"
time packer build \
    -var "proxmox_vmid=$VMID" \
    -var "playbook_file"=$PLAYBOOK \
    -var "os_template=$OS_TEMPLATE" \
    -var "env=${env}" \
    -var "output_template_name"=$OUTPUT \
    -var-file="packer/variables.pkrvars.hcl" \
    packer/golden-ct.pkr.hcl