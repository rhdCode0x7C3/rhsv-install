Let's think about the flow of data through the program.

# 000_hardware
Input: none
Side effects: none
Output: Computer architecture and list of disks

# 001_partition
Input: list of disks, user selects disk
Side effects: create partitions on the selected disk
Output: PARTID of each created partition

# 002_mkfs
Config: sfdisk config
Secrets: LUKS passphrase

Input: PARTID of each partition
Side effects: create filesystems
Output: Result.t with no data

# 003_mount
Config: btrfs mount options

Input: PARTID of each partition
Side effects: mount the partitions
Output: mountpoint of each partition

# 004_subvolumes
Config: subvolume names, mountpoints and mount options

Input: mountpoint of each partition
Side effects: create and mount subvolumes
Output: Result.t with no data

# 005_install_base
Config: void repo mirror URL

Input: path to VFS root
Side effects: install the base system
Output: Result.t with no data

# 006_chroot
Input: path to VFS root
Side effects: chroot into the system
Output: Result.t with no data

# 007_system_config
Config: hostname, https://docs.voidlinux.org/config/rc-files.html#rcconf, dracut
conf
Input: none
Side effects: basic system configuration
Output: Result.t with no data

# 008_fstab
Input: PARTIDs, Btrfs mount options
Side effects: write to /etc/fstab
Output: Result.t with no data

# 009_grub
Input: Computer architecture
Side effects: install grub
Output: Result.t with no data

# 010_reboot
Input: none
Side effects: xbps-reconfigure
Output: Result.t with no data

