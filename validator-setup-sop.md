# Validator setup guide as of 6/15/2024:

### Reference Solana setup guide: 
https://docs.solanalabs.com/operations/setup-a-validator

## Hardware & OS
OS: Ubuntu 24.04  
Motherboard: GIGABYTE TRX50 AERO D  
CPU: Threadripper 7960X 24C 48T 5.3GHz  
Memory: 256GB - Standardizing on DDR5 M321R8GA0BB0-CQK 64GB modules  
DISK1 nvme0n1 - OS disk 1TB - Used for validator logs (NVME)  
DISK2 nvme1n1 - Ledger disk 2TB (NVME)  

### Set static IPs on NICs - Set Routes using netplan
All nodes should be setup with dual NICs, one to be used for management with a manual route and the other to be used for default internet route
Use netplan yaml file, refrence 01-netcfg.yaml example script in repo.

```
sudo vi /etc/netplan/01-netcfg.yaml
```
Set permissions on the netplan file
```
sudo chmod 600 /etc/netplan/01-netcfg.yaml
```
Apply the config changes
```
sudo netplan apply
```
### Enable SSH only on the Management Network Adapter
Modify the following configuration file
```
sudo vi /etc/ssh/sshd_config
```
Find at the top section #ListenAddress 0.0.0.0 remove the # and add the inside management IP address.

### Update Ubuntu System

Run Updates:
```
sudo apt update
sudo apt upgrade
```

### Add sol user - This user will run solana CLI software
```
sudo adduser sol
```

### Prep NVME storage
check partition layout:
```
df -h
```
check block devices:
```
lsblk -f
```
format 2nd disk for ledger:
```
sudo mkfs -t ext4 /dev/nvme1n1
```
### Create the ledger directory, change ownership, mount the drive:
```
sudo mkdir -p /mnt/ledger
sudo chown -R sol:sol /mnt/ledger
sudo mount /dev/nvme1n1 /mnt/ledger
```

### Add the new drive to fstab so that it mounts after reboot:
```
sudo vi /etc/fstab
```
add the following at the end: 
```
/dev/nvme1n1 /mnt/ledger ext4 rw,relatime 0 0
```

### Optimize sysctl knobs:
```
sudo bash -c "cat >/etc/sysctl.d/21-solana-validator.conf <<EOF
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728
vm.max_map_count = 1000000
fs.nr_open = 1000000
EOF"
```

### Confirm sysctl knobs:
```
sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf
```

### Set DefaultLimitNOFILE=1000000
```
sudo vi /etc/systemd/system.conf
```
remove # from DefaultLimitNOFILE and set to 1000000

### reload systemctl daemon
```
sudo systemctl daemon-reload
```

### Increase process file descriptor count limit
```
sudo bash -c "cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
* - nofile 1000000
EOF"
```

### Reboot the server

Log in as the new sol user

Install Solana CLI - Use current build for testnet or mainnet-beta:
```
sh -c "$(curl -sSfL https://release.solana.com/v1.18.15/install)"
```
Verify the new installed version:
```
solana --version
```

Create directory and file for validator config file:
```
mkdir -p /home/sol/bin
```
```
touch /home/sol/bin/validator.sh
```
```
chmod +x /home/sol/bin/validator.sh
```

Edit the validator.sh file and add all variables. Reference validator.sh
```
vi /home/sol/bin/validator.sh
```

Log back into the server sudo user. Create a system service to run the validator
```
sudo vi /etc/systemd/system/sol.service
```

Add the following:
```
[Unit]
Description=Solana Validator
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=sol
LimitNOFILE=1000000
LogRateLimitIntervalSec=0
Environment="PATH=/bin:/usr/bin:/home/sol/.local/share/solana/install/active_release/bin"
ExecStart=/bin/bash /home/sol/bin/validator.sh

[Install]
WantedBy=multi-user.target
```

### Setup log rotation
```
cat > logrotate.sol <<EOF
/home/sol/solana-validator.log {
  rotate 7
  daily
  missingok
  postrotate
    systemctl kill -s USR1 sol.service
  endscript
}
EOF
```

```
sudo cp logrotate.sol /etc/logrotate.d/sol
```
```
sudo systemctl restart logrotate.service
```

Setup 300GB tempfs ram disk:
```
sudo mkdir /mnt/solana-accounts
```

add to fstab:
```
echo 'tmpfs /mnt/solana-accounts tmpfs rw,noexec,nodev,nosuid,noatime,size=300G,user=sol 0 0' | \
  sudo tee --append /etc/fstab > /dev/null
```

setup 250GB swap file for tmpfs spillover:
```
sudo dd if=/dev/zero of=/swapfile bs=1MiB count=250KiB
```
set permissions: 
```
sudo chmod 0600 /swapfile
```
```
sudo mkswap /swapfile
```
update fstab:
```
vi /etc/fstab
```
```
/swapfile swap swap defaults 0 0
```

Enable swap
```
sudo swapon -a
```
```
sudo mount /mnt/solana-accounts/
```
Confirm swap is active with free -g and the tmpfs is mounted with mount

Start the validator service:
```
sudo systemctl enable --now sol
```

Check Log:
```
tail -f solana-validator.log
```

This concludes the setup
