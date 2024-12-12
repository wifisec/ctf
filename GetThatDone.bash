#!/usr/bin/bash

: '
Script Name: GetThatDone.bash
Description: Clones respositories and downloads files useful to get that done.
Author: Adair John Collins
Version: 1.0
'

# Function to print messages in blue
print_blue() {
    local message="$1"
    echo -e "\033[34m$message\033[0m"
}

# Check if pv is installed
if ! command -v pv &> /dev/null; then
    print_blue "pv command could not be found, please install it first using: sudo apt-get install pv"
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_blue "git command could not be found, please install it first using: sudo apt-get install git"
    exit 1
fi

# Function to handle git clone with error checking
clone_repo() {
    local repo_url="$1"
    local repo_name="$(basename $repo_url .git)"
    print_blue "Cloning $repo_name..."
    git clone "$repo_url"
    if [ $? -eq 0 ]; then
        print_blue "$repo_name cloned successfully!"
    else
        print_blue "Failed to clone $repo_name"
    fi
}

# Function to handle wget with progress indicator
download_file() {
    local file_url="$1"
    local file_name="$2"
    print_blue "Downloading $file_name..."
    wget "$file_url" -O "$file_name"
    if [ $? -eq 0 ]; then
        print_blue "$file_name downloaded successfully!"
    else
        print_blue "Failed to download $file_name"
    fi
}

# List of repositories to clone
repos=(
    "https://github.com/0dayCTF/reverse-shell-generator.git"
    "https://github.com/Caesarovich/rome-webshell.git"
    "https://github.com/eb3095/php-shell.git"
    "https://github.com/GTFOBins/GTFOBins.github.io.git"
    "https://github.com/HackTricks-wiki/hacktricks-cloud.git"
    "https://github.com/HackTricks-wiki/hacktricks.git"
    "https://github.com/LOLAPPS-Project/LOLAPPS.git"
    "https://github.com/LOLBAS-Project/LOLBAS.git"
    "https://github.com/mantvydasb/RedTeaming-Tactics-and-Techniques.git"
    "https://github.com/Orange-Cyberdefense/ocd-mindmaps.git"
    "https://github.com/peass-ng/PEASS-ng.git"
    "https://github.com/SnaffCon/Snaffler.git"
    "https://github.com/swisskyrepo/PayloadsAllTheThings.git"
    "https://github.com/WADComs/WADComs.github.io.git"
    "https://github.com/dostoevskylabs/dostoevsky-pentest-notes.git"
    "https://github.com/Flangvik/SharpCollection.git"
    "https://github.com/S3cur3Th1sSh1t/PowerSharpPack.git"
)

# List of files to download with specific output names
files=(
    "https://gist.githubusercontent.com/joswr1ght/22f40787de19d80d110b37fb79ac3985/raw/c871f130a12e97090a08d0ab855c1b7a93ef1150/easy-simple-php-webshell.php easy-simple-php-webshell.php"
    "https://github.com/neox41/WinEnum/blob/master/WinEnum.bat WinEnum.bat"
    "https://mega.nz/file/cr5HGACC#ANXlTyu8sdlIUizcIX418sa1C2M4Ame_3bjxU9xXGfY WinEnum.bat"
    "https://raw.githubusercontent.com/rebootuser/LinEnum/refs/heads/master/LinEnum.sh LinEnum.sh"
    "https://315180959-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-MRh03Vwd4nuiUi3Oje7%2Fuploads%2Fy1seVZGWtwTeflnv1xzu%2FRed_Team_and_Operational_Security.zip?alt=media&token=2d38a749-6e5e-46b1-8e6e-f622efa9d7c7 Red_Team_and_Operational_Security.zip"
)

# Clone all repositories
for repo in "${repos[@]}"; do
    clone_repo "$repo"
done

# Download all files with specified output names
for entry in "${files[@]}"; do
    file_url=$(echo "$entry" | awk '{print $1}')
    file_name=$(echo "$entry" | awk '{print $2}')
    download_file "$file_url" "$file_name"
done

print_blue "All tasks completed!"

