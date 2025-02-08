#!/usr/bin/env bash

# Constants
XPAC_VERSION="0.1.0"
XPAC_HOME="$(dirname "$0")/../share/xpac"  # Path to xpac's shared directory.
INTERNAL_PACKAGES_FILE="$XPAC_HOME/internal_packages.json"  # Path to the JSON file listing internal packages.
INTERNAL_PACKAGES_DIR="$XPAC_HOME/internal_packages" # Directory for internal packages.
INTERNAL_PACKAGES_SETUP_DIR="$INTERNAL_PACKAGES_DIR/setup"  # Directory for internal package setup scripts.
INTERNAL_PACKAGES_TEARDOWN_DIR="$INTERNAL_PACKAGES_DIR/teardown" # Directory for internal package teardown scripts.
USER_INTERNAL_PACKAGES_DIR="$HOME/.local/share/xpac/internal_packages" # Directory for user-installed internal packages

# Globals
package_manager=""  # Will hold the detected package manager (e.g., apt, pacman).
distro_name=""      # Will hold the detected Linux distribution name.

# --- Helper Functions ---

# Display usage information.
display_usage() {
  cat <<EOF
Usage: xpac [command] [package]

Commands:
  install, i, add				- Install package(s)
  remove, rm, del       - Remove package(s)
  purge, pu, p         	- Remove package(s) and their configuration files
  search, s, find, f   	- Search available packages
  search-installed, si  - Search installed packages
  update, ud            - Update package list
  upgrade, ug           - Upgrade all packages
  update-upgrade, uu   	- Update package list and upgrade all packages
  list, ls, l          	- List all available packages
  list-installed, li   	- List installed packages
  list-files, lf        - List files belonging to a package
  list-commands, lc     - List commands (binaries) provided by a package
  show, sh, info, inf  	- Show package information
  clean-cache, cc       - Clean the package cache
  autoremove, ar       	- Remove unused dependencies

Options:
  -h, --help            - Show this help message
  -v, --version         - Show version information

Examples:
  xpac install firefox
  xpac remove firefox
  xpac search firefox
  xpac update-upgrade

For more information, see: https://github.com/byomess/xpac
EOF
}

# Determine the system's package manager.
# Returns:
#   The name of the package manager, or "unknown" if none is found.
get_package_manager() {
  local managers=("yay" "pacman" "pkg" "apt" "dnf" "yum" "zypper")
  for manager in "${managers[@]}"; do
    if command -v "$manager" &>/dev/null; then
      echo "$manager"
      return 0
    fi
  done
  echo "unknown"
  return 1
}

# Get the name of the Linux distribution.
# Returns:
#   The distribution name, or "unknown" if it cannot be determined.
get_distro_name() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$NAME"
  else
    echo "unknown"
  fi
}

# --- Internal Package Management ---

# Executes a script for an internal package (setup or teardown).
# Args:
#   1: script_path - The full path to the script to execute.
run_internal_package_script() {
  local script_path="$1"

  if [ -f "$script_path" ]; then
    bash "$script_path" # Source the script directly for better environment control
  else
    echo "Error: Script not found: $script_path" >&2
    return 1
  fi
}

# Install an internal package.
# Args:
#   1: package - The name of the internal package.
install_internal_package() {
  local package="$1"
  local script_path="$INTERNAL_PACKAGES_SETUP_DIR/$package.sh"
  run_internal_package_script "$script_path"
}

# Uninstall an internal package.
# Args:
#   1: package - The name of the internal package.
uninstall_internal_package() {
  local package="$1"
  local script_path="$INTERNAL_PACKAGES_TEARDOWN_DIR/$package.sh"
  run_internal_package_script "$script_path"
}

# --- Distro Package Management ---

# Run a package manager command, handling common errors.
# Args:
#   1: command - The command name (e.g., "install", "remove").
#   2+: packages - The package(s) to operate on.
run_package_manager_command() {
	local command="$1"
	shift
	local packages="$@"

	if [ -z "$packages" ]; then
		echo "Error: No packages specified for $command." >&2
		return 1
	fi

	case "$package_manager" in
	yay)
		yay -S --needed "$packages"
		;;
	pacman)
		pacman -S --needed "$packages"
		;;
	pkg)
		pkg "$command" "$packages"
		;;
	apt)
		apt "$command" -y "$packages"
		;;
	dnf | yum)
		"$package_manager" "$command" -y "$packages"
		;;
	zypper)
		zypper --non-interactive "$command" "$packages"
		;;
	*)
		echo "Error: '$package_manager' does not support the '$command' command." >&2
		return 1
		;;
	esac
}

# Install distribution packages.
# Args:
#   1+: packages - The name(s) of the package(s) to install.
install_distro_package() {
  run_package_manager_command "install" "$@"
}
# Uninstall distribution packages.
# Args:
#   1+: packages - The name(s) of the package(s) to uninstall.
uninstall_distro_package() {
    # Different command structure for yay/pacman
	if [[ "$package_manager" == "yay" || "$package_manager" == "pacman" ]]; then
		local packages="$@"
		"$package_manager" -R "$packages"
	else
		run_package_manager_command "remove" "$@"
	fi
}

# Purge distribution packages (remove config files).
# Args:
#   1+: packages - The name(s) of the package(s) to purge.
purge_distro_package() {
    # Different command structure for yay/pacman
	if [[ "$package_manager" == "yay" || "$package_manager" == "pacman" ]]; then
		local packages="$@"
		"$package_manager" -Rns "$packages"
	elif [[ "$package_manager" == "apt" ]]; then
		run_package_manager_command "purge" "$@"
	else
		# For other managers, a simple remove is the best we can do.
		uninstall_distro_package "$@"
	fi
}

# Search for packages.
# Args:
#    1+: query - Search terms.
search_packages() {
	local query="$@"
	case "$package_manager" in
	yay | pacman) "$package_manager" -Ss "$query" ;;
	pkg)          pkg search "$query" ;;
	apt)          apt search "$query" ;;
	dnf)          dnf search "$query" ;;
	yum)          yum search "$query" ;;
	zypper)       zypper search "$query" ;;
	*)            echo "Search command not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# Search installed packages.
# Args:
#    1+: query - Search terms.
search_installed_packages() {
	local query="$@"
	case "$package_manager" in
	yay | pacman) "$package_manager" -Qs "$query" ;;
	pkg)          pkg info -a | grep -i "$query" ;; # pkg doesn't have a direct search installed.
	apt)          apt list --installed 2>/dev/null | grep "$query" ;;
	dnf | yum)    "$package_manager" list installed "$query" ;;
	zypper)       zypper search --installed-only "$query" ;;
	*)            echo "Search installed command not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# Update the package list.
update_package_list() {
	case "$package_manager" in
	yay | pacman) "$package_manager" -Sy ;;
	pkg)          pkg update ;;
	apt)          apt update ;;
	dnf | yum)    "$package_manager" check-update ;;
	zypper)       zypper refresh ;;
	*)            echo "Update package list command not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# Upgrade all packages.
upgrade_packages() {
	case "$package_manager" in
	yay | pacman) "$package_manager" -Syu ;;
	pkg)          pkg upgrade ;;
	apt)          apt upgrade -y ;;
	dnf | yum)    "$package_manager" upgrade -y ;;
	zypper)       zypper update --non-interactive ;;  # Use non-interactive for scripting
	*)            echo "Upgrade packages command not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# Update package list and upgrade packages.
update_upgrade_packages() {
  update_package_list && upgrade_packages
}

# List all available packages.
list_all_packages() {
	case "$package_manager" in
	yay | pacman) "$package_manager" -Sl ;;
	pkg)          pkg rquery "%n-%v" ;;  # pkg: Show all remote packages.
	apt)          apt list  ;;
	dnf | yum)    "$package_manager" list all ;;
	zypper)       zypper search --type package ;;
	*)            echo "List all packages command not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# List installed packages.
list_installed_packages() {
	case "$package_manager" in
	yay | pacman) "$package_manager" -Qe ;;
	pkg)          pkg query "%n-%v" ;; # pkg: Show installed packages
	apt)          apt list --installed ;;
	dnf | yum)    "$package_manager" list installed ;;
	zypper)       zypper search --installed-only --type package ;;
	*)            echo "List installed packages command not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# Show package information.
# Args:
#   1: package - The name of the package.
show_package_info() {
	local package="$1"
	if [ -z "$package" ]; then
		echo "Error: No package specified for showing info." >&2
		return 1
	fi
	case "$package_manager" in
	yay | pacman) "$package_manager" -Si "$package" ;;
	pkg)          pkg info "$package" ;;
	apt)          apt show "$package" ;;
	dnf | yum)    "$package_manager" info "$package" ;;
	zypper)       zypper info "$package" ;;
	*)            echo "Show package info command not supported for '$package_manager'." >&2; return 1;;
	esac
}

# List files belonging to a package
# Args:
#  1: package - The name of the package.
list_package_files() {
  local package="$1"
  if [ -z "$package" ]; then
    echo "Error: No package specified for listing files." >&2
    return 1
  fi
	case "$package_manager" in
		yay | pacman) "$package_manager" -Ql "$package" ;;
		pkg)          pkg info -l "$package" ;;
		apt)		  dpkg -L "$package"  ;;
		dnf) 		  dnf repoquery --list "$package" ;;
		yum)          rpm -ql "$package" ;;
		zypper)       zypper info --provides "$package" ;; # Best approximation.  zypper doesn't have direct file listing.
		*)            echo "List package files not supported for '$package_manager'." >&2 ; return 1;;
	esac
}

# List commands (executable files in /bin) provided by a package
# Args:
#    1: package_name - The name of the package
list_package_commands() {
	local package="$1"
	if [ -z "$package" ]; then
		echo "Error: No package specified for listing commands." >&2
		return 1
	fi

	# Get the list of files and filter for those in /bin directories.
	list_package_files "$package" | grep -E '/(usr/)?bin/' | xargs basename
}
# Clean the package cache.
clean_cache() {
	case "$package_manager" in
	yay | pacman) "$package_manager" -Sc ;;
	pkg)          pkg clean -a ;;   # Clean all cached packages
	apt)          apt clean ;;
	dnf)          dnf clean all ;;
	yum)          yum clean all ;;
	zypper)       zypper clean --all ;; # Clean all repos
	*)            echo "Clean cache command not supported for '$package_manager'." >&2 ; return 1;;
	esac
}

# Remove unused dependencies.
autoremove() {
	case "$package_manager" in
	yay)          yay -Yc ;;
	pacman)       pacman -Qdtq | pacman -Rs - ;;  #  Remove orphaned packages.
	pkg)          pkg autoremove ;;
	apt)          apt autoremove -y ;;
	dnf | yum)    "$package_manager" autoremove -y ;;
	zypper)       zypper remove --clean-deps --non-interactive ;;
	*)            echo "Autoremove command not supported for '$package_manager'." >&2 ; return 1;;
	esac
}
# --- Main Logic ---

# Check if a package name refers to an internal package.
# Args:
#  1: package_name - Name of the package
# Returns:
#  0 if internal, 1 otherwise
is_internal_package() {
  local package_name="$1"
  [ -f "$INTERNAL_PACKAGES_SETUP_DIR/$package_name.sh" ] || [ -f "$INTERNAL_PACKAGES_TEARDOWN_DIR/$package_name.sh" ]
}

# Install a package (either internal or distro).
# Args:
#   1+: packages - The name(s) of the package(s) to install.
install_package() {
  for pkg in "$@"; do
    if is_internal_package "$pkg"; then
      install_internal_package "$pkg"
    else
      install_distro_package "$pkg"
    fi
  done
}

# Uninstall a package (either internal or distro).
# Args:
#   1+: packages - The name(s) of the package(s) to uninstall.
uninstall_package() {
  for pkg in "$@"; do
    if is_internal_package "$pkg"; then
      uninstall_internal_package "$pkg"
    else
      uninstall_distro_package "$pkg"
    fi
  done
}

# Purge a package (either internal or distro).
# Args:
#   1+: packages - The name(s) of the package(s) to purge.
purge_package() {
  for pkg in "$@"; do
    if is_internal_package "$pkg"; then
      uninstall_internal_package "$pkg"  # Internal packages don't have a separate purge.
    else
      purge_distro_package "$pkg"
    fi
  done
}

# Search for a package and let the user select one to install.
# Args:
#   1: package - The name of the package to search for.
selective_install_package() {
	local package="$1"
	case "$package_manager" in
		yay) "$package_manager" "$package" ;;
		*)   echo "Selective package installation not supported for '$package_manager'." >&2; return 1 ;;
	esac
}

# Handle the main package action based on user input.
# Args:
#   1: action - The action to perform (e.g., "install", "remove").
#   2+: packages - The package(s) to operate on.
handle_package_action() {
  local action="${1:-update-upgrade}"  # Default to update-upgrade if no action is provided.
  shift
  local packages="$@"

  # Remove leading hyphens from action.
  action=$(echo "$action" | sed 's/^-*//')

  case "$action" in
    install | i | add)				install_package "$packages" ;;
    remove | rm | del)        uninstall_package "$packages" ;;
    purge | pu | p)           purge_package "$packages" ;;
    search | s | find | f)    search_packages "$packages" ;;
    search-installed | si)   	search_installed_packages "$packages" ;;
    update | ud)             	update_package_list ;;
    upgrade | ug)            	upgrade_packages ;;
    update-upgrade | uu)    	update_upgrade_packages ;;
    list | ls | l)           	list_all_packages ;;
    list-installed | li)    	list_installed_packages ;;
    list-files | lf)         	list_package_files "$packages" ;;
    list-commands | lc)      	list_package_commands "$packages" ;;
    show | sh | info | inf)  	show_package_info "$packages" ;;
    clean-cache | cc)        	clean_cache ;;
    autoremove | ar)          autoremove ;;
    help | h)                	display_usage ;;
    version | v)            	echo "xpac version $XPAC_VERSION" ;;
    # *)                      	echo "Error: Unknown action '$action'." >&2; display_usage; return 1 ;;
		*)                      	selective_install_package "$action" ;;
  esac
}

# --- Script Execution ---
package_manager=$(get_package_manager)
if [ "$package_manager" = "unknown" ]; then
  echo "Error: Could not detect a supported package manager." >&2
  exit 1
fi

distro_name=$(get_distro_name)

handle_package_action "$@"

exit 0
