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
    "https://github.com/t3l3machus/hoaxshell.git"
    "https://github.com/Tuhinshubhra/CMSeeK"
    "https://github.com/0xJs/RedTeaming_CheatSheet.git"
    "https://github.com/AlessandroZ/LaZagne.git"
    "https://github.com/t3l3machus/Villain.git"
    "https://github.com/t3l3machus/hoaxshell.git"
    "https://github.com/jpillora/chisel.git"
    "https://github.com/klsecservices/rpivot.git"
    "https://github.com/sshuttle/sshuttle.git"
    "https://github.com/nicocha30/ligolo-ng.git"
    "https://github.com/GhostPack/Seatbelt.git"
    "https://github.com/GhostPack/Rubeus.git"
    "https://github.com/GhostPack/Certify.git"
    "https://github.com/GhostPack/SharpUp.git"
    "https://github.com/GhostPack/SafetyKatz.git"
    "https://github.com/GhostPack/SharpDPAPI.git"
    "https://github.com/hideckies/exploit-notes.git"
    "https://github.com/Tib3rius/windowsprivchecker.git"
    "https://github.com/mthbernardes/rsg.git"
    "https://github.com/411Hall/JAWS.git"
    "https://github.com/0xJs/OSCP_cheatsheet.git"
    "https://github.com/diego-treitos/linux-smart-enumeration.git"
    "https://github.com/enjoiz/Privesc.git"
    "https://github.com/AlessandroZ/BeRoot.git"
    "https://github.com/0xJs/CARTP-cheatsheet.git"
    "https://github.com/jondonas/linux-exploit-suggester-2.git"
    "https://github.com/PShlyundin/ldap_shell.git"
    "https://github.com/CravateRouge/autobloody.git"
    "https://github.com/CravateRouge/bloodyAD.git"
    "https://github.com/dollarboysushil/oscp-cpts-notes.git"
    "https://github.com/ly4k/Certipy.git"
    "https://github.com/ropnop/kerbrute.git"
    "https://github.com/61106960/adPEAS.git"
    "https://github.com/Kitsun3Sec/Pentest-Cheat-Sheets.git"
    "https://github.com/ShutdownRepo/pywhisker.git"
    "https://github.com/k4sth4/Abusing-rights-in-a-Domain"
    "https://github.com/adrecon/ADRecon.git"
    "https://github.com/dirkjanm/ldapdomaindump.git"
    "https://github.com/Tylous/Talon.git"
    "https://github.com/AlessandroZ/BeRoot.git"
    "https://github.com/Integration-IT/Active-Directory-Exploitation-Cheat-Sheet.git"
    "https://github.com/urbanadventurer/username-anarchy.git"
    "https://github.com/CompassSecurity/BloodHoundQueries.git"
    "https://raw.githubusercontent.com/shifty0g/ultimate-nmap-parser/refs/heads/master/ultimate-nmap-parser.sh"
    "https://github.com/padovah4ck/PSByPassCLM.git"
    "https://gist.githubusercontent.com/HarmJ0y/184f9822b195c52dd50c379ed3117993/raw/e5e30c942adb2347917563ef0dafa7054882535a/PowerView-3.0-tricks.ps1"
    "https://raw.githubusercontent.com/gladiatx0r/Powerless/refs/heads/master/Powerless.bat"
    "https://github.com/dirkjanm/krbrelayx.git"
    "https://github.com/AlmondOffSec/PassTheCert.git"
    "https://github.com/hfiref0x/UACME.git"
    "https://github.com/insidetrust/statistically-likely-usernames.git"
    "https://github.com/wietze/ArgFuscator.net.git"
    "https://github.com/wavestone-cdt/EDRSandblast.git"
    "https://github.com/TNCX-byte/PS_SSE_Shell.git"
    "https://github.com/GhnimiWael/LDAPHunter.git"
    "https://github.com/AlessandroZ/LaZagne.git"
    "https://github.com/3ndG4me/spraygen.git"
    "https://github.com/hfiref0x/UACME"
    "https://github.com/hausec/ADAPE-Script"
    "https://github.com/RedTeamOperations/Red-Infra-Craft.git"
)

# List of files to download with specific output names
files=(
    "https://gist.githubusercontent.com/joswr1ght/22f40787de19d80d110b37fb79ac3985/raw/c871f130a12e97090a08d0ab855c1b7a93ef1150/easy-simple-php-webshell.php easy-simple-php-webshell.php"
    "https://github.com/neox41/WinEnum/blob/master/WinEnum.bat WinEnum.bat"
    "https://raw.githubusercontent.com/rebootuser/LinEnum/refs/heads/master/LinEnum.sh LinEnum.sh"
    "https://raw.githubusercontent.com/peass-ng/PEASS-ng/refs/heads/master/winPEAS/winPEASps1/winPEAS.ps1"
    "https://github.com/peass-ng/PEASS-ng/releases/download/20250301-c97fb02a/winPEASx86_ofs.exe"
    "https://raw.githubusercontent.com/61106960/adPEAS/refs/heads/main/adPEAS.ps1"
    "https://www.picussecurity.com/hubfs/Threat%20Readiness%20-%20Active%20Directory%20Ebook%20-%20Q123/Picus-The-Complete-Active-Directory-Security-Handbook.pdf Picus-The-Complete-Active-Directory-Security-Handbook.pdf"
    "https://315180959-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-MRh03Vwd4nuiUi3Oje7%2Fuploads%2Fy1seVZGWtwTeflnv1xzu%2FRed_Team_and_Operational_Security.zip?alt=media&token=2d38a749-6e5e-46b1-8e6e-f622efa9d7c7 Red_Team_and_Operational_Security.zip"
    "https://github.com/pwnwiki/pwnwiki.github.io/archive/master.zip pwnwiki.zip"
    "https://raw.githubusercontent.com/frizb/MSF-Venom-Cheatsheet/refs/heads/master/README.md MSF-Venom-Cheatsheet.md"
    "https://raw.githubusercontent.com/juliourena/plaintext/refs/heads/master/Powershell/PSUpload.ps1 PSUpload.ps1"
    "https://specterops.io/wp-content/uploads/sites/3/2022/06/Certified_Pre-Owned.pdf Certified_Pre-Owned.pdf"
    "https://media.defense.gov/2024/Sep/25/2003553985/-1/-1/0/CTR-Detecting-and-Mitigating-AD-Compromises.PDF CTR-Detecting-and-Mitigating-AD-Compromises.PDF"
    "https://www.blackhat.com/docs/webcast/04262018-Webcast-Toxic-Waste-Removal-by-Andy-Robbins.pdf 04262018-Webcast-Toxic-Waste-Removal-by-Andy-Robbins.pdf"
    "https://raw.githubusercontent.com/ropnop/windapsearch/master/windapsearch.py"
    "https://raw.githubusercontent.com/drtychai/wordlists/refs/heads/master/fasttrack.txt"
    "https://raw.githubusercontent.com/insidetrust/statistically-likely-usernames/master/weak-corporate-passwords/english-basic.txt"
    "wget https://github.com/icsharpcode/AvaloniaILSpy/releases/download/v7.2-rc/Linux.x64.Release.zip"
    "wget https://downloads.apache.org/directory/studio/2.0.0.v20210717-M17/ApacheDirectoryStudio-2.0.0.v20210717-M17-linux.gtk.x86_64.tar.gz.asc"
    "wget https://downloads.apache.org/directory/studio/2.0.0.v20210717-M17/ApacheDirectoryStudio-2.0.0.v20210717-M17-linux.gtk.x86_64.tar.gz.sha512"
    "https://dlcdn.apache.org/directory/studio/2.0.0.v20210717-M17/ApacheDirectoryStudio-2.0.0.v20210717-M17-linux.gtk.x86_64.tar.gz"
    "https://raw.githubusercontent.com/infosecstreams/cheat.sheets/refs/heads/main/netexec.cheat"
    "https://raw.githubusercontent.com/pentestmonkey/finger-user-enum/refs/heads/master/finger-user-enum.pl"
    "https://raw.githubusercontent.com/TeneBrae93/CVE-2025-3243/refs/heads/main/CVE-2025-3243.py"
    "https://github.com/blue0x1/uac-bypass-oneliners"
    "https://github.com/ly4k/Certipy"
)

#"https://mega.nz/file/cr5HGACC#ANXlTyu8sdlIUizcIX418sa1C2M4Ame_3bjxU9xXGfY brockyou.txt.zip"
#"https://cornerpirate.com/2021/06/17/grabbing-ntlm-hashes-with-responder-then-what/"
#"https://labs.nettitude.com/tools/rocktastic/"

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

