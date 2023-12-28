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

# Step 3: Fetch the latest versions of software packages
# Fetch MariaDB version
mariadb_latest_version=$(curl -sSL https://downloads.mariadb.org/mariadb/repositories/ | grep "MariaDB Server" | awk -F'[<|>]' '{print $3}')

# Fetch PHP version
php_latest_version=$(curl -sSL https://www.php.net/downloads.php | grep "PHP 8" | grep -oP 'PHP 8\.\d+\.\d+' | head -n 1)

# Fetch phpMyAdmin version
phpmyadmin_latest_version=$(curl -sSL https://www.phpmyadmin.net/downloads/ | grep "phpMyAdmin" | grep -oP 'phpMyAdmin \d+\.\d+\.\d+' | head -n 1)

# Fetch Nginx version
nginx_latest_version=$(curl -sSL https://nginx.org/en/download.html | grep "Mainline version" | awk -F'[>|<]' '{print $3}' | head -n 1)

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

# Download the MariaDB script to configure access to MariaDB repositories
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
chmod +x mariadb_repo_setup

# Use the script to add MariaDB repositories and install MariaDB from the user-selected version
./mariadb_repo_setup --mariadb-server-version="mariadb-$mariadb_version"

# Install MariaDB server
yum -y install mariadb-server mariadb-backup

# Set the root password for MariaDB
mysqladmin -u root password "$mariadb_password"

# Install PHP with the selected version and required extensions
yum -y install php-$php_selection php-fpm-$php_selection php-mysqlnd-$php_selection php-opcache-$php_selection php-gd-$php_selection php-json-$php_selection php-mbstring-$php_selection php-mcrypt-$php_selection php-xml-$php_selection

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

