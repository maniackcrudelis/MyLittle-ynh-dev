#!/bin/bash

# printers
normal="\e[0m"
bold="\e[1m"
white="\e[97m"
green="\e[32m"
blue="\e[34m"
orange="\e[33m"

echo_info()
{
	echo -e "[${bold}${blue}INFO${normal}] ${bold}${white}$1${normal}"
}

echo_warn()
{
	echo -e "[${bold}${orange}WARN${normal}] ${bold}${white}$1${normal}"
}

echo_info "Install dependencies for VirtualBox Guest additions"
sudo apt update
sudo apt install build-essential dkms linux-headers-`uname -r`

echo_info "Insert Guest Additions CD image from VirtualBox interface"
# Check if /dev/sr0 has a cdrom
while ! sudo blkid /dev/sr0 > /dev/null
do
	echo_info "Press a key when it's done..."
	read
done
sleep 2
# Mount the cd in /media/cdrom
sudo mount -t iso9660 /dev/sr0 /media/cdrom

echo_info "Build Guest Additions"
(cd /media/cdrom0; sudo ./VBoxLinuxAdditions.run)

echo_info "Add a Shared Folder from VirtualBox interface named 'ynh-dev'"
echo_info "Press a key when it's done..."
read

./use_ynh-dev.sh --no-mount
