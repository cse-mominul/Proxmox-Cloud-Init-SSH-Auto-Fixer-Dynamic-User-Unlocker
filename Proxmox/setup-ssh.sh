#!/bin/bash

# ==========================================================
# Proxmox/Cloud-Init SSH Auto-Fixer Installer
# ==========================================================

echo "Installing SSH Auto-Fixer..."

# ১. মূল স্ক্রিপ্টটি তৈরি করা (/usr/local/bin/ এ)
cat <<'EOF' | sudo tee /usr/local/bin/setup-ssh.sh > /dev/null
#!/bin/bash
echo "Running SSH & User Access Fix..."

# Cloud-init কনফিগ ঠিক করা
if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]; then
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/50-cloud-init.conf
fi

if [ -f /etc/cloud/cloud.cfg ]; then
    sed -i 's/ssh_pwauth: [Ff]alse/ssh_pwauth: true/g' /etc/cloud/cloud.cfg
    sed -i 's/ssh_pwauth: 0/ssh_pwauth: 1/g' /etc/cloud/cloud.cfg
fi

# মেইন SSH কনফিগ আপডেট
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/g' /etc/ssh/sshd_config

# ইউজার আনলক করা
for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
    usermod -U "$user" 2>/dev/null
done
usermod -U root 2>/dev/null

# SSH সার্ভিস রিস্টার্ট
systemctl restart sshd
echo "SSH Fix Applied Successfully."
EOF

# ২. স্ক্রিপ্টটিকে এক্সিকিউটেবল পারমিশন দেওয়া
sudo chmod +x /usr/local/bin/setup-ssh.sh

# ৩. Systemd Service ফাইল তৈরি করা
cat <<EOF | sudo tee /etc/systemd/system/fix-ssh.service > /dev/null
[Unit]
Description=Fix SSH Access after Cloud-Init
After=network.target cloud-final.service sshd.service
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-ssh.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# ৪. সার্ভিস এক্টিভেট করা
sudo systemctl daemon-reload
sudo systemctl enable fix-ssh.service
sudo systemctl restart fix-ssh.service

echo "------------------------------------------------"
echo "Installation Complete!"
echo "Service status:"
sudo systemctl status fix-ssh.service --no-pager
echo "------------------------------------------------"
