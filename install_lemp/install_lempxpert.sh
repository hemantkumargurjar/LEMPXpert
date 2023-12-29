#!/bin/bash

# Step 1: Check if the OS version is supported
os_version=$(cat /etc/os-release | grep "^VERSION_ID" | cut -d'"' -f2)
if [ "$(cat /etc/os-release | grep "^ID" | cut -d'"' -f2)" != "centos" ] || \
   [ "$os_version" != "7" ] && [ "$os_version" != "8" ] && [ "$os_version" != "9" ] || \
   [ "$(uname -m)" != "x86_64" ]; then
    echo "Error: LEMPXpert does not support this OS version or architecture."
    echo "Your OS version: CentOS $os_version ($(uname -m))"
    exit 1
fi

# Step 2: Ask for user input and save in variables
read -p "Enter the port for phpMyAdmin access: " phpmyadmin_port
read -p "Enter your email address: " email_address
read -p "Enter a password to protect phpMyAdmin access directory: " phpmyadmin_password
username=$(echo "$email_address" | cut -d'@' -f1)
read -s -p "Enter password for MariaDB: " mariadb_password
echo # Move to the next line

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
    exit 1
fi

if ! [[ " ${php_versions[@]} " =~ " ${php_version} " ]]; then
    echo "Invalid PHP version. Please select from: ${php_versions[@]}"
    exit 1
fi

if ! [[ " ${phpmyadmin_versions[@]} " =~ " ${phpmyadmin_version} " ]]; then
    echo "Invalid phpMyAdmin version. Please select from: ${phpmyadmin_versions[@]}"
    exit 1
fi

if ! [[ " ${nginx_versions[@]} " =~ " ${nginx_version} " ]]; then
    echo "Invalid Nginx version. Please select from: ${nginx_versions[@]}"
    exit 1
fi

# Step 4: Install LEMP stack and required packages
echo "Installing LEMP stack and required packages..."

#First do server update
yum -y update

# Install EPEL repository and yum-utils
groupadd nginx
useradd -g nginx -d /dev/null -s /sbin/nologin nginx
sudo yum -y groupinstall "Development Tools"
sudo yum -y install yum-utils gcc gcc-c++ pcre pcre-devel sshpass zlib zlib-devel tar exim mailx autoconf bind-utils GeoIP GeoIP-devel ca-certificates perl socat perl-devel perl-ExtUtils-Embed make automake perl-libwww-perl tree virt-what openssl-devel openssl which libxml2-devel libxml2 libxslt libxslt-devel gd gd-devel iptables* openldap openldap-devel curl curl-devel diffutils pkgconfig sudo lsof pkgconfig libatomic_ops-devel gperftools gperftools-devel 
sudo yum -y install unzip zip rsync psmisc syslog-ng-libdbi syslog-ng cronie cronie-anacron

# Download the MariaDB script to configure access to MariaDB repositories
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
chmod +x mariadb_repo_setup

# Use the script to add MariaDB repositories and install MariaDB from the user-selected version
./mariadb_repo_setup --mariadb-server-version="mariadb-$mariadb_version"

# Install MariaDB server
yum -y install mariadb-server mariadb-backup

# Set the root password for MariaDB
mysqladmin -u root -p -S /var/lib/mysql/mysql.sock "$mariadb_password"

# Determine CentOS version and extract the major version number
centos_version=$(awk '{print $4}' /etc/centos-release | cut -d '.' -f1)

# Ensure centos_version is an integer
if ! [[ "$centos_version" =~ ^[0-9]+$ ]]; then
    echo "Failed to determine CentOS version."
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
    exit 1
fi

# Install PHP with the selected version and required extensions
echo "Installing PHP..."

# Function to convert user input to PHP package name format
convert_to_php_package_name() {
    local input_version="$1"
    
    # Remove dots and convert to PHP package format (e.g., 8.3 -> php83, 8.2 -> php82)
    php_version="${input_version//./}"
    php_version="php$php_version"
    echo "$php_version"
}

# Determine the PHP version to install
desired_version=$(convert_to_php_package_name "$user_input_version")

# Check if the requested PHP version is available
if [[ "$centos_version" == "7" || "$centos_version" == "8" || "$centos_version" == "9" ]]; then
    sudo dnf install -y "$desired_version" || sudo yum install -y "$desired_version"

# Verify the installation
php$desired_version --version

echo "PHP $desired_version has been installed successfully."

# Add PHP to the user's PATH
user_shell_rc_file="$HOME/.bashrc"  # You can change this to the appropriate shell profile file (e.g., .bash_profile)
php_bin_dir="/usr/bin"
add_php_to_path "$php_bin_dir" "$user_shell_rc_file"

echo "PHP has been added to your PATH. You may need to open a new terminal or run 'source $user_shell_rc_file' for the changes to take effect."

php -v

# Install Nginx with the selected version
yum -y install nginx-$nginx_selection

# Start and enable services
systemctl start mariadb
systemctl enable mariadb

systemctl start php-fpm
systemctl enable php-fpm

systemctl start nginx
systemctl enable nginx

# Step 5: Set up phpMyAdmin
echo "Setting up phpMyAdmin..."

# Define the phpMyAdmin server block file path
nginx_phpmyadmin_conf="/etc/nginx/conf.d/phpmyadmin.conf"

# Create a new Nginx server block for phpMyAdmin
cat <<EOL > "$nginx_phpmyadmin_conf"
server {
    listen 80;
    server_name phpmyadmin.example.com;  # Change this to your desired domain or IP

    root /usr/share/nginx/html/phpmyadmin;

    access_log /var/log/nginx/phpmyadmin.access.log;
    error_log /var/log/nginx/phpmyadmin.error.log;

    location / {
        index index.php;
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;  # Use the provided password file
}
EOL

# Create an .htpasswd file for phpMyAdmin authentication
htpasswd -cb /etc/nginx/.htpasswd "$username" "$phpmyadmin_password"

# Restart Nginx to apply the new configuration
systemctl restart nginx

#!/bin/bash

# ... Previous steps ...

#!/bin/bash

# ... Previous steps ...

# Step 6: Install Linux Dash web dashboard
echo "Installing Linux Dash web dashboard..."

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

