# xpac - Cross-Distro Package Manager

`xpac` is a simple yet powerful wrapper tool designed to unify and streamline package management and common system utility tasks across different Linux distributions and environments like FreeBSD or Termux. With `xpac`, you can manage your system packages and check system status using the same intuitive commands, no matter which compatible OS you're on.

Whether you’re a seasoned user juggling multiple systems, migrating to a new distro, or simply prefer a familiar interface, `xpac` makes it easier to install, update, remove software, and query system status with consistent commands.

## Features

- **Unified Command Interface**: Use the same commands to manage packages and run common utilities, regardless of the underlying package manager (e.g., `apt`, `yum`, `dnf`, `pacman`, `zypper`, `pkg`).
- **Cross-System Compatibility**: Supports multiple popular Linux distributions and other systems like FreeBSD/Termux, making it a great choice for users who switch environments frequently.
- **System Utility Commands**: Access common system information (disk, memory, CPU, network) and perform simple tasks (`ping`, `top`) with unified commands.
- **Dependency Handling**: For utility commands, `xpac` can check for required tools and prompt to install them if missing (where supported).
- **Familiarity**: For users familiar with a specific distro’s package manager, `xpac` provides a consistent interface, reducing the learning curve when migrating.
- **Simplicity**: Focus on the task at hand — managing packages or checking system status — without worrying about remembering specific flags for different native tools.

## Supported Systems & Package Managers

`xpac` currently supports the following package managers:

- **APT**: Debian, Ubuntu, Linux Mint, Pop!_OS, etc.
- **DNF**: Fedora, RHEL (8+), CentOS Stream (8+), etc.
- **Pacman**: Arch Linux, Manjaro, EndeavourOS, etc.
- **YUM**: RHEL (7), CentOS (7), older Fedora versions.
- **Zypper**: openSUSE, SUSE Linux Enterprise.
- **Pkg**: FreeBSD, GhostBSD, Termux (Android), etc.
- **Yay**: Arch Linux AUR Helper (priority over Pacman if installed).

## Installation

### Using the Install Script

You can install `xpac` by cloning the repository and using the provided installation script.

1.  Clone the repository (make sure you have `git` installed):
    ```bash
    git clone https://github.com/byomess/xpac.git
    ```
2.  Navigate into the directory and run the installation script:
    ```bash
    cd xpac
    sudo ./install.sh
    # Use sudo if installing system-wide (e.g., to /usr/local/bin)
    # Omit sudo if installing to a user directory handled by the script
    ```

## Usage

Once installed, use `xpac` followed by a command and arguments.

### Package Management

- **Install a package**:
  ```bash
  xpac install <package-name> [package-name...]
  # Aliases: i, add
  ```

- **Remove a package**:
  ```bash
  xpac remove <package-name> [package-name...]
  # Aliases: rm, del
  ```

- **Purge a package** (remove config files too; falls back to 'remove' if unsupported):
  ```bash
  xpac purge <package-name> [package-name...]
  # Aliases: pu, p
  ```

- **Search for available packages**:
  ```bash
  xpac search <query>
  # Aliases: s, find, f
  ```

- **Search within installed packages**:
  ```bash
  xpac search-installed <query>
  # Aliases: si
  ```

- **Update package list**:
  ```bash
  xpac update
  # Aliases: ud
  ```

- **Upgrade all packages**:
  ```bash
  xpac upgrade
  # Aliases: ug
  ```

- **Update package list AND upgrade all packages**:
  ```bash
  xpac update-upgrade
  # Aliases: uu
  ```

- **List all available packages** (can be very long!):
  ```bash
  xpac list
  # Aliases: ls, l
  ```

- **List installed packages**:
  ```bash
  xpac list-installed
  # Aliases: li
  ```

- **List files owned by an installed package**:
  ```bash
  xpac list-files <package-name>
  # Aliases: lf
  ```

- **List commands (binaries) provided by an installed package**:
  ```bash
  xpac list-commands <package-name>
  # Aliases: lc
  ```

- **Show package details/information**:
  ```bash
  xpac show <package-name>
  # Aliases: sh, info, inf
  ```

- **Clean package manager cache**:
  ```bash
  xpac clean-cache
  # Aliases: cc
  ```

- **Remove unused dependencies (autoremove)**:
  ```bash
  xpac autoremove
  # Aliases: ar
  ```

### System Utility Commands

- **Show system information**: Displays distribution, kernel, architecture, hostname, uptime, etc.
  ```bash
  xpac sysinfo
  ```

- **Show disk usage**: Lists mounted filesystems and their usage (like `df -h`).
  ```bash
  xpac disk
  # Alias: df
  ```

- **Show memory usage**: Displays RAM and swap usage (like `free -h`).
  ```bash
  xpac memory
  # Alias: mem
  ```

- **Show CPU information**: Displays CPU model, core count, and load average.
  ```bash
  xpac cpuinfo
  # Alias: cpu
  ```

- **Show IP addresses**: Lists IP addresses for active network interfaces.
  ```bash
  xpac ip
  # Alias: net
  ```

- **Show top processes**: Lists processes consuming the most resources.
  ```bash
  xpac top [options]
  # Options:
  #   -s <key>  Sort by key (cpu[default], mem, pid, user, start_time, time)
  #   -n <num>  Show <num> processes (default 10)
  #   -f <pat>  Filter command by case-insensitive <pattern>
  # Example: xpac top -s mem -n 5 -f firefox
  ```

- **Check network connectivity**: Pings a reliable external host (8.8.8.8).
  ```bash
  xpac ping
  ```

---

Use `xpac --help` to see the full list of commands and options available in your installed version.

## Why xpac?

- **Consistency**: No need to memorize different commands for each package manager or utility.
- **Flexibility**: Works across a variety of Linux distributions and other compatible systems.
- **Efficiency**: Simplifies common tasks with easy-to-remember commands.
- **Ease of Migration**: Helps maintain a consistent workflow when switching between systems.

## Contributing

We welcome contributions to `xpac`! If you have a bug fix, feature request, want to add support for another package manager, or improve the project, feel free to fork the repo, make changes, and submit a pull request.

### Issues and Feedback

If you encounter any issues, or if you have suggestions or feedback, please open an issue in the [GitHub Issues](https://github.com/byomess/xpac/issues) section.

## License

`xpac` is open source and available under the [MIT License](LICENSE).