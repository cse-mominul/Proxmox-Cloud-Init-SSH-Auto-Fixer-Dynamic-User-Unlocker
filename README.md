# SSH Auto-Fixer for Proxmox & Cloud-Init

This repository contains a specialized script designed to resolve SSH login issues on Linux VMs (Ubuntu, Debian, CentOS, etc.) running on Proxmox or CloudStack. It specifically fixes the "Permission denied (publickey)" error that occurs when Cloud-Init disables password authentication and locks user accounts after a reboot.

## Features
- **Dynamic User Unlocking**: Automatically detects and unlocks all real users (UID >= 1000) and the Root user.
- **Persistence**: Creates a `systemd` service to ensure the fix runs automatically after every reboot.
- **SELinux Compatibility**: Configures SELinux policies correctly without needing to disable security via `setenforce 0`.
- **Cloud-Init Override**: Removes the restrictive `50-cloud-init.conf` file that blocks password authentication.

---

## Step-by-Step Installation

### Step 1: Access your VM
Log in to your VM using the **Proxmox Console** (since SSH is currently blocked).

### Step 2: Download the Script
Download the script directly from your GitHub repository (replace `your-username` with your actual GitHub username):
```bash
git clone https://github.com/cse-mominul/Proxmox-Cloud-Init-SSH-Auto-Fixer-Dynamic-User-Unlocker.git
cd Proxmox-Cloud-Init-SSH-Auto-Fixer-Dynamic-User-Unlocker
chmod +x setup-ssh.sh
sudo ./setup-ssh.sh
