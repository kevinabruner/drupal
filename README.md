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
- `-e "target_app=[APP_NAME]"`
- Where [APP_NAME] is the GitHub repository name of the Drupal website in question.
  - e.g. `ansible-playbook playbooks/deploy-dev -e "target_app=recursioncomic"`

## Playbook steps
1. Create your dev machines by using [netbox](https://netbox.thejfk.ca) (internal link only!) and then deploy them using the [Terraform server](https://github.com/kevinabruner/terraform).

2. On the Ansible controller, first run the composer playbook to build the composer files into a Drupal application. This will run locally on your Ansible controller.
    - `ansible-playbook playbooks/build-composer.yaml -e target_app=[APP_NAME]`
3. Once Drupal is built, you can bake a golden image using packer. 
    - Packer will automatically invoke it's only playbook for building its image (`_packer-build.yaml`). 
    - There's a basic script in the root of this repo which invokes packer and the `_packer-preflight.yaml` playbook to ensure the previous golden image is destroyed and the previous step of building composer has been run. 
    - You must provide the drupal application as an argument
      - `./bake.sh [APP_NAME]`
4. You can then deploy to dev using a playbook if your image built correctly.
    - `ansible-playbook playbooks/deploy-dev.yaml -e target_app=[APP_NAME]`
    - Alternatively, you can simply re-deploy using terraform which will use the new image. 
5. If your dev servers look good, go ahead and do the same for prod
    - `ansible-playbook playbooks/deploy-dev.yaml -e target_app=[APP_NAME]`
    - Same as the dev servers, terraform will automatically deploy from the latest golden image.
