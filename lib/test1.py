import os

def create_file_structure(root_dir="."):
    """
    Creates the BusEase app's file and folder structure with .dart files.

    Args:
        root_dir (str, optional): The root directory where the structure will be created. Defaults to the current directory.
    """
    # Define the directory structure as a dictionary
    dir_structure = {
        "lib": {
            "main.dart": "",  # Empty string for empty file content
            "firebase_options.dart": "",
            "models": {
                "user_model.dart": "",
            },
            "screens": {
                "splash_screen.dart": "",
                "welcome_screen.dart": "",
                "login": {
                    "passenger_login.dart": "",
                    "driver_login.dart": "",
                    "admin_login.dart": "",
                },
                "signup": {
                    "passenger_signup.dart": "",
                },
                "dashboard": {
                    "passenger_dashboard.dart": "",
                    "driver_dashboard.dart": "",
                    "admin_dashboard.dart": "",
                },
                "bus_management": {
                    "add_bus_screen.dart": "",
                    "bus_list_screen.dart": "",
                },
                "booking": {
                    "book_bus_screen.dart": "",
                    "booking_history_screen.dart": "",
                    "booking_list_screen.dart": "",
                },
                "map": {
                    "map_screen.dart": "",
                }
            },
            "services": {
                "auth_service.dart": "",
                "firestore_service.dart": "",
            },
            "widgets": {
                "custom_widgets.dart": "",
            },
        },
    }

    def create_structure(base_dir, structure):
        """
        Recursively creates directories and files based on the given structure.

        Args:
            base_dir (str): The base directory for creating the structure.
            structure (dict): A dictionary representing the directory structure.
        """
        for name, content in structure.items():
            path = os.path.join(base_dir, name)
            if isinstance(content, str):  # Create a file
                try:
                    # Ensure the directory exists.
                    os.makedirs(os.path.dirname(path), exist_ok=True)
                    with open(path, "w") as f:
                        f.write(content)  # Create an empty file
                    print(f"Created file: {path}")
                except Exception as e:
                    print(f"Error creating file {path}: {e}")
            else:  # Create a directory
                try:
                    os.makedirs(path, exist_ok=True)
                    print(f"Created directory: {path}")
                    create_structure(path, content)  # Recursive call for sub-directories
                except Exception as e:
                    print(f"Error creating directory {path}: {e}")

    # Start creating the structure from the root directory
    create_structure(root_dir, dir_structure)


if __name__ == "__main__":
    # Get the directory where the script is located.
    script_directory = os.path.dirname(os.path.abspath(__file__))
    create_file_structure(script_directory)
    print("File and folder structure creation complete.")
