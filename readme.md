# Ansible
This controls all my software. 

# .bashrc
Put this at the end, or you'll never access the inventory token
```
VAULT_PATH="/home/kevin/ansible/vault.yaml"
PASS_PATH="/home/kevin/.vaultpass"

if [ -f "$VAULT_PATH" ] && [ -f "$PASS_PATH" ]; then
    # Extracts the value after the colon, then strips quotes and whitespace
    TOKEN=$(ansible-vault view "$VAULT_PATH" --vault-password-file "$PASS_PATH" | awk -F': ' '/netbox_token/ {print $2}' | tr -d '"' | tr -d "'" | xargs)
    if [ -n "$TOKEN" ]; then
        export NETBOX_API_TOKEN="$TOKEN"
    fi
fi
```
# vault pass
Create a vault pass at `/home/kevin/.vaultpass`. Just the password by itself in the file. 600 permissions.
If you don't know the password, oops!


# Deploying Drupal applications using Ansible
- These playbooks are designed to manage Drupal applications distributed over multiple highly-available virtual machines in a proxmox environment. 
- The source-of-truth for this is my **Netbox** server which pulls all server configuration data.
- The IaC provider is **Terraform** which also pulls all of its source information from Netbox. 

## Deployment steps
A custom field called "repo" for is set for all Drupal VMs in my netbox.
Currently these applications are:
- [Recursioncomic.com](https://recursioncomic.com)
  - [GitHub Link](https://github.com/kevinabruner/recursioncomic)
- [Nerdperk.ca](https://nerdperk.ca)
  - [GitHub Link](https://github.com/kevinabruner/nerdperk)
- [Dan's blog template](https://koscinski.thejfk.ca) (WIP)
  - [GitHub Link](https://github.com/kevinabruner/koscinski)

## Scoping your play
These playbooks are designed to manage any number of Drupal websites. As such, running these playbooks without providing any variables will result in an error. The `target_app` variable is required to passed to every playbook on every run for these playbooks to work. The argument after any playbook should be:
- `-e "target_app='[--REPOSITORY--]'"`
- Where [--REPOSITORY--] is the GitHub repository name of the Drupal website in question.
  - e.g. `ansible-playbook 1-build-composer.yaml -e "target_app='recursioncomic'"`

## Playbook steps
1. Create your dev machines by using [netbox](https://netbox.thejfk.ca) (internal link only!) and then deploy them using the [Terraform server](https://github.com/kevinabruner/terraform).
  - Optionally destroy and recreate blank dev machines by running `ansible-playbook 0-wipe-dev.yaml`
2. On the Ansible controller, first run the build.yaml playbook to build the composer files into a Drupal application. This will run locally on your Ansible controller.
    - `ansible-playbook 1-build-composer.yaml`
3. Once Drupal is built, you can deploy all of its files to your dev servers.
    - `ansible-playbook 2-deploy-dev.yaml`
4. If your dev servers work the way you like, you then bake an image from the 1st dev server
    - `ansible-playbook 3-bake-image.yaml`
5. Once your image is ready, you may destroy, rebuild and reconfigure them in prod one at a time
    - `ansible-playbook 4-deploy-prod.yaml`
