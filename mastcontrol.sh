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

# Colors
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
NC='\033[0m'

case "$1" in
    install)
        echo -e "${BLUE}Downloading and Installing MastRadar (Fork of AIS Catcher)...${NC}"

        BASE_URL="https://qqnqihvqgwdmfcdwduvk.supabase.co/storage/v1/object/public/publicFiles/MastRadar/"

        ARCH=$(dpkg --print-architecture)
        OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        CODENAME=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')

        case "$ARCH" in
            amd64) ARCH_SUFFIX="amd64" ;;
            arm64) ARCH_SUFFIX="arm64" ;;
            armhf) ARCH_SUFFIX="armhf" ;;
            *) echo -e "${BLUE}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
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
            echo -e "${BLUE}Redirecting $OS $ORIGINAL_CODENAME to nearest LTS build: $CODENAME${NC}"
        fi

        FILE="ais-catcher_${OS}_${CODENAME}_${ARCH_SUFFIX}.deb"

        wget "$BASE_URL/$FILE" -O "/tmp/$FILE" || { echo -e "${BLUE}Failed to download $FILE${NC}"; exit 1; }
        sudo apt install -y "/tmp/$FILE"
        echo -e "${BLUE}MastRadar/AIS-catcher installed successfully.${NC}"

        SCRIPT_NAME="mastcontrol"
        wget -O "/usr/local/bin/$SCRIPT_NAME" "https://raw.githubusercontent.com/mastchain/mastcontrol/refs/heads/main/mastcontrol.sh" \
            || { echo -e "${BLUE}Failed to download mastcontrol script${NC}"; exit 1; }
        chmod +x "/usr/local/bin/$SCRIPT_NAME"

        echo -e "${BLUE}MastRadar/AIS-catcher installed. Let's set it up.${NC}"
        # Kick off configuration immediately after install
        /usr/local/bin/mastcontrol configure
        ;;
    configure)
        echo -e "${BLUE}Configuring MastRadar (Fork of AIS Catcher)...${NC}"
        echo -e "${BLUE}Enter your USERPWD parameter for this station${NC}"
        echo -e "${BLUE}e.g. (email@domain.com:vzXhH9BQm3Ju2h+kQEispt9wOVA+H7wlOD0omNwgnjY=)${NC}"
        printf "${MAGENTA}USERPWD: ${NC}" >/dev/tty
        read token </dev/tty
        printf "${MAGENTA}Any additional command line arguments for MastRadar/AIS-catcher (e.g. -N 8100): ${NC}" >/dev/tty
        read args </dev/tty
        printf "${BLUE}Creating systemd service file...${NC}" >/dev/tty
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
            echo -e "${BLUE}MastRadar restarted successfully.${NC}"
        else
            systemctl start mastradar.service
            echo -e "${BLUE}MastRadar installed and started successfully.${NC}"
        fi
        /usr/local/bin/mastcontrol status
        ;;
    start)
        echo -e "${BLUE}Starting MastRadar...${NC}"
        systemctl start mastradar.service
        echo -e "${BLUE}mastradar started.${NC}"
        ;;
    stop)
        echo -e "${BLUE}Stopping MastRadar...${NC}"
        systemctl stop mastradar.service
        echo -e "${BLUE}mastradar stopped.${NC}"
        ;;
    status)
        echo -e "${BLUE}MastRadar service status:${NC}"
        systemctl status mastradar.service --no-pager
        ;;
    log)
        echo -e "${BLUE}Recent MastRadar logs:${NC}"
        journalctl -u mastradar.service -n 100 --no-pager
        ;;
    update)
        echo -e "${BLUE}Updating mastcontrol...${NC}"
        wget -O "/usr/local/bin/mastcontrol" "https://raw.githubusercontent.com/mastchain/mastcontrol/refs/heads/main/mastcontrol.sh" \
            || { echo -e "${BLUE}Failed to download update.${NC}"; exit 1; }
        chmod +x "/usr/local/bin/mastcontrol"
        echo -e "${BLUE}mastcontrol updated successfully.${NC}"
        echo -e "${BLUE}Version info:${NC}"
        head -3 /usr/local/bin/mastcontrol
        ;;
    *)
        echo ""
        echo -e "${BLUE}Usage: $0 {install|configure|update|start|stop|status|log}${NC}"
        echo ""
        echo -e "${BLUE}Commands:${NC}"
        echo -e "${BLUE}  install    - Download and install MastRadar and this control script${NC}"
        echo -e "${BLUE}  configure  - Set your station credentials and start the service${NC}"
        echo -e "${BLUE}               (automatically runs after install)${NC}"
        echo -e "${BLUE}  update     - Update this control script to the latest version${NC}"
        echo -e "${BLUE}  start      - Start the MastRadar service${NC}"
        echo -e "${BLUE}  stop       - Stop the MastRadar service${NC}"
        echo -e "${BLUE}  status     - Show current service status${NC}"
        echo -e "${BLUE}  log        - Show the last 100 lines of service logs${NC}"
        echo ""
        exit 1
        ;;
esac

exit 0
