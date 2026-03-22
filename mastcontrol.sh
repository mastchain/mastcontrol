#!/bin/bash

# mastcontrol.sh
# This script provides basic install, start, and stop commands for mastcontrol.

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root or with sudo."
    # Re-run the script with sudo
    echo "Attempting to re-run with sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Colors (safe for both light and dark terminals)
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

case "$1" in
    install)
        echo -e "${CYAN}Downloading and Installing MastRadar (Fork of AIS Catcher)...${NC}"

        BASE_URL="https://qqnqihvqgwdmfcdwduvk.supabase.co/storage/v1/object/public/publicFiles/MastRadar/"

        ARCH=$(dpkg --print-architecture)
        OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        CODENAME=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')

        case "$ARCH" in
            amd64) ARCH_SUFFIX="amd64" ;;
            arm64) ARCH_SUFFIX="arm64" ;;
            armhf) ARCH_SUFFIX="armhf" ;;
            *) echo -e "${CYAN}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
        esac

        # Define available builds
        AVAILABLE=("jammy" "noble" "plucky" "bookworm" "trixie")

        # Redirect non-available Ubuntu versions to closest LTS
        if [[ "$OS" == "ubuntu" && ! " ${AVAILABLE[@]} " =~ " $CODENAME " ]]; then
            ORIGINAL_CODENAME="$CODENAME"
            # Simple mapping to nearest LTS
            case "$CODENAME" in
                focal|kinetic) CODENAME="jammy" ;;
                lunar) CODENAME="noble" ;;
                *) CODENAME="plucky" ;;
            esac
            echo -e "${CYAN}Redirecting $OS $ORIGINAL_CODENAME to nearest LTS build: $CODENAME${NC}"
        fi

        FILE="ais-catcher_${OS}_${CODENAME}_${ARCH_SUFFIX}.deb"

        wget "$BASE_URL/$FILE" -O "/tmp/$FILE" || { echo -e "${CYAN}Failed to download $FILE${NC}"; exit 1; }
        sudo apt install -y "/tmp/$FILE"
        echo -e "${CYAN}MastRadar/AIS-catcher installed successfully.${NC}"

        SCRIPT_NAME="mastcontrol"
        wget -O "/usr/local/bin/$SCRIPT_NAME" "https://raw.githubusercontent.com/mastchain/mastcontrol/refs/heads/main/mastcontrol.sh" \
            || { echo -e "${CYAN}Failed to download mastcontrol script${NC}"; exit 1; }
        chmod +x "/usr/local/bin/$SCRIPT_NAME"

        echo -e "${CYAN}MastRadar/AIS-catcher installed. Let's set it up.${NC}"
        # Kick off configuration immediately after install
        /usr/local/bin/mastcontrol configure
        ;;
    configure)
        echo -e "${CYAN}Configuring MastRadar (Fork of AIS Catcher)...${NC}"
        echo -e "${CYAN}Enter your USERPWD parameter for this station${NC}"
        echo -e "${CYAN}e.g. (email@domain.com:vzXhH9BQm3Ju2h+kQEispt9wOVA+H7wlOD0omNwgnjY=)${NC}"
        printf "${YELLOW}USERPWD: ${NC}" >/dev/tty
        read token </dev/tty
        printf "${YELLOW}Any additional command line arguments for MastRadar/AIS-catcher (e.g. -N 8100): ${NC}" >/dev/tty
        read args </dev/tty

        SERVICE_FILE_CONTENT="[Unit]
Description=MastRadar (Fork of AIS Catcher)
After=network.target

[Service]
ExecStart=/usr/bin/AIS-catcher -H https://api.mastchain.io/api/upload USERPWD ${token} INTERVAL 60 ${args}
Restart=always
User=root

[Install]
WantedBy=multi-user.target"

        echo "$SERVICE_FILE_CONTENT" > /etc/systemd/system/mastradar.service
        systemctl daemon-reload
        systemctl enable mastradar.service

        if systemctl is-active --quiet mastradar.service; then
            systemctl restart mastradar.service
            echo -e "${CYAN}MastRadar restarted successfully.${NC}"
        else
            systemctl start mastradar.service
            echo -e "${CYAN}MastRadar installed and started successfully.${NC}"
        fi
        /usr/local/bin/mastcontrol status
        ;;
    start)
        echo -e "${CYAN}Starting MastRadar...${NC}"
        systemctl start mastradar.service
        echo -e "${CYAN}mastradar started.${NC}"
        ;;
    stop)
        echo -e "${CYAN}Stopping MastRadar...${NC}"
        systemctl stop mastradar.service
        echo -e "${CYAN}mastradar stopped.${NC}"
        ;;
    status)
        echo -e "${CYAN}MastRadar service status:${NC}"
        systemctl status mastradar.service --no-pager
        ;;
    log)
        echo -e "${CYAN}Recent MastRadar logs:${NC}"
        journalctl -u mastradar.service -n 100 --no-pager
        ;;
    update)
        echo -e "${CYAN}Updating mastcontrol...${NC}"
        wget -O "/usr/local/bin/mastcontrol" "https://raw.githubusercontent.com/mastchain/mastcontrol/refs/heads/main/mastcontrol.sh" \
            || { echo -e "${CYAN}Failed to download update.${NC}"; exit 1; }
        chmod +x "/usr/local/bin/mastcontrol"
        echo -e "${CYAN}mastcontrol updated successfully.${NC}"
        echo -e "${CYAN}Version info:${NC}"
        head -3 /usr/local/bin/mastcontrol
        ;;
    *)
        echo ""
        echo -e "${CYAN}Usage: $0 {install|configure|update|start|stop|status|log}${NC}"
        echo ""
        echo -e "${CYAN}Commands:${NC}"
        echo -e "${CYAN}  install    - Download and install MastRadar and this control script${NC}"
        echo -e "${CYAN}  configure  - Set your station credentials and start the service${NC}"
        echo -e "${CYAN}               (automatically runs after install)${NC}"
        echo -e "${CYAN}  update     - Update this control script to the latest version${NC}"
        echo -e "${CYAN}  start      - Start the MastRadar service${NC}"
        echo -e "${CYAN}  stop       - Stop the MastRadar service${NC}"
        echo -e "${CYAN}  status     - Show current service status${NC}"
        echo -e "${CYAN}  log        - Show the last 100 lines of service logs${NC}"
        echo ""
        exit 1
        ;;
esac

exit 0
