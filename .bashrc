alias ans-run='git pull && time ansible-playbook'
bake() {
    local app_name="$1"
    if [ -z "$1" ]; then
        echo "Error: You must provide a target_app name (e.g., bake nerdperk)"
        return 1
    fi

    echo "--- Pulling latest configuration ---"
    git pull || { echo "Git pull failed"; return 1; }

    echo "--- Checking for existing template: ${app_name}-golden ---"
    ssh root@pve "VMID=\$(qm list | grep \"${app_name}-golden\" | awk '{print \$1}'); if [ ! -z \"\$VMID\" ]; then echo \"Destroying old template ID: \$VMID\"; qm destroy \$VMID --purge; fi"

    echo "--- Baking Gold Image for: $app_name ---"
    time packer build \
        -var "target_app=$app_name" \
        -var-file="packer/variables.pkrvars.hcl" \
        -var-file="packer/secret.pkrvars.hcl" \
        packer/drupal-golden-image.pkr.hcl
}
