#!/bin/bash
app_name="$1"
if [ -z "$1" ]; then
    echo "Error: You must provide a target_app name (e.g., bake.sh nerdperk)"
    return 1
fi

echo "--- Pulling latest configuration ---"
git pull || { echo "Git pull failed"; return 1; }

echo "--- Running Pre-flight Checklist ---"
ans-run playbooks/_packer-preflight.yaml -e "target_app=$app_name"

echo "--- Baking Gold Image for: $app_name ---"
time packer build \
    -var "target_app=$app_name" \
    -var-file="packer/variables.pkrvars.hcl" \
    -var-file="packer/secret.pkrvars.hcl" \
    packer/drupal-golden-image.pkr.hcl