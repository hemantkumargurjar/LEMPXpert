import os
import sys
import pyfiglet

# ASCII art logo using pyfiglet
logo_text = pyfiglet.figlet_format("LEMPXpert", font="banner")
welcome_message = "Welcome to LEMPXpert - Your LEMP Server Manager"

def display_menu():
    print(logo_text)
    print(welcome_message)
    print("Select an option:")
    print("1. Install LEMPXpert")
    print("2. Test Server")
    print("3. Exit")

def install_lempxpert():
    # Implement installation logic here
    print("Installing LEMPXpert...")
    # Add your installation steps here

def test_server():
    # Implement server testing logic here
    print("Testing Server...")
    # Add your server testing steps here

def main():
    while True:
        display_menu()
        choice = input("Enter your choice (1/2/3): ")

        if choice == '1':
            install_lempxpert()
        elif choice == '2':
            test_server()
        elif choice == '3':
            print("Exiting LEMPXpert. Goodbye!")
            sys.exit(0)
        else:
            print("Invalid choice. Please select a valid option (1/2/3).")

if __name__ == "__main__":
    main()
