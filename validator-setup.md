Validator setup guide as of 2/7/2024

Reference Solana setup guide: https://docs.solanalabs.com/operations/setup-a-validator

OS: Ubunut 22.04
2 disks:
nvme0n1 - OS disk should be atleast 500GB (can be SATA)
nvme1n1 - Ledger disk should be atleast 2TB (must be NVME)

Run Updates:
sudo apt update
sudo apt upgrade

Add sol user:
sudo adduser sol

hard drive setup:
check partition layout:
df -h

check block devices:
lsblk -f

format 2nd disk for ledger:
sudo mkfs -t ext4 /dev/nvme1n1

create the ledger directory, change ownership, mount the drive:
sudo mkdir -p /mnt/ledger
sudo chown -R sol:sol /mnt/ledger
sudo mount /dev/nvme1n1 /mnt/ledger

add the new drive to fstab so that it mounts after reboot:
sudo vi /etc/fstab
add: /dev/nvme1n1 /mnt/ledger ext4 rw,relatime 0 0

