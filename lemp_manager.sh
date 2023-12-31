#!/bin/bash

# Install figlet if not already installed
if ! command -v figlet &> /dev/null; then
    echo "Installing figlet..."
    sudo yum -y install epel-release
    sudo yum -y install figlet
fi

# Clear the terminal
clear

# ASCII art logo using figlet
logo_text=$(figlet "LEMPXpert")

welcome_message="Welcome to LEMPXpert - Your LEMP Server Manager"

display_menu() {
    echo "$logo_text"
    echo "$welcome_message"
    echo "Select an option:"
    echo "1. Install LEMPXpert"
    echo "2. Test Server"
    echo "3. Exit"
}

install_lempxpert() {
    # Create a temporary directory for storing the downloaded script
    temp_dir=$(mktemp -d)
    temp_script="$temp_dir/install_lempxpert.sh"

    # Check if the script file already exists and remove it if it does
    if [ -f "$temp_script" ]; then
        rm -f "$temp_script"
    fi
    
    # Download the install_lempxpert.sh script
    echo "Downloading LEMPXpert installer..."
    curl -sSL -o "$temp_script" https://raw.githubusercontent.com/hemantkumargurjar/LEMPXpert/main/install_lemp/install_lempxpert.sh
    
    # Execute the downloaded script
    chmod +x "$temp_script"
    bash "$temp_script"
    
    # Clean up the temporary directory
    rm -rf "$temp_dir"
}

test_server() {
    # Create a temporary directory for storing the downloaded script
    temp_dir=$(mktemp -d)
    temp_script="$temp_dir/test_server.sh"
    
    # Check if the script file already exists and remove it if it does
    if [ -f "$temp_script" ]; then
        rm -f "$temp_script"
    fi
    
    # Download the test_server.sh script
    echo "Downloading Test Server script..."
    curl -sSL -o "$temp_script" https://raw.githubusercontent.com/hemantkumargurjar/LEMPXpert/main/install_lemp/install_php.sh
    
    # Execute the downloaded script
    chmod +x "$temp_script"
    bash "$temp_script"
    
    # Clean up the temporary directory
    rm -rf "$temp_dir"
}


while true; do
    display_menu
    read -p "Enter your choice (1/2/3): " choice

    case "$choice" in
        1)
            install_lempxpert
            ;;
        2)
            test_server
            ;;
        3)
            echo "Exiting LEMPXpert. Goodbye!"
            # Remove temporary folders
            rm -rf "$temp_dir"  # Remove the temporary directory used for script download
            if [ -f "lemp_manager.sh" ]; then
                rm -f "lemp_manager.sh"
            fi
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option (1/2/3)."
            ;;
    esac
done
