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
    # Implement installation logic here
    echo "Installing LEMPXpert..."
    # Add your installation steps here
}

test_server() {
    # Implement server testing logic here
    echo "Testing Server..."
    # Add your server testing steps here
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
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option (1/2/3)."
            ;;
    esac
done
