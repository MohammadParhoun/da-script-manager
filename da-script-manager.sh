#!/bin/bash

GREEN="\e[32m"
GREEN2="\e[1;32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[1;36m"
BRIGHT_WHITE="\e[1;37m"
RESET="\e[0m"

if ! command -v curl &>/dev/null; then
    echo -e "${RED}'curl' is not installed. Please install it first.${RESET}"
    exit 1
fi

cleanup_temp_scripts() {
    find "$TMP_DIR" -maxdepth 1 -type f ! -name "*.log" -delete
    echo
    echo
    exit 1
}

trap cleanup_temp_scripts SIGINT SIGTSTP

GITHUB_USER="MohammadParhoun"
GITHUB_BRANCH="main"

TMP_DIR="/tmp/da-scripts"
mkdir -p "$TMP_DIR"

declare -A myscripts=(
    #script_name=github_repo
    ["directadmin-config.sh"]="directadmin-config"
    ["da-php.sh"]="da-php"
    ["sourceGuardian-auto-installer.sh"]="sourceguardian-auto-installer"
    ["da-ssh.sh"]="da-ssh"
    ["csf-installer.sh"]="CSF-installer"
)

downloader() {
    local script_name="$1"
    local local_script_path="$TMP_DIR/$script_name"
    local repo_name="${myscripts[$script_name]}"
    
    local url="https://raw.githubusercontent.com/$GITHUB_USER/$repo_name/refs/heads/$GITHUB_BRANCH/$script_name"
    
    if curl -fsSL "$url" -o "$local_script_path"; then
        chmod +x "$local_script_path"
        return 0
    else
        echo -e "${RED}Failed to download '$script_name' from GitHub.${RESET}"
        return 1
    fi
}

script_runner() {
    local script_name="$1"
    local local_script_path="$TMP_DIR/$script_name"
    local log_file="$TMP_DIR/$script_name.log"


    if [[ ! -x $local_script_path ]]; then
        if downloader $script_name; then
            echo -e "${GREEN}$script_name has been downloaded${RESET}"
        else
            echo -e "${RED}$script_name not found or download failed${RESET}"
            return 1
        fi
    fi

    
    echo "Executing $script_name..."

    if "$local_script_path" | tee "$log_file"; then
            echo -e "${GREEN}\ndone${RESET}\n"
            #echo -e "${GREEN}\n✓ $script_name script executed successfully.${RESET}\n"
        else
            echo -e "${RED}\n$script_name script failed. See log: $log_file ${RESET}\n"
            return 1
    fi
}

run_all_scripts() {
    script_order=("csf-installer.sh" "directadmin-config.sh" "da-php.sh" "sourceGuardian-auto-installer.sh" "da-ssh.sh")
    for script in ${script_order[@]}; do
        echo "Running $script..."
        if ! script_runner $script; then
            echo -e "${RED}failed to execute $script script. Stopped.${RESET}"
            return 1
        fi
    done

    echo -e "${GREEN}All scripts executed successfully.${RESET}"
    return 0

}


while true; do
    echo
    echo -e "${GREEN2}  Directadmin Script Manager${RESET}"
    echo -e "${GREEN2}----------------------------------------------${RESET}"
    echo -e "${GREEN2}  1.${BRIGHT_WHITE} DirectAdmin Config Script${RESET}"
    echo -e "${GREEN2}  2.${BRIGHT_WHITE} DirectAdmin PHP Configuration Script${RESET}"
    echo -e "${GREEN2}  3.${BRIGHT_WHITE} SourceGuardian Installer Script${RESET}"
    echo -e "${GREEN2}  4.${BRIGHT_WHITE} SSH Configuration for DirectAdmin${RESET}"
    echo -e "${GREEN2}  5.${BRIGHT_WHITE} CSF Installation${RESET}"
    echo -e "${GREEN2}  6.${BRIGHT_WHITE} All Scripts${RESET}"
    echo -e "${GREEN2}  7.${BRIGHT_WHITE} Exit${RESET}"
    echo

    read -p "$(echo -e "${BRIGHT_WHITE}Enter your choice [1-7]: ${RESET}")" choice

    case $choice in
    1) script_runner "directadmin-config.sh" ;;
    2) script_runner "da-php.sh" ;;
    3) script_runner "sourceGuardian-auto-installer.sh" ;;
    4) script_runner "da-ssh.sh" ;;
    5) script_runner "csf-installer.sh" ;;
    6) run_all_scripts ;;
    7) echo "Exiting..."
            break ;;
    *) echo -e "${RED}Invalid choice. Please try again.${RESET}" ;;
    esac

done

echo
read -p "$(echo -e "${YELLOW}Do you want to keep the log files? (y/N): ${RESET}")" keep_logs

if [[ "$keep_logs" =~ ^[Yy]$ ]]; then
    find "$TMP_DIR" -maxdepth 1 -type f ! -name "*.log" -delete
    echo "Logs are kept in $TMP_DIR. Script files removed."
else
    rm -rf "$TMP_DIR"
    echo -e "${GREEN}All temporary files and logs in $TMP_DIR removed.${RESET}"
fi
    
exit 0


