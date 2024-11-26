# xpac - Cross-Distro Package Manager Wrapper

`xpac` is a simple yet powerful wrapper tool designed to unify and streamline package management across different Linux distributions. With `xpac`, you can manage your system packages using the same commands, no matter which distribution you're on.

Whether you’re a seasoned Linux user, migrating to a new distro, or simply prefer a familiar interface for managing packages, `xpac` makes it easier to install, update, and remove software with consistent commands.

## Features

- **Unified Command Interface**: Use the same commands to manage packages, regardless of the underlying package manager (e.g., `apt`, `yum`, `dnf`, `pacman`).
- **Cross-Distro Compatibility**: Supports multiple popular Linux distributions, making it a great choice for users who switch distros frequently.
- **Familiarity**: For users familiar with a specific distro’s package manager, `xpac` provides a consistent interface, reducing the learning curve when migrating.
- **Simplicity**: Focus on what matters — installing, removing, and updating packages without worrying about distro-specific details.
  
## Supported Distributions

# Function to handle installation, uninstallation, and purging of packages

`xpac` currently supports the following Linux package managers and distributions:
- **APT**: Debian, Ubuntu, Linux Mint, etc.
- **DNF**: Fedora, Red Hat, CentOS, etc.
- **Pacman**: Arch Linux, Manjaro, etc.
- **YUM**: Legacy package manager for Red Hat-based systems.
- **Zypper**: OpenSUSE, SUSE Linux Enterprise, etc.
- **Pkg**: FreeBSD package manager, for example TrueOS, GhostBSD, Termux, etc.

## Installation

### Using the Install Script

You can install `xpac` by cloning the repository and using the provided installation script.

1. Clone the repository (make sure you have `git` installed):
    ```bash
    git clone https://github.com/byomess/xpac.git
    ```
2. Use the installation script to install `xpac`:

    ```bash
    cd xpac
    ./install.sh
    ```

## Usage

Once installed, you can use `xpac` as a drop-in replacement for your package manager commands. For example:

- **Install a package**:

  ```bash
  xpac install <package-name>
  # Aliases for install: i, add
  ```

- **Remove a package**:

  ```bash
  xpac remove <package-name>
    # Aliases for remove: rm, delete, del
  ```

- **Update package list and upgrade packages**:
  
  ```
  xpac update-upgrade
  # Aliases for update-upgrade: upd-upg, ud-upg, uu
  ```

- **Purge a package**:

  ```bash
  xpac purge <package-name>
  # Aliases for purge: pu, p
  ```

- **Search for a package**:

  ```bash
  xpac search <package-name>
  # Aliases for search: s, find, f, query, q
  ```

- **List installed packages**:

  ```bash
  xpac list-installed
  # Aliases for list-installed: li, lsi
  ```

- **Show information about a package**:

  ```bash
  xpac info <package-name>
  # Aliases for info: inf, in
  ```

- **Show files installed by a package**:

  ```bash
  xpac list-files <package-name>
  # Aliases for list-files: lf
  ```

- **Clean package cache**:

  ```bash
  xpac clean-cache
  # Aliases for clean-cache: clean, clear, c
  ```

- **Remove unneeded dependencies**:

  ```bash
  xpac autoremove
  # Aliases for autoremove: ar
  ```

And more... Use `xpac help` to see the full list of commands and options.

## Why xpac?

- **Consistency**: No need to learn new commands for each package manager.
- **Flexibility**: Seamlessly works across a variety of distributions.
- **Ease of Migration**: If you’re switching between distributions, `xpac` helps maintain the same package management experience.
  
## Contributing

We welcome contributions to `xpac`! If you have a bug fix, feature request, or want to help improve the project, feel free to fork the repo, make changes, and submit a pull request.

### Issues and Feedback

If you encounter any issues, or if you have suggestions or feedback, please open an issue in the [GitHub Issues](https://github.com/byomess/xpac/issues) section.

## License

`xpac` is open source and available under the [MIT License](LICENSE).