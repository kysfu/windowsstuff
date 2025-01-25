import os
from mutagen.mp4 import MP4
import re

# Function to clean folder and file names by removing invalid characters
def clean_name(name):
    # Windows invalid characters list
    invalid_chars = r'<>:"/\|?*'
    return re.sub(r'[' + re.escape(invalid_chars) + r']', '_', name)

# Function to extract metadata from .m4b files
def extract_metadata(file_path):
    try:
        audio = MP4(file_path)
        # Extract metadata (keys may vary; adjust if needed)
        author = audio.tags.get("\xa9ART", ["Unknown Author"])[0]
        title = audio.tags.get("\xa9nam", ["Unknown Title"])[0]
        year = audio.tags.get("\xa9day", ["Unknown Year"])[0]  # Year tag
        return author.strip(), title.strip(), year.strip(), file_path
    except Exception as e:
        print(f"Error reading metadata from {file_path}: {e}")
        return None, None, None, None

# Prompt for the base path
base_path = input("Enter the full path to the folder you want to process: ").strip()

# Verify if the path exists
if not os.path.exists(base_path):
    print(f"The path '{base_path}' does not exist. Please check and try again.")
else:
    # Process folders
    for folder_name in os.listdir(base_path):
        folder_path = os.path.join(base_path, folder_name)

        if os.path.isdir(folder_path):  # Ensure it's a folder
            # Store files processed to avoid overwriting the same author-title
            files_processed = set()

            for root, _, files in os.walk(folder_path):
                for file_name in files:
                    if file_name.endswith(".m4b"):  # Look for .m4b files
                        file_path = os.path.join(root, file_name)
                        author, title, year, _ = extract_metadata(file_path)

                        if author and title and year:
                            # Clean the author, title, and year names to remove invalid characters
                            author = clean_name(author)
                            title = clean_name(title)
                            year = clean_name(year)

                            # Create the author's folder if it doesn't exist
                            author_folder_path = os.path.join(base_path, author)
                            if not os.path.exists(author_folder_path):
                                os.makedirs(author_folder_path)

                            # Create the book's folder inside the author's folder with Year
                            book_folder_path = os.path.join(author_folder_path, f"{year} - {title}")

                            # Skip if the folder and file already exist
                            new_file_name = f"{year} - {author} - {title}.m4b"
                            new_file_path = os.path.join(book_folder_path, new_file_name)

                            if os.path.exists(book_folder_path) and os.path.exists(new_file_path):
                                print(f"Skipping already processed file: {new_file_name}")
                                continue  # Skip to the next file

                            # Create the book folder if it doesn't exist
                            if not os.path.exists(book_folder_path):
                                os.makedirs(book_folder_path)

                            # Rename and move the .m4b file with Year
                            try:
                                os.rename(file_path, new_file_path)
                                print(f"Renamed and moved: {file_name} -> {new_file_name}")
                            except Exception as e:
                                print(f"Error renaming file '{file_name}': {e}")

            # Clean up non-.m4b files in the folder
            for root, dirs, files in os.walk(folder_path, topdown=False):
                for file_name in files:
                    if not file_name.endswith(".m4b"):
                        file_path = os.path.join(root, file_name)
                        try:
                            os.remove(file_path)
                            print(f"Deleted non-.m4b file: {file_path}")
                        except Exception as e:
                            print(f"Error deleting file '{file_path}': {e}")

            # Clean up empty folders after processing
            for root, dirs, files in os.walk(folder_path, topdown=False):
                for dir_name in dirs:
                    dir_path = os.path.join(root, dir_name)
                    # Remove empty directories
                    if not os.listdir(dir_path):  # Check if directory is empty
                        try:
                            os.rmdir(dir_path)
                            print(f"Deleted empty folder: {dir_path}")
                        except Exception as e:
                            print(f"Error deleting folder '{dir_path}': {e}")

            # Now delete the root-level folder if it's empty
            if not os.listdir(folder_path):  # Check if the root folder is empty
                try:
                    os.rmdir(folder_path)
                    print(f"Deleted empty root folder: {folder_path}")
                except Exception as e:
                    print(f"Error deleting folder '{folder_path}': {e}")

            print(f"Organized all .m4b files in '{folder_name}' into their respective folders.")
