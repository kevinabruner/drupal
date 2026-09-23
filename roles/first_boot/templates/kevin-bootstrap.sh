#!/bin/bash

source /etc/environment

# drupal environment file setup
TARGET_DIR="/etc/apache2/conf-available"
TARGET_FILE="${TARGET_DIR}/Drupal-env.conf"
mkdir -p "$TARGET_DIR"

# Write the drupal environment file content
cat <<EOF > "$TARGET_FILE"
SetEnv environment "${environment}"
EOF

# Enable and start the apache configuration
a2enconf Drupal-env 
systemctl restart apache2
