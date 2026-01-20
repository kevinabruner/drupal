#!/bin/bash
gitDir="/home/kevin/ansible"
password_file="/home/kevin/ansible-pass"

sudo apt-get update && sudo apt-get dist-upgrade -y
sudo apt-get install python3-pip ansible vim -y
#sudo cp -R $gitDir/ansible-files/* /etc/ansible


# Check if the password file exists
if [ ! -f "$password_file" ]; then
    echo -n "Enter your passphrase: "
    read -s pass # This will prompt the user for a password without echoing it back to the terminal
    echo -n "$pass" | openssl aes-256-cbc -a -salt -pass stdin > $password_file
fi


line_to_append="ANSIBLE_VAULT_PASSWORD_FILE=$password_file"
if grep -qF "$line_to_append" /etc/environment; then
    echo "The line is already present in /etc/environment."
else
    # Append the line to /etc/environment
    echo "$line_to_append" | sudo tee -a /etc/environment > /dev/null
    echo "Line appended to /etc/environment."
fi

echo "Configuration updated successfully!"

source /etc/environment
