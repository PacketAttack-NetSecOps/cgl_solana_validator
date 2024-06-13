# Validator setup guide as of 2/7/2024:

### Reference Solana setup guide: 
https://docs.solanalabs.com/operations/setup-a-validator

### Hardware
OS: Ubunut 22.04
Disks (2):
nvme0n1 - OS disk should be atleast 500GB (can be SATA)
nvme1n1 - Ledger disk should be atleast 2TB (must be NVME)

### Set static IPs on NICs - Set routes
All nodes should be setup with dual NICs, one to be used for management with a manual route and the other to be used for default internet route
Use netplan yaml file:
sudo vi /etc/netplan/01-netcfg.yaml
See 01/netcfg.yaml example script in repo.

Apply the config changes
sudo netplan apply

### Run Updates:
sudo apt update
sudo apt upgrade

### Add sol user:
sudo adduser sol

### hard drive setup:
check partition layout:
df -h

### check block devices:
lsblk -f

### format 2nd disk for ledger:
sudo mkfs -t ext4 /dev/nvme1n1

### create the ledger directory, change ownership, mount the drive:
sudo mkdir -p /mnt/ledger
sudo chown -R sol:sol /mnt/ledger
sudo mount /dev/nvme1n1 /mnt/ledger

### add the new drive to fstab so that it mounts after reboot:
sudo vi /etc/fstab
add: /dev/nvme1n1 /mnt/ledger ext4 rw,relatime 0 0

### Optimize sysctl knobs:
sudo bash -c "cat >/etc/sysctl.d/21-solana-validator.conf <<EOF
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728
vm.max_map_count = 1000000
fs.nr_open = 1000000
EOF"

### Confirm sysctl knobs:
sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf

Add DefaultLimitNOFILE=1000000 to system.conf:
sudo vi /etc/systemd/system.conf
remove # from DefaultLimitNOFILE and set to 1000000

reload daemon
sudo systemctl daemon-reload

sudo bash -c "cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 1000000
EOF"

### Close all open sessions (log out ) ###

Log in as the sol user

Instal Solana CLI - Use current build for testnet or mainnet-beta:
sh -c "$(curl -sSfL https://release.solana.com/v1.17.20/install)"

check version:
solana --version

Create directory and file for validator config file:
mkdir -p /home/sol/bin
touch /home/sol/bin/validator.sh
chmod +x /home/sol/bin/validator.sh

Add config for validator.sh depending on server network:

exec solana-validator \
    --identity /home/sol/validator-keypair.json \
    --vote-account /home/sol/vote-account-keypair.json \
    --log /home/sol/solana-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/solana-accounts \
    --rpc-port 8899 \
    --private-rpc \
    --dynamic-port-range 8000-8020 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size 250000000 

create a system service (do this as sudo admin):
sudo vi /etc/systemd/system/sol.service

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

Setup log rotate:
# Setup log rotation

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
sudo cp logrotate.sol /etc/logrotate.d/sol
sudo systemctl restart logrotate.service

Setup ram disk:
sudo mkdir /mnt/solana-accounts

sudo vi /etc/fstab
add to the bottom: "tmpfs /mnt/solana-accounts tmpfs rw,size=300G,user=sol 0 0"

setup 250GB swap file for tmpfs spillover:
sudo dd if=/dev/zero of=/swapfile bs=1MiB count=250KiB

set permissions: 
sudo chmod 0600 /swapfile

sudo mkswap /swapfile

update fstab:
vi /etc/fstab
/swapfile swap swap defaults 0 0

Enable swap
sudo swapon -a
sudo mount /mnt/solana-accounts/

Confirm swap is active with free -g and the tmpfs is mounted with mount

Start the validator service:
sudo systemctl enable --now sol

Check Log:
tail -f solana-validator.log
