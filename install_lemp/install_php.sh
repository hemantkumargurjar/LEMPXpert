#!/bin/bash

# Check if the script is running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Function to enable the Remi repository for CentOS 7, 8, or 9
enable_remi_repository() {
    local releasever="$1"
    
    if [[ "$releasever" == "7" ]]; then
        sudo yum install -y epel-release
        sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
    elif [[ "$releasever" == "8" ]]; then
        sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    elif [[ "$releasever" == "9" ]]; then
        sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
    else
        echo "Unsupported CentOS version: $releasever"
        exit 1
    fi
}

# Function to convert user input to PHP package name format
convert_to_php_package_name() {
    local input_version="$1"
    
    # Remove dots and convert to PHP package format (e.g., 8.3 -> php83, 8.2 -> php82)
    php_version="${input_version//./}"
    php_version="php$php_version"
    echo "$php_version"
}

# Function to add PHP to the user's PATH
add_php_to_path() {
    local php_bin_dir="$1"
    local user_shell_rc_file="$2"
    
    # Add PHP binary directory to the PATH in the user's shell profile configuration
    echo "export PATH=\$PATH:$php_bin_dir" >> "$user_shell_rc_file"
}

# Main menu
echo "PHP Version Installer Script for CentOS 7, 8, 9"
echo "--------------------------------------------"

# Determine CentOS version and extract the major version number
centos_version=$(awk '{print $4}' /etc/centos-release | cut -d '.' -f1)

# Ensure centos_version is an integer
if ! [[ "$centos_version" =~ ^[0-9]+$ ]]; then
    echo "Failed to determine CentOS version."
    exit 1
fi

# Enable the corresponding Remi repository
enable_remi_repository "$centos_version"

# Prompt the user for the desired PHP version in the format like "8.3" or "8.2"
read -p "Enter the PHP version you want to install (e.g., 8.3, 8.2): " user_input_version

# Convert user input to PHP package name format (e.g., "8.3" -> "php83", "8.2" -> "php82")
desired_version=$(convert_to_php_package_name "$user_input_version")

# Install the requested PHP version
if [[ "$centos_version" == "7" || "$centos_version" == "8" || "$centos_version" == "9" ]]; then
    sudo dnf install -y "$desired_version" || sudo yum install -y "$desired_version"
    
    # Verify the installation
    php -v

    echo "PHP $user_input_version has been installed successfully."

    # Add PHP to the user's PATH
    user_shell_rc_file="$HOME/.bashrc"  # You can change this to the appropriate shell profile file (e.g., .bash_profile)
    php_bin_dir="/usr/bin"
    add_php_to_path "$php_bin_dir" "$user_shell_rc_file"
    
    echo "PHP has been added to your PATH. You may need to open a new terminal or run 'source $user_shell_rc_file' for the changes to take effect."
else
    echo "Unsupported CentOS version: $centos_version"
    exit 1
fi
