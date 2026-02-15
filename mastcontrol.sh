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
            # Simple mapping to nearest LTS
            case "$CODENAME" in
                focal|kinetic) CODENAME="jammy" ;;
                lunar) CODENAME="noble" ;;
                *) CODENAME="plucky" ;; 
            esac
            echo "Redirecting $OS $CODENAME to nearest LTS build: $CODENAME"
        fi

        FILE="ais-catcher_${OS}_${CODENAME}_${ARCH_SUFFIX}.deb"

        wget "$BASE_URL/$FILE" -O "/tmp/$FILE" || { echo "Failed to download $FILE"; exit 1; }
        sudo apt install -y "/tmp/$FILE"
        echo "MastRadar/AIS-catcher installed successfully."

        cp "$0" /usr/local/bin/mastcontrol
        chmod +x /usr/local/bin/mastcontrol

        echo "You can now use the 'mastcontrol' command to control the MastRadar service."
        echo "For example, to start the service, run 'mastcontrol start'."
        echo "To stop the service, run 'mastcontrol stop'."
        ;;
    configure)
        echo "Configuring MastRadar (Fork of AIS Catcher)..."
        echo "Enter your USERPWD parameter for this station"
        echo "e.g. (email@domain.com:vzXhH9BQm3Ju2h+kQEispt9wOVA+H7wlOD0omNwgnjY=)"
        read -p "USERPWD: " token
        read -p "Any additional command line arguments for MastRadar/AIS-catcher (e.g. -N 8100): " args

        SERVICE_FILE_CONTENT="[Unit]
Description=MastRadar (Fork of AIS Catcher)
After=network.target

[Service]
ExecStart=/usr/local/bin/AIS-catcher -H https://api.mastchain.io/api/upload USERPWD ${token} INTERVAL 60 ${args}
Restart=always
User=root

[Install]
WantedBy=multi-user.target"

        echo "Setting things up..."
        echo "$SERVICE_FILE_CONTENT" > /etc/systemd/system/mastradar.service
        systemctl daemon-reload
        systemctl enable mastradar.service
        systemctl start mastradar.service
        
        echo "MastRadar installed and started successfully."
    
        ;;
    start)
        echo "Starting MastRadar..."
        sudo systemctl start mastradar.service
        echo "mastradar started."
        ;;
    stop)
        echo "Stopping MastRadar..."
        sudo systemctl stop mastradar.service
        echo "mastradar stopped."
        ;;
    *)
        echo "Usage: $0 {install|start|stop}"
        exit 1
        ;;
esac

exit 0