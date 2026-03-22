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

case "$1" in
    install)
        echo "Downloading and Installing MastRadar (Fork of AIS Catcher)..."

        BASE_URL="https://qqnqihvqgwdmfcdwduvk.supabase.co/storage/v1/object/public/publicFiles/MastRadar/"

        ARCH=$(dpkg --print-architecture)
        OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        CODENAME=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')

        case "$ARCH" in
            amd64) ARCH_SUFFIX="amd64" ;;
            arm64) ARCH_SUFFIX="arm64" ;;
            armhf) ARCH_SUFFIX="armhf" ;;
            *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
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
            echo "Redirecting $OS $ORIGINAL_CODENAME to nearest LTS build: $CODENAME"
        fi

        FILE="ais-catcher_${OS}_${CODENAME}_${ARCH_SUFFIX}.deb"

        wget "$BASE_URL/$FILE" -O "/tmp/$FILE" || { echo "Failed to download $FILE"; exit 1; }
        sudo apt install -y "/tmp/$FILE"
        echo "MastRadar/AIS-catcher installed successfully."

        SCRIPT_NAME="mastcontrol"
        wget -O "/usr/local/bin/$SCRIPT_NAME" "https://raw.githubusercontent.com/mastchain/mastcontrol/refs/heads/main/mastcontrol.sh" \
            || { echo "Failed to download mastcontrol script"; exit 1; }
        chmod +x "/usr/local/bin/$SCRIPT_NAME"

        echo "MastRadar/AIS-catcher installed. Let's set it up."
        # Kick off configuration immediately after install
        /usr/local/bin/mastcontrol configure
        ;;
    configure)
        echo "Configuring MastRadar (Fork of AIS Catcher)..."
        echo "Enter your USERPWD parameter for this station"
        echo "e.g. (email@domain.com:vzXhH9BQm3Ju2h+kQEispt9wOVA+H7wlOD0omNwgnjY=)"
        read -p "USERPWD: " token </dev/tty
        read -p "Any additional command line arguments for MastRadar/AIS-catcher (e.g. -N 8100): " args </dev/tty

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
            echo "MastRadar restarted successfully."
        else
            systemctl start mastradar.service
            echo "MastRadar installed and started successfully."
        fi
        /usr/local/bin/mastcontrol status
        ;;
    start)
        echo "Starting MastRadar..."
        systemctl start mastradar.service
        echo "mastradar started."
        ;;
    stop)
        echo "Stopping MastRadar..."
        systemctl stop mastradar.service
        echo "mastradar stopped."
        ;;
    status)
        echo "MastRadar service status:"
        systemctl status mastradar.service --no-pager
        ;;
    log)
        echo "Recent MastRadar logs:"
        journalctl -u mastradar.service -n 100 --no-pager
        ;;
    update)
        echo "Updating mastcontrol..."
        wget -O "/usr/local/bin/mastcontrol" "https://raw.githubusercontent.com/mastchain/mastcontrol/refs/heads/main/mastcontrol.sh" \
            || { echo "Failed to download update."; exit 1; }
        chmod +x "/usr/local/bin/mastcontrol"
        echo "mastcontrol updated successfully."
        echo "Version info:"
        head -3 /usr/local/bin/mastcontrol
        ;;
    *)
        echo ""
        echo "Usage: $0 {install|configure|update|start|stop|status|log}"
        echo ""
        echo "Commands:"
        echo "  install    - Download and install MastRadar and this control script"
        echo "  configure  - Set your station credentials and start the service"
        echo "               (automatically runs after install)"
        echo "  update     - Update this control script to the latest version"
        echo "  start      - Start the MastRadar service"
        echo "  stop       - Stop the MastRadar service"
        echo "  status     - Show current service status"
        echo "  log        - Show the last 100 lines of service logs"
        echo ""
        exit 1
        ;;
esac

exit 0