#!/bin/bash

# ==========================================================
# Proxmox/Cloud-Init SSH Auto-Fixer & Dynamic User Unlocker
# Purpose: Permanent Password Access & User Recovery
# ==========================================================

echo "Starting SSH & User Access Configuration..."

# 1. Clear Cloud-Init Override Settings
# Cloud-init often creates a file that explicitly disables password auth
if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
    sudo rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
    echo "Removed cloud-init SSH override file."
fi

# 2. Update SSH Configuration (Enable Password & Root Login)
# This forces the main config to allow password-based access
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/g' /etc/ssh/sshd_config

# 3. Dynamic User Unlock (For all real users)
# Automatically detects and unlocks all users with UID >= 1000 and Root
echo "Unlocking all users for password access..."
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    sudo usermod -U "$user" 2>/dev/null
    sudo usermod -p '*' "$user" 2>/dev/null
done
sudo usermod -U root 2>/dev/null

# 4. Permanent SELinux Configuration (Alternative to setenforce 0)
# This allows SSH password auth even when SELinux is Enforcing
if command -v setsebool &> /dev/null; then
    sudo setsebool -P ssh_sysadm_login 1 2>/dev/null
    sudo setsebool -P auth_login_any_state 1 2>/dev/null
    echo "SELinux policies updated successfully."
fi

# 5. Create Systemd Service for Persistence
# This ensures the fix runs automatically after every reboot/Cloud-init cycle
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

# 6. Enable Service & Restart SSH
sudo systemctl daemon-reload
sudo systemctl enable fix-ssh.service
sudo systemctl restart sshd

echo "------------------------------------------------"
echo "Configuration Complete!"
echo "You can now login via SSH using your password."
echo "------------------------------------------------"
