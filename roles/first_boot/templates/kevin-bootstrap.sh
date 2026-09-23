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

# If the hostname ends in 1 and we're in prod, then create a cron job to backup nfs
if [[ "$(hostname -s)" == *1 && "$environment" == "prod" ]]; then
    echo "0 3 * * * root rsync -az --delete /var/www/html/sites/default/files/ /home/kevin/nfs-files" > /etc/cron.d/ceph-nfs-backup
    chmod 644 /etc/cron.d/ceph-nfs-backup
fi
