alias ans-run='git pull && time ansible-playbook'
bake() {
    if [ -z "$1" ]; then
        echo "Error: You must provide a target_app name (e.g., bake nerdperk)"
        return 1
    fi

    APP_NAME=$1

    echo "--- Pulling latest configuration ---"
    git pull || { echo "Git pull failed"; return 1; }

    echo "--- Checking for existing template: ${app_name}-golden ---"
    ssh root@$pve_node "VMID=\$(qm list | grep \"${app_name}-golden\" | awk '{print \$1}'); if [ ! -z \"\$VMID\" ]; then echo \"Destroying old template ID: \$VMID\"; qm destroy \$VMID --purge; fi"

    echo "--- Baking Gold Image for: $APP_NAME ---"
    time packer build \
        -var "target_app=$APP_NAME" \
        -var-file="packer/variables.pkrvars.hcl" \
        -var-file="packer/secret.pkrvars.hcl" \
        packer/drupal-golden-image.pkr.hcl
}
