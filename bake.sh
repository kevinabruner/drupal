#!/bin/bash
app_name="$1"
if [ -z "$1" ]; then
    echo "Error: You must provide a target_app name (e.g., bake.sh nerdperk)"
    return 1
fi

echo "--- Pulling latest configuration ---"
git pull || { echo "Git pull failed"; return 1; }

echo "--- Fetching VMID from Inventory ---"

VMID=$(ansible-inventory --list | jq -r '
  ._meta.hostvars as $hv |
  .role_vm_template.hosts[]? | 
  select($hv[.].custom_fields.repos == "'"$app_name"'" and $hv[.].custom_fields.dev_or_prod == "dev") | 
  $hv[.].custom_fields.vmid
')

if [ "$VMID" == "null" ] || [ -z "$VMID" ]; then
    echo "Error: Could not find VMID for $app_name in inventory."
    exit 1
fi

echo "--- Found VMID: $VMID  ---"

echo "--- Running Pre-flight Checklist ---"
ansible-playbook playbooks/_packer-preflight.yaml -e "target_app=$app_name" -K

echo "--- Baking Gold Image for: $app_name ---"
time packer build \
    -var "target_app=$app_name" \
    -var "proxmox_vmid=$VMID" \
    -var-file="packer/variables.pkrvars.hcl" \
    -var-file="packer/secret.pkrvars.hcl" \
    packer/drupal-golden-image.pkr.hcl