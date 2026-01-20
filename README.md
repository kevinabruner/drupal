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
These roles and playbooks are designed to manage a number of websites, but are not scoped to any one site by default. As such, running these playbooks without providing any variables will result in an error. The `target_app` variable is required to passed to every playbook on every run for these playbooks to work. The argument after any playbook should be:
- `-e "target_app=[--REPOSITORY--]"`
- Where [--REPOSITORY--] is the GitHub repository name of the Drupal website in question.
  - e.g. `ansible-playbook playbooks/1-build-composer.yaml -e "target_app=recursioncomic"`

## Playbook steps
1. Create your dev machines by using [netbox](https://netbox.thejfk.ca) (internal link only!) and then deploy them using the [Terraform server](https://github.com/kevinabruner/terraform).
  - Optionally destroy and recreate blank dev machines by running `ansible-playbook 0-wipe-dev.yaml`
2. On the Ansible controller, first run the build.yaml playbook to build the composer files into a Drupal application. This will run locally on your Ansible controller.
    - `ansible-playbook playbooks/1-build-composer.yaml`
3. Once Drupal is built, you can deploy all of its files to your dev servers.
    - `ansible-playbook playbooks/2-deploy-dev.yaml`
4. If your dev servers work the way you like, you then bake an image from the 1st dev server
    - `ansible-playbook playbooks/3-bake-image.yaml`
5. Once your image is ready, you may destroy, rebuild and reconfigure them in prod one at a time
    - `ansible-playbook playbooks/4-deploy-prod.yaml`
