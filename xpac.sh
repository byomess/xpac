#!/bin/bash

# Define constants
XPAC_HOME="$(dirname "$0")/../lib/xpac"
INTERNAL_PACKAGES_FILE="$XPAC_HOME/internal_packages.json"
INTERNAL_PACKAGES_DIR="$XPAC_HOME/internal_packages"
INTERNAL_PACKAGES_SETUP_DIR="$XPAC_HOME/internal_packages/setup"
INTERNAL_PACKAGES_TEARDOWN_DIR="$XPAC_HOME/internal_packages/teardown"

package_manager=""
distro_name=""

# Function to install internal package
install_internal_package() {
	local package="$1"
	local setup_script="$INTERNAL_PACKAGES_SETUP_DIR/$package.sh"

	if [ -f "$setup_script" ]; then
		cat "$setup_script" | bash
	else
		echo "Internal package $package does not have a setup script"
	fi
}

# Function to uninstall internal package
uninstall_internal_package() {
	local package="$1"
	local teardown_script="$INTERNAL_PACKAGES_TEARDOWN_DIR/$package.sh"

	if [ -f "$teardown_script" ]; then
		cat "$teardown_script" | bash
	else
		echo "Internal package $package does not have a teardown script"
	fi
}

# Function to handle installation of distro packages
install_distro_package() {
	local packages="$@"
	case "$package_manager" in
	yay) yay -S "$packages" ;;
	pacman) pacman -S "$packages" ;;
	pkg) pkg install "$packages" ;;
	apt) apt install "$packages" ;;
	dnf) dnf install "$packages" ;;
	yum) yum install "$packages" ;;
	zypper) zypper install "$packages" ;;
	*) echo "Unknown package manager" ;;
	esac
}

# Function to uninstall distro packages
uninstall_distro_package() {
	local packages="$@"
	case "$package_manager" in
	yay) yay -R "$packages" ;;
	pacman) pacman -R "$packages" ;;
	apt) apt remove "$packages" ;;
	dnf) dnf remove "$packages" ;;
	yum) yum remove "$packages" ;;
	zypper) zypper remove "$packages" ;;
	*) echo "Uninstall command not supported for this package manager" ;;
	esac
}

# Function to purge distro packages
purge_distro_package() {
	local packages="$@"
	case "$package_manager" in
	yay) yay -Rns "$packages" ;;
	pacman) pacman -Rns "$packages" ;;
	apt) apt purge "$packages" ;;
	*) echo "Purge command not supported for this package manager" ;;
	esac
}

install_package() {
	internal_packages_json=$(cat "$INTERNAL_PACKAGES_FILE" | jq -r '.[]')

	packages_to_install="$@"

	for package_to_install in $packages_to_install; do
		internal_package_json=$(echo "$internal_packages_json" | jq -r '. | select(.name == "'$package_to_install'")')

		if [ -n "$internal_package_json" ]; then
			install_internal_package "$package_to_install"
		else
			install_distro_package "$package_to_install"
		fi
	done
}

uninstall_package() {
	internal_packages_json=$(cat "$INTERNAL_PACKAGES_FILE" | jq -r '.[]')

	packages_to_uninstall="$@"

	for package_to_uninstall in $packages_to_uninstall; do
		internal_package_json=$(echo "$internal_packages_json" | jq -r '. | select(.name == "'$package_to_uninstall'")')

		if [ -n "$internal_package_json" ]; then
			uninstall_internal_package "$package_to_uninstall"
		else
			uninstall_distro_package "$package_to_uninstall"
		fi
	done
}

purge_package() {
	internal_packages_json=$(cat "$internal_packages_file" | jq -r '.[]')

	packages_to_purge="$@"

	for package_to_purge in $packages_to_purge; do
		internal_package_json=$(echo "$internal_packages_json" | jq -r '. | select(.name == "'$package_to_purge'")')

		if [ -n "$internal_package_json" ]; then
			purge_internal_package "$package_to_purge"
		else
			purge_distro_package "$package_to_purge"
		fi
	done
}

search_packages() {
	local query="$@"
	case "$package_manager" in
	yay) yay -Ss "$query" ;;
	pacman) pacman -Ss "$query" ;;
	pkg) pkg search "$query" ;;
	apt) apt search "$query" ;;
	*)
		echo "Search command not supported for this package manager"
		;;
	esac
}

search_installed_packages() {
	local query="$@"
	case "$package_manager" in
	yay) yay -Qs "$query" ;;
	pacman) pacman -Qs "$query" ;;
	apt) apt list --installed "$query" ;;
	dnf) dnf list installed "$query" ;;
	yum) yum list installed "$query" ;;
	zypper) zypper search --installed-only "$query" ;;
	*)
		echo "Search installed command not supported for this package manager"
		;;
	esac
}

update_package_list() {
	case "$package_manager" in
	yay) yay -Sy ;;
	pacman) pacman -Sy ;;
	apt) apt update ;;
	dnf) dnf check-update ;;
	yum) yum check-update ;;
	zypper) zypper refresh ;;
	*)
		echo "Update package list command not supported for this package manager"
		;;
	esac
}

upgrade_packages() {
	case "$package_manager" in
	yay) yay -Syu ;;
	pacman) pacman -Syu ;;
	apt) apt upgrade ;;
	dnf) dnf upgrade ;;
	yum) yum upgrade ;;
	zypper) zypper update ;;
	*)
		echo "Upgrade packages command not supported for this package manager"
		;;
	esac
}

update_upgrade_packages() {
	case "$package_manager" in
	yay) yay -Syu ;;
	pacman) pacman -Syu ;;
	apt) apt update && apt upgrade ;;
	dnf) dnf check-update && dnf upgrade ;;
	yum) yum check-update && yum upgrade ;;
	zypper) zypper refresh && zypper update ;;
	*)
		echo "Update and upgrade packages command not supported for this package manager"
		;;
	esac
}

list_all_packages() {
	case "$package_manager" in
	yay) yay -Sl ;;
	pacman) pacman -Sl ;;
	apt) apt list ;;
	dnf) dnf list ;;
	yum) yum list ;;
	zypper) zypper search ;;
	*)
		echo "List all packages command not supported for this package manager"
		;;
	esac
}

list_installed_packages() {
	case "$package_manager" in
	yay) yay -Qe ;;
	pacman) pacman -Qe ;;
	apt) apt list --installed ;;
	dnf) dnf list installed ;;
	yum) yum list installed ;;
	zypper) zypper search --installed-only ;;
	*) echo "List installed packages command not supported for this package manager" ;;
	esac
}

show_package_info() {
	local package="$@"
	case "$package_manager" in
	yay) yay -Si "$package" ;;
	pacman) pacman -Si "$package" ;;
	pkg) pkg info "$package" ;;
	apt) apt show "$package" ;;
	dnf) dnf info "$package" ;;
	yum) yum info "$package" ;;
	zypper) zypper info "$package" ;;
	*) echo "Show package info command not supported for this package manager" ;;
	esac
}

list_package_files() {
	case "$package_manager" in
	yay) yay -Ql $@ ;;
	pacman) pacman -Ql $@ ;;
	pkg) pkg listfiles $@ ;;
	apt) apt listfiles $@ ;;
	dnf) dnf repoquery --list $@ ;;
	yum) yum list files $@ ;;
	zypper) zypper search --details $@ ;;
	*) echo "List package files not supported for this package manager" ;;
	esac
}

list_package_commands() {
	case "$package_manager" in
	yay) yay -Ql $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	pacman) pacman -Ql $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	pkg) pkg listfiles $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	apt) apt listfiles $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	dnf) dnf repoquery --list $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	yum) yum list files $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	zypper) zypper search --details $@ | sed -n -e 's/.*\/bin\///p' | tail -n +2 ;;
	*) echo "List package commands not supported for this package manager" ;;
	esac
}

clean_cache() {
	case "$package_manager" in
	yay) yay -Sc ;;
	pacman) pacman -Sc ;;
	pkg) pkg clean ;;
	apt) apt clean ;;
	dnf) dnf clean all ;;
	yum) yum clean all ;;
	zypper) zypper clean ;;
	*)
		echo "Clean cache command not supported for this package manager"
		;;
	esac
}

autoremove() {
	case "$package_manager" in
	yay) yay -Yc ;;
	pacman) pacman -Qdtq | pacman -Rs - ;;
	pkg) pkg autoremove ;;
	apt) apt autoremove ;;
	dnf) dnf autoremove ;;
	yum) yum autoremove ;;
	zypper) zypper remove --clean-deps-only ;;
	*)
		echo "Autoremove command not supported for this package manager"
		;;
	esac
}

# Function to handle installation, uninstallation, and purging of packages
handle_package_action() {
	local action="$1"
	local packages=${@:2}

	case "$action" in
	install | i | add) install_package "$packages" ;;
	uninstall | remove | rm | delete | del) uninstall_package "$packages" ;;
	purge | pu | p) purge_package "$packages" ;;
	search | s | find | f | query | q) search_packages "$packages" ;;
	search-installed | si | find-installed | fi | query-installed | qi | search-local | sl | find-local | fl | query-local | ql) search_installed_packages "$packages" ;;
	update | upd | ud) update_package_list ;;
	upgrade | upg | ug) upgrade_packages ;;
	update-upgrade | uu) update_upgrade_packages ;;
	list | ls | l) list_all_packages ;;
	list-installed | li | lsi) list_installed_packages ;;
	list-files | lf) list_package_files "$packages" ;;
	list-commands | lc) list_package_commands "$packages" ;;
	show | sh | info | in) show_package_info "$packages" ;;
	clean | clear | c) clean_cache ;;
	autoremove | ar) autoremove ;;
	help | h) display_usage ;;
	*) echo "Unknown action: $action" ;;
	esac
}

# Function to display usage instructions
display_usage() {
	echo "Usage: xpac [command] [package]"
	echo
	echo "Commands:"
	echo "  install,i,add - install package"
	echo "  remove,rm,delete,del - remove package"
	echo "  purge,pu,p - remove package, its configuration files and dependencies"
	echo "  search,s,find,f,query,q - search available packages"
	echo "  search-installed,si,find-installed,fi,query_installed,qi - search installed packages"
	echo "  update,ud - update package list"
	echo "  upgrade,ug - upgrade packages"
	echo "  update-upgrade,uu - update and upgrade"
	echo "  list,ls,l - list all available packages"
	echo "  list-installed,li,lsi - list installed packages"
	echo "  show,sh,info,i - show package info"
	echo "  clean,clear,c - clean cache"
	echo "  autoremove - remove packages that were installed as dependencies but are no longer needed"
	echo "  help,h - show help"
	echo
	echo "Options:"
	echo "  -h, --help - show help"
	echo "  -v, --version - show version"
	echo
	echo "Examples:"
	echo "  xpac install firefox"
	echo "  xpac remove firefox"
	echo "  xpac search firefox"
	echo "  xpac update"
	echo "  xpac upgrade"
	echo "  xpac update_upgrade"
	echo "  xpac list"
	echo "  xpac list_installed"
	echo "  xpac show firefox"
	echo "  xpac clean"
	echo "  xpac autoremove"
	echo "  xpac help"
	echo
	echo "For more information, see: https://github.com/byomess/xpac"
}

# Function to determine the package manager
get_package_manager() {
	if command -v yay &>/dev/null; then
		echo "yay"
	elif command -v pacman &>/dev/null; then
		echo "pacman"
	elif command -v pkg &>/dev/null; then
		echo "pkg"
	elif command -v apt &>/dev/null; then
		echo "apt"
	elif command -v dnf &>/dev/null; then
		echo "dnf"
	elif command -v yum &>/dev/null; then
		echo "yum"
	elif command -v zypper &>/dev/null; then
		echo "zypper"
	else
		echo "Unknown package manager"
	fi
}

# Function to get the name of the Linux distribution
get_distro_name() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		echo $NAME
	else
		echo "unknown"
	fi
}

parse_args() {
	while [ "$1" != "" ]; do
		case $1 in
		-h | --help | help | h)
			display_usage
			exit 0
			;;
		-v | --version)
			echo "xpac 0.1.0"
			exit 0
			;;
		*)
			return
			;;
		esac
	done
}

# Set package manager
package_manager=$(get_package_manager)

parse_args "$@"

# Call main function
handle_package_action "$@"
