#!/bin/bash

# ==========================================================
# Proxmox/Cloud-Init SSH Auto-Fixer & Dynamic User Unlocker
# Purpose: Permanent Password Access without deleting configs
# ==========================================================

echo "Starting SSH & User Access Configuration..."

# 1. Modify 50-cloud-init.conf instead of removing it
# This changes 'no' to 'yes' inside the override file
if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/50-cloud-init.conf
    echo "Updated 50-cloud-init.conf to allow password authentication."
fi

# 2. Fix ssh_pwauth in cloud.cfg
# This ensures cloud-init itself allows password auth on next boot
if [ -f /etc/cloud/cloud.cfg ]; then
    sudo sed -i 's/ssh_pwauth: false/ssh_pwauth: true/g' /etc/cloud/cloud.cfg
    sudo sed -i 's/ssh_pwauth: 0/ssh_pwauth: 1/g' /etc/cloud/cloud.cfg
    echo "Fixed ssh_pwauth in cloud.cfg."
fi

# 3. Standard SSH Configuration Updates
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config

# 4. Dynamic User Unlock
echo "Unlocking all users..."
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    sudo usermod -U "$user" 2>/dev/null
    sudo usermod -p '*' "$user" 2>/dev/null
done
sudo usermod -U root 2>/dev/null

# 5. Persistent Systemd Service
SCRIPT_PATH=$(readlink -f "$0")
cat <<EOF | sudo tee /etc/systemd/system/fix-ssh.service
[Unit]
Description=Fix SSH Access after Cloud-Init
After=cloud-final.service sshd.service

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 6. Apply Changes
sudo systemctl daemon-reload
sudo systemctl enable fix-ssh.service
sudo systemctl restart sshd

echo "------------------------------------------------"
echo "Configuration Updated Successfully!"
echo "------------------------------------------------"
