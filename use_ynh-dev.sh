#!/bin/bash

# As an argument for this script, you can choose the directory to link to the host directory
# Choose between: ssowat, moulinette, yunohost, yunohost-admin or all
dir_to_mount=${1:-all}
if [ "$1" == "--no-mount" ]
then
	dir_to_mount=all
	doImount=0
	build_only=1
else
	doImount=1
	build_only=0
fi

ynh_dev_dir=/ynh-dev

# printers
normal="\e[0m"
bold="\e[1m"
white="\e[97m"
green="\e[32m"
blue="\e[34m"
orange="\e[33m"

echo_success()
{
	echo -e "[${bold}${green} OK ${normal}] ${bold}${white}$1${normal}"
}

echo_info()
{
	echo -e "[${bold}${blue}INFO${normal}] ${bold}${white}$1${normal}"
}

echo_warn()
{
	echo -e "[${bold}${orange}WARN${normal}] ${bold}${white}$1${normal}"
}

# Create the main directory for the mount
sudo mkdir -p "${ynh_dev_dir}"

create_sym_link () {
	local dest="$1"
	local link="$2"

	if [ ! -L "$link" ]; then
		# Move real directory to /ynh-dev
		sudo rm -rf "$dest"
		sudo mkdir -p "$(dirname "$dest")"
		sudo mv $link $dest
	fi
    # Symlink from Git repository
	sudo ln -sfn $dest $link
}

# Mount ynh-dev directory from the host
mount_directory () {
	if [ $doImount -eq 1 ]
	then
		echo_info "Mount shared directory from ynh-dev"
		sudo mount -o defaults -t vboxsf ynh-dev ${ynh_dev_dir}
	fi
}

# Umount directory before playing with it
if sudo mount | grep --quiet ${ynh_dev_dir}
then
	echo_info "Umount shared directory ${ynh_dev_dir}"
	sudo umount ${ynh_dev_dir}
fi

# ssowat
if [ "$dir_to_mount" == "ssowat" ] || [ "$dir_to_mount" == "all" ]
then
	create_sym_link "${ynh_dev_dir}/ssowat" "/usr/share/ssowat"
	mount_directory
	echo_success "Now using Git repository for SSOwat"
fi

# moulinette
if [ "$dir_to_mount" == "moulinette" ] || [ "$dir_to_mount" == "all" ]
then
	create_sym_link "${ynh_dev_dir}/moulinette/locales" "/usr/share/moulinette/locale"
	create_sym_link "${ynh_dev_dir}/moulinette/moulinette" "/usr/lib/python2.7/dist-packages/moulinette"
	mount_directory
	echo_success "Now using Git repository for Moulinette"
fi

# yunohost
if [ "$dir_to_mount" == "yunohost" ] || [ "$dir_to_mount" == "all" ]
then
	# bin
	create_sym_link "${ynh_dev_dir}/yunohost/bin/yunohost" "/usr/bin/yunohost"
	create_sym_link "${ynh_dev_dir}/yunohost/bin/yunohost-api" "/usr/bin/yunohost-api"

	# data
	create_sym_link "${ynh_dev_dir}/yunohost/data/bash-completion.d/yunohost" "/etc/bash_completion.d/yunohost"
	create_sym_link "${ynh_dev_dir}/yunohost/data/actionsmap/yunohost.yml" "/usr/share/moulinette/actionsmap/yunohost.yml"
	create_sym_link "${ynh_dev_dir}/yunohost/data/hooks" "/usr/share/yunohost/hooks"
	create_sym_link "${ynh_dev_dir}/yunohost/data/templates" "/usr/share/yunohost/templates"
	create_sym_link "${ynh_dev_dir}/yunohost/data/helpers" "/usr/share/yunohost/helpers"
	create_sym_link "${ynh_dev_dir}/yunohost/data/helpers.d" "/usr/share/yunohost/helpers.d"
	create_sym_link "${ynh_dev_dir}/yunohost/data/other" "/usr/share/yunohost/yunohost-config/moulinette"

	# debian
	create_sym_link "${ynh_dev_dir}/yunohost/debian/conf/pam/mkhomedir" "/usr/share/pam-configs/mkhomedir"

	# lib
	create_sym_link "${ynh_dev_dir}/yunohost/lib/metronome/modules/ldap.lib.lua" "/usr/lib/metronome/modules/ldap.lib.lua"
	create_sym_link "${ynh_dev_dir}/yunohost/lib/metronome/modules/mod_auth_ldap2.lua" "/usr/lib/metronome/modules/mod_auth_ldap2.lua"
	create_sym_link "${ynh_dev_dir}/yunohost/lib/metronome/modules/mod_legacyauth.lua" "/usr/lib/metronome/modules/mod_legacyauth.lua"
	create_sym_link "${ynh_dev_dir}/yunohost/lib/metronome/modules/mod_storage_ldap.lua" "/usr/lib/metronome/modules/mod_storage_ldap.lua"
	create_sym_link "${ynh_dev_dir}/yunohost/lib/metronome/modules/vcard.lib.lua" "/usr/lib/metronome/modules/vcard.lib.lua"

	# src
	create_sym_link "${ynh_dev_dir}/yunohost/src/yunohost" "/usr/lib/moulinette/yunohost"

	# locales
	create_sym_link "${ynh_dev_dir}/yunohost/locales" "/usr/lib/moulinette/yunohost/locales"

	mount_directory

	echo_success "Now using Git repository for YunoHost"
fi

# yunohost-admin
if [ "$dir_to_mount" == "yunohost-admin" ] || [ "$dir_to_mount" == "all" ]
then
	create_sym_link "${ynh_dev_dir}/yunohost-admin/src" "/usr/share/yunohost/admin"

	mount_directory

	getent passwd ynhdev > /dev/null
	if [ $? -eq 2 ]; then
		sudo useradd ynhdev
	fi

	bower_dir=$(mktemp --directory)
	sudo chmod 755 $bower_dir
	sudo mkdir -p ${ynh_dev_dir}/yunohost-admin/src/bower_components
	sudo mount -o bind $bower_dir ${ynh_dev_dir}/yunohost-admin/src/bower_components
	sudo chown -R ynhdev: ${ynh_dev_dir}/yunohost-admin/src/bower_components

	dist_dir=$(mktemp --directory)
	sudo chmod 755 $dist_dir
	sudo mkdir -p ${ynh_dev_dir}/yunohost-admin/src/dist
	sudo mount -o bind $dist_dir ${ynh_dev_dir}/yunohost-admin/src/dist
	sudo chown -R ynhdev: ${ynh_dev_dir}/yunohost-admin/src/dist

	pushd ${ynh_dev_dir}/yunohost-admin/src
	# Install npm dependencies if needed
	which gulp > /dev/null
	if [ $? -eq 1 ]
	then
		echo_info "Installing dependencies to develop in yunohost-admin ..."

		curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
		sudo apt install nodejs

		sudo npm install --no-bin-links
		sudo npm install -g bower
		sudo npm install -g gulp
	fi
	sudo su -c "bower install" ynhdev
	sudo npm install gulp --no-bin-links
	sudo npm install --no-bin-links
	sudo su -c "gulp build --dev" ynhdev

	echo_success "Now using Git repository for yunohost-admin"

	if [ $build_only -eq 0 ]
	then
		echo_warn "-------------------------------------------------------- "
		echo_warn "Launching gulp ...                                       "
		echo_warn "NB : This command will keep running and watch for changes"
		echo_warn " in the folder ${ynh_dev_dir}/yunohost-admin/src, such that you"
		echo_warn "don't need to re-run npm yourself everytime you change   "
		echo_warn "something !                                              "
		echo_warn "-------------------------------------------------------- "
		sudo su -c "gulp watch --dev" ynhdev
	fi

	sudo umount ${ynh_dev_dir}/yunohost-admin/src/bower_components
	sudo umount ${ynh_dev_dir}/yunohost-admin/src/dist

	popd
fi
