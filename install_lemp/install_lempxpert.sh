#!/bin/bash

# Function to log messages to a file
log_message() {
    local message="$1"
    local log_file="/var/log/lempxpert.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    log_message "Script run as non-root user"
    exit 1
fi

# Step 1: Check if the OS version is supported
os_version=$(cat /etc/os-release | grep "^VERSION_ID" | cut -d'"' -f2)
if [ "$(cat /etc/os-release | grep "^ID" | cut -d'"' -f2)" != "centos" ] || \
   [ "$os_version" != "7" ] && [ "$os_version" != "8" ] && [ "$os_version" != "9" ] || \
   [ "$(uname -m)" != "x86_64" ]; then
    echo "Error: LEMPXpert does not support this OS version or architecture."
    echo "Your OS version: CentOS $os_version ($(uname -m))"
    log_message "Unsupported OS version or architecture"
    exit 1
fi

# Step 2: Ask for user input and save in variables
read -p "Enter the port for phpMyAdmin access: " phpmyadmin_port
read -p "Enter your email address: " email_address
read -p "Enter a password to protect phpMyAdmin access directory: " -s phpmyadmin_password
username=$(echo "$email_address" | cut -d'@' -f1)
read -p "Enter password for MariaDB: " -s mariadb_password
echo # Move to the next line

# Validate email address format
if [[ ! "$email_address" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "Error: Invalid email address format."
    log_message "Invalid email address format: $email_address"
    exit 1
fi

# Step 3: Specify the versions of software packages
# You can manually specify the versions here
mariadb_versions=("10.11" "10.6" "10.5")
php_versions=("8.3" "8.2" "8.1" "8.0" "7.4")
phpmyadmin_versions=("5.2.1")
nginx_versions=("1.25" "1.24")

# Display the available versions
echo "Available versions:"
echo "MariaDB: ${mariadb_versions[@]}"
echo "PHP: ${php_versions[@]}"
echo "phpMyAdmin: ${phpmyadmin_versions[@]}"
echo "Nginx: ${nginx_versions[@]}"

# Prompt the user to select versions
read -p "Select the MariaDB version: " mariadb_version
read -p "Select the PHP version: " php_version
read -p "Select the phpMyAdmin version: " phpmyadmin_version
read -p "Select the Nginx version: " nginx_version

# Check if the selected versions are valid
if ! [[ " ${mariadb_versions[@]} " =~ " ${mariadb_version} " ]]; then
    echo "Invalid MariaDB version. Please select from: ${mariadb_versions[@]}"
    log_message "Invalid MariaDB version: $mariadb_version"
    exit 1
fi

if ! [[ " ${php_versions[@]} " =~ " ${php_version} " ]]; then
    echo "Invalid PHP version. Please select from: ${php_versions[@]}"
    log_message "Invalid PHP version: $php_version"
    exit 1
fi

if ! [[ " ${phpmyadmin_versions[@]} " =~ " ${phpmyadmin_version} " ]]; then
    echo "Invalid phpMyAdmin version. Please select from: ${phpmyadmin_versions[@]}"
    log_message "Invalid phpMyAdmin version: $phpmyadmin_version"
    exit 1
fi

if ! [[ " ${nginx_versions[@]} " =~ " ${nginx_version} " ]]; then
    echo "Invalid Nginx version. Please select from: ${nginx_versions[@]}"
    log_message "Invalid Nginx version: $nginx_version"
    exit 1
fi

############################################
# Install LEMP stack and required packages
############################################
# Step 4: Install LEMP stack and required packages
echo "Installing LEMP stack and required packages..."
log_message "Installing LEMP stack and required packages"

# First do server update
yum -y update

# Install EPEL repository and yum-utils
groupadd nginx
useradd -g nginx -d /dev/null -s /sbin/nologin nginx
sudo yum -y groupinstall "Development Tools"
sudo yum -y install yum-utils gcc gcc-c++ pcre pcre-devel sshpass zlib zlib-devel tar exim mailx autoconf bind-utils GeoIP GeoIP-devel ca-certificates perl socat perl-devel perl-ExtUtils-Embed make automake perl-libwww-perl tree virt-what openssl-devel openssl which libxml2-devel libxml2 libxslt libxslt-devel gd gd-devel iptables* openldap openldap-devel curl curl-devel diffutils pkgconfig sudo lsof pkgconfig libatomic_ops-devel gperftools gperftools-devel 
sudo yum -y install unzip zip rsync psmisc syslog-ng-libdbi syslog-ng cronie cronie-anacron nano

############################################
# Install MariaDB
############################################

# Check if MariaDB is already installed
if ! command -v mysql &> /dev/null; then
    # MariaDB is not installed, proceed with installation
    echo "Installing MariaDB server..."
    log_message "Installing MariaDB server"

    # Download the MariaDB script to configure access to MariaDB repositories
    wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    chmod +x mariadb_repo_setup

    # Use the script to add MariaDB repositories and install MariaDB from the user-selected version
    ./mariadb_repo_setup --mariadb-server-version="mariadb-$mariadb_version"

    # Install MariaDB server
    yum -y install mariadb-server mariadb-backup

    # Set the root password for MariaDB
    mysqladmin -u root password "$mariadb_password"
else
    # MariaDB is already installed
    echo "MariaDB is already installed. Skipping installation."
    log_message "MariaDB is already installed"
fi

# Set the root password for MariaDB
mysqladmin -u root -p -S /var/lib/mysql/mysql.sock "$mariadb_password"

############################################
# Install PHP
############################################
# Determine CentOS version and extract the major version number
centos_version=$(awk '{print $4}' /etc/centos-release | cut -d '.' -f1)

# Ensure centos_version is an integer
if ! [[ "$centos_version" =~ ^[0-9]+$ ]]; then
    echo "Failed to determine CentOS version."
    log_message "Failed to determine CentOS version"
    exit 1
fi

# Enable the corresponding Remi repository based on CentOS version
if [[ "$centos_version" == "7" ]]; then
    # Enable Remi repository for CentOS 7
    sudo yum install -y epel-release
    sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
elif [[ "$centos_version" == "8" ]]; then
    # Enable Remi repository for CentOS 8
    sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
elif [[ "$centos_version" == "9" ]]; then
    # Enable Remi repository for CentOS 9
    sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
else
    echo "Unsupported CentOS version: $centos_version"
    log_message "Unsupported CentOS version: $centos_version"
    exit 1
fi

# Install PHP with the selected version and required extensions
echo "Installing PHP..."
log_message "Installing PHP"

# Function to convert user input to PHP package name format
convert_to_php_package_name() {
    local input_version="$1"
    
    # Remove dots and convert to PHP package format (e.g., 8.3 -> php83, 8.2 -> php82)
    php_version_new="${input_version//./}"
    php_version_ex="$php_version_new"
    echo "php$php_version_ex"
}

# Determine the PHP version to install
desired_version=$(convert_to_php_package_name "$php_version")
echo "$desired_version"

# Install PHP version
if [[ "$centos_version" == "7" || "$centos_version" == "8" || "$centos_version" == "9" ]]; then
    sudo dnf install -y "$desired_version" || sudo yum install -y "$desired_version"
fi

echo "PHP $desired_version has been installed successfully."
log_message "PHP $desired_version has been installed successfully"

# Create a symbolic link to PHP binary in a directory in PATH
php_bin_dir="/usr/bin"
sudo ln -sf "$php_bin_dir/$desired_version" "$php_bin_dir/php"

echo "PHP has been added to your PATH. You may need to open a new terminal for the changes to take effect."
log_message "PHP has been added to PATH"

################################################
# Install Nginx with the selected version
################################################
# Install Nginx with the selected version
# Function to install Nginx with the specified version
install_nginx() {
    
    # Add the Nginx repository
    sudo tee /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

    # Enable mainline or stable repo based on user input
    if [ "$nginx_version_branch" == "mainline" ]; then
        sudo yum-config-manager --enable nginx-mainline
    fi
    
    # Install Nginx
    sudo yum -y install nginx-$nginx_version
    
    # Enable and start Nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx

     # Add Nginx binary directory to PATH
    if ! grep -q "/usr/sbin/nginx" /etc/environment; then
        echo 'PATH="$PATH:/usr/sbin"' | sudo tee -a /etc/environment
    fi
}

# Function to configure the root website
configure_root_website() {
    local root_dir="$1"
    local server_ip="$2"
    
    # Create the root directory
    sudo mkdir -p "$root_dir"
    
    # Create a sample index.html
    echo "<html><body><h1>Welcome to LEMPXpert.com</h1></body></html>" | sudo tee "$root_dir/index.html" > /dev/null
    
    # Set proper permissions
    sudo chown -R nginx:nginx "$root_dir"
    
    # Configure the Nginx server block for the root website
    sudo tee /etc/nginx/conf.d/lempxpert.conf <<EOF
server {
    listen 80;
    server_name $server_ip;

    root $root_dir;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    # Reload Nginx to apply the configuration
    sudo systemctl reload nginx
}

# Main script
read -p "Enter 'stable' or 'mainline' to choose the Nginx version: " nginx_version_branch
root_dir="/home/lempxpert.server/public"  
mkdir -p "$root_dir"
# Validate the root directory path
if [ -z "$root_dir" ] || [ ! -d "$root_dir" ]; then
    echo "Invalid root directory path. Please provide a valid directory path."
    exit 1
fi

# Get the server's IPv4 address
server_ip=$(curl -4 ifconfig.co)

# Install Nginx with the specified version
install_nginx "$nginx_version_branch"

# Configure the root website
configure_root_website "$root_dir" "$server_ip"

echo "LEMPXpert.com has been configured with Nginx $nginx_version."
# Nginx Installation Finsihed

# Start and enable services
systemctl start mariadb
systemctl enable mariadb

systemctl start php-fpm
systemctl enable php-fpm

systemctl start nginx
systemctl enable nginx

############################################
            #Install phpMyAdmin
############################################

# Step 5: Set up phpMyAdmin
echo "Setting up phpMyAdmin..."
log_message "Setting up phpMyAdmin"

phpmyadmin_dir="/home/lempxpert.server/private/phpmyadmin"
temp_dir_php=$(mktemp -d)

#Install phpMyAdmin
wget -P "$temp_dir_php" https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_version}/phpMyAdmin-${phpmyadmin_version}-all-languages.tar.gz

#Configure phpMyAdmin
config_file="/etc/phpMyAdmin/config.inc.php"

if [ -f "$config_file" ]; then
    # Backup existing configuration
    sudo mv "$config_file" "${config_file}.bak"
fi

# Generate a random blowfish_secret for enhanced security
blowfish_secret=$(openssl rand -base64 32)

# Create a new phpMyAdmin configuration file
sudo tee "$config_file" > /dev/null <<EOL
<?php
\$cfg['blowfish_secret'] = '$blowfish_secret';
\$cfg['Servers'][1]['host'] = 'localhost';
\$cfg['Servers'][1]['port'] = '3306';
\$cfg['Servers'][1]['socket'] = '';
\$cfg['Servers'][1]['connect_type'] = 'tcp';
\$cfg['Servers'][1]['extension'] = 'mysqli';
\$cfg['Servers'][1]['auth_type'] = 'cookie';
\$cfg['Servers'][1]['user'] = 'root';
\$cfg['Servers'][1]['password'] = '$mariadb_password';
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
?>
EOL

# Define the phpMyAdmin server block file path
nginx_phpmyadmin_conf="/etc/nginx/conf.d/phpmyadmin.conf"

# Set proper permissions
sudo chown root:nginx "$config_file"
sudo chmod 640 "$config_file"

# Step 3: Create a symbolic link for phpMyAdmin in Nginx's web root
sudo ln -s /home/LEMPXpert.com/private/phpmyadmin /usr/share/nginx/html/phpmyadmin

# Restart Nginx to apply the new configuration
systemctl restart nginx

# Step 6: Install Linux Dash web dashboard
echo "Installing Linux Dash web dashboard..."
echo "You can access phpMyAdmin at: http://$server_ip/phpmyadmin"
log_message "Installing Linux Dash web dashboard"

############################################
# Install Linux Dash web dashboard
############################################

# Define the Linux Dash installation directory
linux_dash_dir="/var/www/html/lempxpert/linux-dash"

# Create the Linux Dash directory
mkdir -p "$linux_dash_dir"

# Clone the Linux Dash repository from GitHub
git clone --depth 1 https://github.com/afaqurk/linux-dash.git "$linux_dash_dir"

# Modify the Linux Dash configuration
linux_dash_config="$linux_dash_dir/app/server/config.json"
cat <<EOL > "$linux_dash_config"
{
  "accounts": [
    {
      "user": "$username",
      "pass": "$linux_dash_password"
    }
  ]
}
EOL

# Configure Nginx to serve Linux Dash and point the main server to /home/lempxpert.server/public
linux_dash_nginx_conf="/etc/nginx/conf.d/linux-dash.conf"

cat <<EOL > "$linux_dash_nginx_conf"
server {
    listen 8080;  # Change this to your desired port
    server_name lempxpert.example.com;  # Change this to your desired domain or IP

    root $linux_dash_dir/app/server;

    access_log /var/log/nginx/lempxpert-linux-dash.access.log;
    error_log /var/log/nginx/lempxpert-linux-dash.error.log;

    location / {
        index index.html index.php;
        try_files \$uri \$uri/ /index.html;
    }

    location /server-status {
        proxy_pass http://127.0.0.1:8080;  # You can change the port if needed
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # ... Other Nginx settings ...

}

server {
    listen 80;  # Default HTTP port
    server_name $server_ip;  # Use the server's IP address

    root /home/lempxpert.server/public;  # Point to /home/lempxpert.server/public

    access_log /var/log/nginx/lempxpert.access.log;
    error_log /var/log/nginx/lempxpert.error.log;

    # ... Other Nginx settings for the main server ...

}
EOL

# Restart Nginx to apply the new configuration
systemctl restart nginx  # Assuming you're using Nginx

# ... Continue with the finalization step ...

# Step 7: Finalize the setup
echo "LEMPXpert installation completed."
log_message "LEMPXpert installation completed"
