#!/usr/bin/env bash

# --- Constants ---
readonly XPAC_VERSION="0.2.0"
readonly XPAC_HOME="$(dirname "$0")/../share/xpac"                  		# Path to xpac's shared directory.
readonly INTERNAL_PACKAGES_FILE="$XPAC_HOME/internal_packages.json" 		# Path to the JSON file listing internal packages.
readonly INTERNAL_PACKAGES_DIR="$XPAC_HOME/internal_packages"       		# Directory for internal packages.
readonly INTERNAL_PACKAGES_SETUP_DIR="$INTERNAL_PACKAGES_DIR/setup"   		# Directory for internal package setup scripts.
readonly INTERNAL_PACKAGES_TEARDOWN_DIR="$INTERNAL_PACKAGES_DIR/teardown" 	# Directory for internal package teardown scripts.

# --- Globals ---
declare package_manager="" # Detected package manager (e.g., apt, pacman).
declare distro_name=""     # Detected Linux distribution name.
declare -A dep_map         # Associative array for dependency package names

# --- Dependency Package Name Mappings ---
# Format: dep_map[command,package_manager]=package_name
dep_map[ping,apt]="iputils-ping"
dep_map[ping,pacman]="inetutils"
dep_map[ping,dnf]="iputils"
dep_map[ping,yum]="iputils"
dep_map[ping,zypper]="iputils"
dep_map[ping,pkg]="inetutils"

dep_map[hostname,apt]="hostname"
dep_map[hostname,pacman]="inetutils"
dep_map[hostname,dnf]="hostname"
dep_map[hostname,yum]="hostname"
dep_map[hostname,zypper]="hostname"
dep_map[hostname,pkg]="inetutils"

dep_map[ip,apt]="iproute2"
dep_map[ip,pacman]="iproute2"
dep_map[ip,dnf]="iproute2"
dep_map[ip,yum]="iproute2"
dep_map[ip,zypper]="iproute2"
dep_map[ip,pkg]="iproute2"

dep_map[ifconfig,apt]="net-tools"
dep_map[ifconfig,pacman]="net-tools"
dep_map[ifconfig,dnf]="net-tools"
dep_map[ifconfig,yum]="net-tools"
dep_map[ifconfig,zypper]="net-tools"
dep_map[ifconfig,pkg]="net-tools"

dep_map[lscpu,apt]="util-linux"
dep_map[lscpu,pacman]="util-linux"
dep_map[lscpu,dnf]="util-linux"
dep_map[lscpu,yum]="util-linux"
dep_map[lscpu,zypper]="util-linux"
dep_map[lscpu,pkg]="util-linux"

dep_map[free,apt]="procps"
dep_map[free,pacman]="procps-ng"
dep_map[free,dnf]="procps-ng"
dep_map[free,yum]="procps-ng"
dep_map[free,zypper]="procps"
dep_map[free,pkg]="procps-ng"

dep_map[uptime,apt]="procps"
dep_map[uptime,pacman]="procps-ng"
dep_map[uptime,dnf]="procps-ng"
dep_map[uptime,yum]="procps-ng"
dep_map[uptime,zypper]="procps"
dep_map[uptime,pkg]="procps-ng"

dep_map[ps,apt]="procps"
dep_map[ps,pacman]="procps-ng"
dep_map[ps,dnf]="procps-ng"
dep_map[ps,yum]="procps-ng"
dep_map[ps,zypper]="procps"
dep_map[ps,pkg]="procps-ng"

dep_map[df,apt]="coreutils"
dep_map[df,pacman]="coreutils"
dep_map[df,dnf]="coreutils"
dep_map[df,yum]="coreutils"
dep_map[df,zypper]="coreutils"
dep_map[df,pkg]="coreutils"

dep_map[uname,apt]="coreutils"
dep_map[uname,pacman]="coreutils"
dep_map[uname,dnf]="coreutils"
dep_map[uname,yum]="coreutils"
dep_map[uname,zypper]="coreutils"
dep_map[uname,pkg]="coreutils"

dep_map[rpm,apt]="rpm"
dep_map[rpm,pacman]="rpm-tools"
dep_map[rpm,dnf]="rpm"
dep_map[rpm,yum]="rpm"
dep_map[rpm,zypper]="rpm"
dep_map[rpm,pkg]=""

dep_map[dpkg,apt]="dpkg"
dep_map[dpkg,pacman]=""
dep_map[dpkg,dnf]=""
dep_map[dpkg,yum]=""
dep_map[dpkg,zypper]=""
dep_map[dpkg,pkg]=""


# --- Helper Functions ---

# Description: Prints an error message to stderr.
# Args: $*: The error message components.
_err() {
  echo "Error: $*" >&2
}

# Description: Prints an info message to stdout.
# Args: $*: The message components.
_info() {
  echo "Info: $*"
}

# Description: Prepends sudo to arguments if not root and not using yay.
# Args: $@: Command and arguments to potentially prefix with sudo.
# Outputs: Command prefixed with sudo if necessary.
_maybe_sudo() {
    if [[ "$EUID" -eq 0 || "$package_manager" == "yay" ]]; then
        echo "$@"
    else
        echo "sudo" "$@"
    fi
}

# Description: Checks if a command exists, prompts to install if missing.
# Args: $1: command_name, $2: friendly_name (optional)
# Returns: 0 if command exists or was successfully installed, 1 otherwise.
_require_command() {
    local cmd="$1"
    local friendly_name="${2:-$1}"
    local package_name=""
    local answer

    if command -v "$cmd" &>/dev/null; then return 0; fi

    package_name="${dep_map[$cmd,$package_manager]}"

    if [ -z "$package_name" ] && [[ "$package_manager" == "yay" ]]; then
        _info "No specific mapping for '$cmd' under 'yay', checking 'pacman' mapping..."
        package_name="${dep_map[$cmd,pacman]}"
    fi

    if [ -n "$package_name" ]; then
        if [[ "$package_manager" == "pkg" ]]; then
             _info "Command '$cmd' not found. Required package might be '$package_name'."
             _info "Automatic installation via pkg is less reliable for utils; please install manually if needed."
        fi

        read -rp "Command '$cmd' not found. Package '$package_name' may provide it. Install '$package_name'? [Y/n] " answer

        if [[ "$answer" =~ ^[Yy]$|^$ ]]; then
            _info "Attempting to install '$package_name'..."
            if install_distro_package "$package_name"; then
                if command -v "$cmd" &>/dev/null; then
                    _info "'$package_name' installed successfully."
                    return 0
                else
                    _err "Installation of '$package_name' reported success, but command '$cmd' is still not found."
                    _info "You might need to re-login or run 'hash -r'."
                    return 1
                fi
            else
                _err "Failed to install '$package_name'."
                return 1
            fi
        else
            _info "Installation cancelled. Cannot proceed without '$cmd'."
            return 1
        fi
    else
        case "$cmd" in
            uname|df|ps|free|uptime|ls|grep|awk|sed|head|tail|cat|echo|printf)
                 _err "Critical command '$cmd' not found. This indicates a broken base system or PATH issue."
                 return 1;;
            hostname|rpm|dpkg)
                 _err "Command '$cmd' not found, and no package mapping defined for '$package_manager' or 'pacman' fallback."
                 _info "Please try installing the appropriate package manually (e.g., '$cmd', 'rpm-tools', 'inetutils', 'dpkg')."
                 return 1;;
             *)
                _err "Command '$cmd' not found, and no package mapping defined for '$package_manager' or 'pacman' fallback."
                _info "Please try installing '$friendly_name' or the package providing it manually."
                return 1;;
        esac
    fi
}

# Description: Displays usage information and exits.
display_usage() {
  cat <<EOF
Usage: xpac [command] [args...]

Package Management Commands:
  install, i, add        - Install package(s)
  remove, rm, del        - Remove package(s)
  purge, pu, p           - Remove package(s) and their configuration files
  search, s, find, f     - Search available packages
  search-installed, si   - Search installed packages
  update, ud             - Update package list
  upgrade, ug            - Upgrade all packages
  update-upgrade, uu     - Update package list and upgrade all packages
  list, ls, l            - List all available packages
  list-installed, li     - List installed packages
  list-files, lf [pkg]   - List files belonging to a package
  list-commands, lc [pkg]- List commands (binaries) provided by a package
  show, sh, info, inf [pkg]- Show package information
  clean-cache, cc        - Clean the package cache
  autoremove, ar         - Remove unused dependencies

System Utility Commands:
  sysinfo                - Show system information (Distro, Kernel, Arch, Hostname, Uptime)
  disk, df               - Show disk usage for main filesystems
  memory, mem            - Show memory (RAM/Swap) usage
  cpuinfo, cpu           - Show CPU information (Model, Cores, Load)
  ip, net                - Show IP addresses for active network interfaces
  top [options]          - Show top processes
      Options:
          -s <key>       Sort by key (cpu[default], mem, pid, user, start_time, time)
          -n <num>       Show specified number of processes (default 10)
          -f <pattern>   Filter processes by command name/args (case-insensitive)
  ping                   - Check network connectivity by pinging 8.8.8.8

Options:
  -h, --help             - Show this help message
  -v, --version          - Show version information

Examples:
  xpac install firefox
  xpac remove firefox
  xpac search firefox
  xpac update-upgrade
  xpac sysinfo
  xpac disk
  xpac top                  # Top 10 by CPU
  xpac top -s mem -n 5      # Top 5 by Memory
  xpac top -f bash          # Top 10 by CPU, filtered by 'bash'
  xpac top -s pid -f sshd   # Top 10 by PID, filtered by 'sshd'

For more information, see: https://github.com/byomess/xpac
EOF
  exit 0
}


# Description: Determines the system's package manager.
get_package_manager() {
  local manager
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

# Description: Gets the name of the Linux distribution from /etc/os-release.
get_distro_name() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${PRETTY_NAME:-$NAME}"
  else
    echo "unknown"
  fi
}

# --- Internal Package Management ---

# Description: Executes an internal package script (setup or teardown).
run_internal_package_script() {
  local script_path="$1"
  if [ -f "$script_path" ]; then
    if bash "$script_path"; then return 0; else _err "Script execution failed: $script_path"; return 1; fi
  else _err "Script not found: $script_path"; return 1; fi
}
# Description: Installs an internal package via its setup script.
install_internal_package() {
  local script_path="$INTERNAL_PACKAGES_SETUP_DIR/$1.sh"; run_internal_package_script "$script_path"
}
# Description: Uninstalls an internal package via its teardown script.
uninstall_internal_package() {
  local script_path="$INTERNAL_PACKAGES_TEARDOWN_DIR/$1.sh"; run_internal_package_script "$script_path"
}

# --- Distro Package Management -- Central Dispatcher ---

# Description: Executes the native package manager command for a given action.
# Args: $1: xpac_action (e.g., install, remove, update)
#       $@: arguments for the action (e.g., package names)
# Returns: Exit status of the native command.
_run_native_command() {
    local xpac_action="$1"; shift
    local args=("$@")
    local native_cmd_parts=()
    local needs_sudo=1
    local suppress_exit_code=0

    case "$xpac_action" in
        search|list|list-installed|list-files|show|search-installed)
            needs_sudo=0 ;;
    esac

    case "$package_manager" in
        pacman)
            case "$xpac_action" in
                install)        native_cmd_parts=(pacman -S --needed --noconfirm "${args[@]}"); needs_sudo=1 ;;
                remove)         native_cmd_parts=(pacman -R --noconfirm "${args[@]}"); needs_sudo=1 ;;
                purge)          native_cmd_parts=(pacman -Rns --noconfirm "${args[@]}"); needs_sudo=1 ;;
                search)         native_cmd_parts=(pacman -Ss "${args[@]}") ;;
                search-installed) native_cmd_parts=(pacman -Qs "${args[@]}") ;;
                update)         native_cmd_parts=(pacman -Sy); needs_sudo=1 ;;
                upgrade)        native_cmd_parts=(pacman -Syu --noconfirm); needs_sudo=1 ;;
                list)           native_cmd_parts=(pacman -Sl) ;;
                list-installed) native_cmd_parts=(pacman -Qe) ;;
                list-files)     native_cmd_parts=(pacman -Ql "${args[@]}") ;;
                show)           native_cmd_parts=(pacman -Si "${args[@]}") ;;
                clean-cache)    native_cmd_parts=(pacman -Sc --noconfirm); needs_sudo=1 ;;
                *) _err "Xpac action '$xpac_action' not implemented for pacman."; return 1 ;;
            esac
            ;;
        yay)
            needs_sudo=0
            case "$xpac_action" in
                install)        native_cmd_parts=(yay -S --needed --noconfirm "${args[@]}") ;;
                remove)         native_cmd_parts=(yay -R --noconfirm "${args[@]}") ;;
                purge)          native_cmd_parts=(yay -Rns --noconfirm "${args[@]}") ;;
                search)         native_cmd_parts=(yay -Ss "${args[@]}") ;;
                search-installed) native_cmd_parts=(pacman -Qs "${args[@]}") ;;
                update)         native_cmd_parts=(yay -Sy) ;;
                upgrade)        native_cmd_parts=(yay -Syu --noconfirm) ;;
                list)           native_cmd_parts=(yay -Sl) ;;
                list-installed) native_cmd_parts=(yay -Qe) ;;
                list-files)     native_cmd_parts=(yay -Ql "${args[@]}") ;;
                show)           native_cmd_parts=(yay -Si "${args[@]}") ;;
                clean-cache)    native_cmd_parts=(yay -Sc --noconfirm) ;;
                autoremove)     native_cmd_parts=(yay -Yc --noconfirm) ;;
                *) _err "Xpac action '$xpac_action' not implemented for yay."; return 1 ;;
            esac
            ;;
        apt)
            case "$xpac_action" in
                install)        native_cmd_parts=(apt-get install -y "${args[@]}"); needs_sudo=1 ;;
                remove)         native_cmd_parts=(apt-get remove -y "${args[@]}"); needs_sudo=1 ;;
                purge)          native_cmd_parts=(apt-get purge -y "${args[@]}"); needs_sudo=1 ;;
                search)         native_cmd_parts=(apt-cache search --names-only "${args[@]}") ;;
                update)         native_cmd_parts=(apt-get update); needs_sudo=1 ;;
                upgrade)        native_cmd_parts=(apt-get upgrade -y); needs_sudo=1 ;;
                list)           native_cmd_parts=(apt-cache pkgnames) ;;
                list-installed) native_cmd_parts=(apt list --installed) ;;
                list-files)     if _require_command dpkg "dpkg utility"; then native_cmd_parts=(dpkg -L "${args[@]}"); else return 1; fi ;;
                show)           native_cmd_parts=(apt-cache show "${args[@]}") ;;
                clean-cache)    native_cmd_parts=(apt-get clean); needs_sudo=1 ;;
                autoremove)     native_cmd_parts=(apt-get autoremove -y); needs_sudo=1 ;;
                 *) _err "Xpac action '$xpac_action' not implemented for apt."; return 1 ;;
            esac
            ;;
        dnf | yum)
            local mgr_cmd="$package_manager"
            case "$xpac_action" in
                install)        native_cmd_parts=("$mgr_cmd" install -y "${args[@]}"); needs_sudo=1 ;;
                remove)         native_cmd_parts=("$mgr_cmd" remove -y "${args[@]}"); needs_sudo=1 ;;
                purge)          _info "'purge' not distinct for $mgr_cmd; using remove."; native_cmd_parts=("$mgr_cmd" remove -y "${args[@]}"); needs_sudo=1 ;;
                search)         native_cmd_parts=("$mgr_cmd" search "${args[@]}") ;;
                search-installed) native_cmd_parts=("$mgr_cmd" list installed "${args[@]}") ;;
                update)         native_cmd_parts=("$mgr_cmd" check-update); suppress_exit_code=1; needs_sudo=1 ;;
                upgrade)        native_cmd_parts=("$mgr_cmd" upgrade -y); needs_sudo=1 ;;
                list)           native_cmd_parts=("$mgr_cmd" list available) ;;
                list-installed) native_cmd_parts=("$mgr_cmd" list installed) ;;
                list-files)     if _require_command rpm "rpm utility"; then native_cmd_parts=(rpm -ql "${args[@]}"); else return 1; fi ;;
                show)           native_cmd_parts=("$mgr_cmd" info "${args[@]}") ;;
                clean-cache)    native_cmd_parts=("$mgr_cmd" clean all); needs_sudo=1 ;;
                autoremove)     native_cmd_parts=("$mgr_cmd" autoremove -y); needs_sudo=1 ;;
                 *) _err "Xpac action '$xpac_action' not implemented for $mgr_cmd."; return 1 ;;
            esac
            ;;
        zypper)
            case "$xpac_action" in
                install)        native_cmd_parts=(zypper --non-interactive install "${args[@]}"); needs_sudo=1 ;;
                remove)         native_cmd_parts=(zypper --non-interactive remove "${args[@]}"); needs_sudo=1 ;;
                purge)          _info "'purge' not distinct for zypper; using remove."; native_cmd_parts=(zypper --non-interactive remove "${args[@]}"); needs_sudo=1 ;;
                search)         native_cmd_parts=(zypper search "${args[@]}") ;;
                search-installed) native_cmd_parts=(zypper search --installed-only "${args[@]}") ;;
                update)         native_cmd_parts=(zypper refresh); needs_sudo=1 ;;
                upgrade)        native_cmd_parts=(zypper --non-interactive update); needs_sudo=1 ;;
                list)           native_cmd_parts=(zypper search --type package) ;;
                list-installed) native_cmd_parts=(zypper search --installed-only --type package) ;;
                list-files)     if _require_command rpm "rpm utility"; then native_cmd_parts=(rpm -ql "${args[@]}"); else return 1; fi ;;
                show)           native_cmd_parts=(zypper info "${args[@]}") ;;
                clean-cache)    native_cmd_parts=(zypper clean --all); needs_sudo=1 ;;
                autoremove)     native_cmd_parts=(zypper remove --clean-deps --non-interactive); needs_sudo=1 ;;
                 *) _err "Xpac action '$xpac_action' not implemented for zypper."; return 1 ;;
            esac
            ;;
        pkg)
            case "$xpac_action" in
                install)        native_cmd_parts=(pkg install -y "${args[@]}"); needs_sudo=1 ;;
                remove)         native_cmd_parts=(pkg remove -y "${args[@]}"); needs_sudo=1 ;;
                purge)          _info "'purge' not distinct for pkg; using remove."; native_cmd_parts=(pkg remove -y "${args[@]}"); needs_sudo=1 ;;
                search)         native_cmd_parts=(pkg search "${args[@]}") ;;
                update)         native_cmd_parts=(pkg update); needs_sudo=1 ;;
                upgrade)        native_cmd_parts=(pkg upgrade -y); needs_sudo=1 ;;
                list)           native_cmd_parts=(pkg rquery "%n-%v") ;;
                list-installed) native_cmd_parts=(pkg query "%n-%v") ;;
                list-files)     native_cmd_parts=(pkg info -l "${args[@]}") ;;
                show)           native_cmd_parts=(pkg info "${args[@]}") ;;
                clean-cache)    native_cmd_parts=(pkg clean -y); needs_sudo=1 ;;
                autoremove)     native_cmd_parts=(pkg autoremove -y); needs_sudo=1 ;;
                 *) _err "Xpac action '$xpac_action' not implemented for pkg."; return 1 ;;
            esac
            ;;
        *)
            _err "Package manager '$package_manager' not handled in _run_native_command."
            return 1
            ;;
    esac

    if [ ${#native_cmd_parts[@]} -eq 0 ]; then
        _err "Internal Error: Action '$xpac_action' failed to map to a native command for '$package_manager'."
        return 1
    fi

    local final_cmd_str
    if [[ "$needs_sudo" -eq 1 ]]; then
         final_cmd_str=$(_maybe_sudo "${native_cmd_parts[@]}")
    else
         printf -v final_cmd_str "%q " "${native_cmd_parts[@]}"
    fi

    eval "$final_cmd_str"
    local exit_status=$?

    if [[ "$suppress_exit_code" -eq 1 && "$exit_status" -ne 0 ]]; then
         _info "(Ignoring non-zero exit status $exit_status for $xpac_action)"
        return 0
    fi

    return $exit_status
}

# --- Distro Package Management -- Wrapper Functions ---

# Description: Installs distribution packages.
install_distro_package() {
  if [ $# -eq 0 ]; then _err "No packages specified for install."; return 1; fi
  _run_native_command "install" "$@"
}

# Description: Uninstalls distribution packages.
uninstall_distro_package() {
  if [ $# -eq 0 ]; then _err "No packages specified for remove."; return 1; fi
  _run_native_command "remove" "$@"
}

# Description: Purges distribution packages (removes config files).
purge_distro_package() {
   if [ $# -eq 0 ]; then _err "No packages specified for purge."; return 1; fi
   _run_native_command "purge" "$@"
}

# Description: Searches for available packages.
search_packages() {
  if [ -z "$*" ]; then _err "No search query specified."; return 1; fi
  _run_native_command "search" "$@"
}

# Description: Searches installed packages (specific implementations).
search_installed_packages() {
  local query="$@"
  if [ -z "$query" ]; then _err "No search query specified for installed packages."; return 1; fi

  case "$package_manager" in
    pkg)
          if ! _require_command grep "grep utility"; then return 1; fi
          pkg info -a | grep -i -- "$query" ;;
    apt)
          if ! _require_command dpkg-query "dpkg-query utility (dpkg)"; then return 1; fi
          if ! _require_command grep "grep utility"; then return 1; fi
          if ! _require_command cut "cut utility (coreutils)"; then return 1; fi
          dpkg-query -W -f='${Status} ${Package}\n' | grep "install ok installed" | cut -d' ' -f4- | grep -i -- "$query" ;;
    *)
          _run_native_command "search-installed" "$@" ;;
  esac
  return $?
}

# Description: Updates the local package list/cache.
update_package_list() {
  _info "Updating package list using $package_manager..."
  _run_native_command "update"
}

# Description: Upgrades all installed packages.
upgrade_packages() {
   _info "Upgrading all packages using $package_manager..."
   _run_native_command "upgrade"
}

# Description: Updates package list and then upgrades all packages.
update_upgrade_packages() {
  update_package_list && upgrade_packages
}

# Description: Lists all available packages.
list_all_packages() {
  _run_native_command "list"
}

# Description: Lists explicitly installed packages.
list_installed_packages() {
   _run_native_command "list-installed"
}

# Description: Shows detailed information about a specific package.
show_package_info() {
  if [ -z "$1" ]; then _err "No package specified for showing info."; return 1; fi
  _run_native_command "show" "$1"
}

# Description: Lists files belonging to an installed package.
list_package_files() {
  if [ -z "$1" ]; then _err "No package specified for listing files."; return 1; fi
  _run_native_command "list-files" "$1"
}

# Description: Lists commands (binaries) provided by a package.
list_package_commands() {
  local package="$1"
  if [ -z "$package" ]; then _err "No package specified for listing commands."; return 1; fi

  local list_files_output
  list_files_output=$(list_package_files "$package" 2>/dev/null)
  local exit_status=$?

  if [ $exit_status -ne 0 ]; then
      _err "Could not list files for package '$package'. Is it installed?"
      return 1
  fi

  echo "$list_files_output" | grep -E '/(s?bin/|games/)[^/]+$' | sed -E 's|.*/||' | sort -u
  return 0
}


# Description: Cleans the package manager's cache.
clean_cache() {
   _info "Cleaning package cache using $package_manager..."
   _run_native_command "clean-cache"
}

# Description: Removes unused dependencies (orphaned packages).
autoremove() {
   _info "Removing unused dependencies using $package_manager..."
  case "$package_manager" in
    pacman)
                  local orphans
                  orphans=$(pacman -Qdtq)
                  if [[ -n "$orphans" ]]; then
                    local cmd_str
                    cmd_str=$(_maybe_sudo pacman -Rs --noconfirm -)
                    echo "$orphans" | eval "$cmd_str"
                    return $?
                  else
                    _info "No orphaned packages to remove."
                    return 0
                  fi ;;
    *) _run_native_command "autoremove" ;;
  esac
}

# --- System Utility Functions ---

# Description: Shows basic system information.
util_sysinfo() {
    local hostname_cmd="<hostname command missing>"
    local kernel_info="<uname command missing>"
    local arch_info="<uname command missing>"
    local uptime_info="<uptime command missing>"
    local cores_info="<lscpu command missing>"

    if _require_command hostname "hostname utility (inetutils/hostname)"; then hostname_cmd="$(hostname)"; fi
    if _require_command uname "uname utility (coreutils)"; then
        kernel_info="$(uname -r)"
        arch_info="$(uname -m)"
    fi
    if _require_command uptime "uptime utility (procps/procps-ng)"; then
         uptime_info="$(uptime -p 2>/dev/null || uptime)"
    fi
    if _require_command lscpu "lscpu utility (util-linux)"; then
        local cores
        cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
        cores_info="${cores:-<not detected>}"
    fi

    echo "--- System Information ---"
    printf "Hostname:\t%s\n" "$hostname_cmd"
    printf "Distribution:\t%s\n" "$distro_name"
    printf "Kernel:\t\t%s\n" "$kernel_info"
    printf "Architecture:\t%s\n" "$arch_info"
    printf "Uptime:\t\t%s\n" "$uptime_info"
    printf "CPU Cores:\t%s\n" "$cores_info"
    echo "------------------------"
    return 0
}

# Description: Shows disk usage for major filesystems.
util_disk() {
    if ! _require_command df "df utility (coreutils)"; then return 1; fi
    echo "--- Disk Usage (excluding tmpfs/devtmpfs/squashfs) ---"
    if df --total -hT --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=squashfs &>/dev/null; then
        df --total -hT --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=squashfs
    else
        df -hT --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=squashfs
    fi
    echo "------------------------------------------------------"
    return 0
}

# Description: Shows memory usage.
util_memory() {
     if ! _require_command free "free utility (procps/procps-ng)"; then return 1; fi
     echo "--- Memory Usage ---"
     free -h
     echo "--------------------"
     return 0
}

# Description: Shows CPU information.
util_cpuinfo() {
    local cpu_model="<lscpu command missing>"
    local load_avg="<uptime command missing>"
    local lscpu_extra_info=""

    local lscpu_ok=0
    local uptime_ok=0
    _require_command lscpu "lscpu utility (util-linux)" && lscpu_ok=1
    _require_command uptime "uptime utility (procps/procps-ng)" && uptime_ok=1

    if [[ $lscpu_ok -eq 1 ]]; then
        cpu_model=$(lscpu | grep 'Model name:' | sed -E 's/Model name:\s*//')
        lscpu_extra_info=$(lscpu | grep -E '^CPU\(s\):|^Thread\(s\) per core:|^Core\(s\) per socket:|^Socket\(s\):' | sed -E 's/:\s+/: /')
    fi
    if [[ $uptime_ok -eq 1 ]]; then
        load_avg=$(uptime | grep -o 'load average:.*' | awk '{print $3 $4 $5}')
    fi

    echo "--- CPU Information ---"
    printf "Model:\t\t%s\n" "$cpu_model"
    if [[ -n "$lscpu_extra_info" ]]; then
        echo "$lscpu_extra_info"
    fi
    printf "Load Average:\t%s\n" "$load_avg"
    echo "-----------------------"
    return 0
}

# Description: Shows IP addresses for active interfaces.
util_ip() {
    local ip_found=0
    local ifconfig_found=0
    if command -v ip &>/dev/null; then ip_found=1; fi
    if command -v ifconfig &>/dev/null; then ifconfig_found=1; fi

    if [[ $ip_found -eq 0 && $ifconfig_found -eq 0 ]]; then
         _err "Neither 'ip' (iproute2) nor 'ifconfig' (net-tools) command found."
         if ! _require_command ip "ip utility (iproute2)"; then return 1; fi
         ip_found=1
    fi

    echo "--- Network Interfaces (IP Addresses) ---"
    if [[ $ip_found -eq 1 ]]; then
        if ! command -v ip &>/dev/null; then _err "ip command still not found after install attempt."; return 1; fi
        ip -br address show scope global | awk '$1 != "lo" { $1=$1":"; print $1 "\t" $3}'
        if ! ip -br address show scope global | grep -q -v '^lo '; then
             _info "No active global IP addresses found (excluding loopback)."
        fi
    elif [[ $ifconfig_found -eq 1 ]]; then
         if ! _require_command ifconfig "ifconfig utility (net-tools)"; then return 1; fi
         _info "Using 'ifconfig' (less preferred)."
         ifconfig | grep -E '^\w.*Link|inet ' | grep -v '127.0.0.1|::1' | sed -n -e '/^\w/h' -e '/inet / { G; s/ *inet \([0-9.]*\).*/\1/p; }'
    fi
    echo "-------------------------------------------"
    return 0
}


# Description: Shows top processes by CPU or Memory with cleaner output and options.
util_top() {
    if ! _require_command ps "ps utility (procps/procps-ng)"; then return 1; fi

    local num_lines=10
    local filter_pattern=""
    local sort_key_user="cpu"
    local sort_key_ps="-%cpu"
    local header_text="--- Top Processes by CPU Usage ---"

    while [[ $# -gt 0 ]]; do
        [[ "$1" =~ ^- ]] || break
        case "$1" in
            -s|--sort)
                if [ -z "$2" ]; then _err "Missing sort key for -s option."; return 1; fi
                sort_key_user="$2"
                case "$sort_key_user" in
                    cpu) sort_key_ps="-%cpu"; header_text="--- Top Processes by CPU Usage ---" ;;
                    mem) sort_key_ps="-%mem"; header_text="--- Top Processes by Memory Usage ---" ;;
                    pid) sort_key_ps="pid"; header_text="--- Processes Sorted by PID ---" ;;
                    user) sort_key_ps="user"; header_text="--- Processes Sorted by User ---" ;;
                    start|start_time) sort_key_ps="start_time"; header_text="--- Processes Sorted by Start Time ---" ;;
                    time) sort_key_ps="-time"; header_text="--- Processes Sorted by CPU Time ---" ;;
                    *) _err "Invalid sort key '$2'. Use: cpu, mem, pid, user, start_time, time."; return 1 ;;
                esac
                shift 2 ;;
            -n|--number)
                if [ -z "$2" ]; then _err "Missing number for -n option."; return 1; fi
                if ! [[ "$2" =~ ^[0-9]+$ ]] || [ "$2" -eq 0 ]; then _err "Invalid number '$2' for -n option. Must be a positive integer."; return 1; fi
                num_lines="$2"
                shift 2 ;;
            -f|--filter)
                 if [ -z "$2" ]; then _err "Missing filter pattern for -f option."; return 1; fi
                 filter_pattern="$2"
                 shift 2 ;;
            *)
                _err "Unknown option for 'top': $1"
                echo "Usage: xpac top [-s key] [-n num] [-f pattern]"
                return 1 ;;
        esac
    done
    if [[ $# -gt 0 ]]; then
        _err "Unexpected argument(s) for 'top': $*"
        echo "Usage: xpac top [-s key] [-n num] [-f pattern]"
        return 1
    fi

    if [ -n "$filter_pattern" ]; then header_text+=" (Filtered by '$filter_pattern')"; fi
    if [ "$num_lines" -ne 10 ]; then
         header_text="${header_text/Top Processes/Top $num_lines Processes}"
         header_text="${header_text/Processes Sorted/Top $num_lines Processes Sorted}"
    fi
    echo "$header_text"

    local w_user=10 w_pid=7 w_cpu=5 w_mem=5 w_vsz=9 w_rss=8 w_stat=5 w_start=5 w_time=8 w_cmd=60
    printf "%-${w_user}s %${w_pid}s %${w_cpu}s %${w_mem}s %${w_vsz}s %${w_rss}s %-${w_stat}s %${w_start}s %${w_time}s %s\n" \
        "USER" "PID" "%CPU" "%MEM" "VSZ(KiB)" "RSS(KiB)" "STAT" "START" "TIME" "COMMAND"

    local ps_output
    # Correct AWK script definition
    local awk_script='
    BEGIN {
        printed_lines = 0
    }
    {
        command_col = ""
        for (i = 10; i <= NF; i++) {
            command_col = command_col $i " "
        }
        sub(/ $/, "", command_col)

        if (length(command_col) > cmdw) {
            command_col = substr(command_col, 1, cmdw - 3) "..."
        }
        printf "%-*s %*s %*s %*s %*s %*s %-*s %*s %*s %s\n", u, $1, p, $2, c, $3, m, $4, v, $5, r, $6, st, $7, sd, $8, t, $9, command_col
        printed_lines++
    }
    END {
        exit (printed_lines == 0)
    }'

    ps_output=$(ps axo user:$((${w_user}+1)),pid,%cpu,%mem,vsz,rss,stat,start_time,time,args --sort="$sort_key_ps" | tail -n +2)
    if [ -n "$filter_pattern" ]; then ps_output=$(echo "$ps_output" | grep -i -- "$filter_pattern"); fi
    formatted_output=$(echo "$ps_output" | head -n "$num_lines" | awk -v u=$w_user -v p=$w_pid -v c=$w_cpu -v m=$w_mem -v v=$w_vsz -v r=$w_rss -v st=$w_stat -v sd=$w_start -v t=$w_time -v cmdw=$w_cmd "$awk_script")
    local awk_exit_status=$?
    echo "$formatted_output"

    if [ $awk_exit_status -ne 0 ] && [ -n "$filter_pattern" ] ; then _info "No processes found matching filter '$filter_pattern'."; elif [ $awk_exit_status -ne 0 ]; then _info "No processes found or error during formatting."; fi
    local total_width=$(( w_user + 1 + w_pid + 1 + w_cpu + 1 + w_mem + 1 + w_vsz + 1 + w_rss + 1 + w_stat + 1 + w_start + 1 + w_time + 1 + w_cmd ))
    printf '%.0s-' $(seq 1 $total_width); printf '\n'

    return 0
}


# Description: Pings a host to check network connectivity.
util_ping() {
    if ! _require_command ping "ping utility (iputils/inetutils)"; then return 1; fi
    local target_host="8.8.8.8"; local ping_count=4
    echo "--- Network Connectivity Test (ping $target_host) ---"
    ping -c "$ping_count" "$target_host"
    local exit_status=$?
    echo "---------------------------------------------------"
    if [ $exit_status -eq 0 ]; then _info "Ping successful."; else case $exit_status in 1) _err "Ping failed: No reply";; 2) _err "Ping failed: Other error (e.g., unknown host)";; *) _err "Ping failed (Exit code: $exit_status)";; esac; fi
    return $exit_status
}


# --- Main Logic ---

# Description: Checks if a package name corresponds to an internal package.
is_internal_package() {
  local package_name="$1"
  [ -f "$INTERNAL_PACKAGES_SETUP_DIR/$package_name.sh" ] || \
  [ -f "$INTERNAL_PACKAGES_TEARDOWN_DIR/$package_name.sh" ]
}

# Description: Installs packages, dispatching to internal or distro handler.
install_package() {
  local pkg; local overall_status=0
  if [ $# -eq 0 ]; then _err "No packages specified for install."; return 1; fi # FIX: Added return 1
  local distro_pkgs=()
  for pkg in "$@"; do
    if is_internal_package "$pkg"; then install_internal_package "$pkg" || overall_status=$?; else distro_pkgs+=("$pkg"); fi
  done
  if [ ${#distro_pkgs[@]} -gt 0 ]; then install_distro_package "${distro_pkgs[@]}" || overall_status=$?; fi
  return $overall_status
}

# Description: Uninstalls packages, dispatching to internal or distro handler.
uninstall_package() {
  local pkg; local overall_status=0
   if [ $# -eq 0 ]; then _err "No packages specified for remove."; return 1; fi # FIX: Added return 1
  local distro_pkgs=()
  for pkg in "$@"; do
    if is_internal_package "$pkg"; then
      if [ -f "$INTERNAL_PACKAGES_TEARDOWN_DIR/$pkg.sh" ]; then uninstall_internal_package "$pkg" || overall_status=$?; else _info "No internal teardown script for '$pkg'."; fi
    else distro_pkgs+=("$pkg"); fi
  done
  if [ ${#distro_pkgs[@]} -gt 0 ]; then uninstall_distro_package "${distro_pkgs[@]}" || overall_status=$?; fi
  return $overall_status
}

# Description: Purges packages; equivalent to uninstall for internal packages.
purge_package() {
  local pkg; local overall_status=0
  if [ $# -eq 0 ]; then _err "No packages specified for purge."; return 1; fi # FIX: Added return 1
  local distro_pkgs=()
  for pkg in "$@"; do
    if is_internal_package "$pkg"; then
      _info "Purge executes teardown script for internal package '$pkg'."
      if [ -f "$INTERNAL_PACKAGES_TEARDOWN_DIR/$pkg.sh" ]; then uninstall_internal_package "$pkg" || overall_status=$?; else _info "No internal teardown script for '$pkg'."; fi
    else distro_pkgs+=("$pkg"); fi
  done
  if [ ${#distro_pkgs[@]} -gt 0 ]; then purge_distro_package "${distro_pkgs[@]}" || overall_status=$?; fi
  return $overall_status
}

# Description: Fallback for unrecognized commands (attempts yay search/install).
selective_install_package() {
  local potential_package="$1"
  if [ -z "$potential_package" ]; then display_usage; return 1; fi
  case "$package_manager" in
    yay)
      _info "Unrecognized command '$potential_package'. Attempting interactive search/install with yay."
      yay "$@"
      # FIX: Return 127 (command not found) even if yay succeeds
      _err "Command '$potential_package' is not a valid xpac command."
      return 127
      ;;
    *)
      _err "Unknown action or package '$potential_package'."
      display_usage
      return 1 ;;
  esac
}

# Description: Handles the main action based on user input command.
handle_main_action() {
  local action="${1:-update-upgrade}"; shift || true; local args=("$@")
  if [[ "$action" == "--help" || "$action" == "-h" ]]; then display_usage; return 0; fi
  if [[ "$action" == "--version" || "$action" == "-v" ]]; then echo "xpac version $XPAC_VERSION"; return 0; fi

  case "$action" in
    install | i | add)        install_package "${args[@]}" ;;
    remove | rm | del)        uninstall_package "${args[@]}" ;;
    purge | pu | p)           purge_package "${args[@]}" ;;
    search | s | find | f)    search_packages "${args[@]}" ;;
    search-installed | si)    search_installed_packages "${args[@]}" ;;
    update | ud)              update_package_list ;;
    upgrade | ug)             upgrade_packages ;;
    update-upgrade | uu)      update_upgrade_packages ;;
    list | ls | l)            list_all_packages ;;
    list-installed | li)      list_installed_packages ;;
    list-files | lf)          list_package_files "${args[0]}" ;;
    list-commands | lc)       list_package_commands "${args[0]}" ;;
    show | sh | info | inf)   show_package_info "${args[0]}" ;;
    clean-cache | cc)         clean_cache ;;
    autoremove | ar)          autoremove ;;
    sysinfo)                  util_sysinfo ;;
    disk | df)                util_disk ;;
    memory | mem)             util_memory ;;
    cpuinfo | cpu)            util_cpuinfo ;;
    ip | net)                 util_ip ;;
    top)                      util_top "${args[@]}" ;;
    ping)                     util_ping ;;
    help | h)                 display_usage ;;
    version | v)              echo "xpac version $XPAC_VERSION" ;;
    *)                        selective_install_package "$action" "${args[@]}" ;;
  esac
  return $?
}

# --- Script Execution ---

package_manager=$(get_package_manager)
if [ "$package_manager" = "unknown" ]; then
  _err "Could not detect a supported package manager (apt, pacman, yay, dnf, yum, zypper, pkg)."
  exit 1
fi
distro_name=$(get_distro_name)
handle_main_action "$@"
exit $?