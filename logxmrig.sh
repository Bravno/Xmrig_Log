#!/bin/bash

# Configuration
POOL="xmr-eu1.nanopool.org:14444"
WALLET="4A9SeKhwWx8DtAboVp1e1LdbgrRJxvjEFNh4VNw1NDng6ELLeKJPVrPQ9n9eNc4iLVC4BKeR4egnUL68D1qUmdJ7N3TaB5w"
LOGFILE="/var/log/xmrig_install.log"

# Functions
log() {
    echo "$(date) - $1" | tee -a $LOGFILE
}

install_dependencies() {
    log "Installing dependencies..."

    if command -v apt-get &> /dev/null; then
        log "Detected apt-based system."
        sudo apt-get update -y
        sudo apt-get install -y build-essential cmake libuv1-dev libssl-dev libhwloc-dev
    elif command -v yum &> /dev/null; then
        log "Detected yum-based system."
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y cmake libuv-devel openssl-devel hwloc-devel
    elif command -v zypper &> /dev/null; then
        log "Detected zypper-based system."
        sudo zypper install -y gcc gcc-c++ make cmake libuv-devel openssl-devel hwloc-devel
    else
        log "Unsupported package manager. Exiting."
        exit 1
    fi
}

download_xmrig() {
    log "Downloading XMRig..."
    cd /tmp
    wget https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-x64.tar.gz -O xmrig.tar.gz
    tar -xzf xmrig.tar.gz
    cd xmrig-6.20.0
}

configure_xmrig() {
    log "Configuring XMRig..."
    cat > config.json <<EOF
{
    "algo": "cn/2",
    "url": "$POOL",
    "user": "$WALLET",
    "pass": "x",
    "rig-id": "rig1",
    "max-cpu-usage": 75,
    "cpu-priority": 5,
    "threads": null,
    "pools": [
        {
            "url": "$POOL",
            "user": "$WALLET",
            "pass": "x"
        }
    ],
    "api": {
        "enabled": true,
        "port": 0
    },
    "http": {
        "enabled": false
    }
}
EOF
}

install_xmrig() {
    log "Installing XMRig..."
    sudo mv xmrig /usr/local/bin/xmrig
    sudo chmod +x /usr/local/bin/xmrig
    sudo ln -s /usr/local/bin/xmrig /usr/bin/xmrig
}

start_xmrig() {
    log "Starting XMRig..."
    xmrig --config=config.json &>> $LOGFILE &
}

cleanup() {
    log "Cleaning up..."
    rm -rf /tmp/xmrig*
}

# Main
log "Starting XMRig installation script."

install_dependencies
download_xmrig
configure_xmrig
install_xmrig
start_xmrig
cleanup

log "XMRig installation complete."
