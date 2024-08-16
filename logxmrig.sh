#!/bin/bash

# Параметры
POOL="xmr-eu1.nanopool.org:14444"
WALLET="4A9SeKhwWx8DtAboVp1e1LdbgrRJxvjEFNh4VNw1NDng6ELLeKJPVrPQ9n9eNc4iLVC4BKeR4egnUL68D1qUmdJ7N3TaB5w"

# Функция для вывода сообщений
log_message() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Установка зависимостей и XMRig
install_xmrig() {
    log_message "Запуск установки XMRig"

    # Обновление системы
    log_message "Обновление системы"
    if [ -x "$(command -v apt-get)" ]; then
        apt-get update -y && apt-get upgrade -y
        apt-get install -y \
            build-essential cmake git libhwloc-dev \
            autoconf automake libtool pkg-config \
            libssl-dev libjansson-dev \
            libunwind-dev zlib1g-dev \
            libcurl4-openssl-dev \
            software-properties-common
    elif [ -x "$(command -v yum)" ]; then
        yum update -y
        yum groupinstall -y "Development Tools"
        yum install -y \
            cmake git hwloc-devel \
            autoconf automake libtool pkgconfig \
            openssl-devel jansson-devel \
            libcurl-devel zlib-devel \
            unzip wget
    elif [ -x "$(command -v zypper)" ]; then
        zypper refresh
        zypper update -y
        zypper install -y \
            gcc-c++ cmake git hwloc-devel \
            autoconf automake libtool pkg-config \
            libopenssl-devel jansson-devel \
            libcurl-devel zlib-devel \
            unzip wget
    elif [ -x "$(command -v pacman)" ]; then
        pacman -Syu --noconfirm
        pacman -S --noconfirm \
            base-devel cmake git hwloc \
            autoconf automake libtool \
            openssl jansson \
            libcurl zlib \
            unzip wget
    else
        log_message "Неизвестный пакетный менеджер, установка прервана"
        exit 1
    fi

    # Клонирование репозитория XMRig
    log_message "Клонирование репозитория XMRig"
    git clone https://github.com/xmrig/xmrig.git
    cd xmrig || exit

    # Сборка XMRig
    log_message "Сборка XMRig"
    mkdir build
    cd build || exit
    cmake ..
    make -j"$(nproc)" | tee build.log

    # Создание конфигурационного файла
    log_message "Создание конфигурационного файла XMRig"
    cat > config.json <<EOF
{
    "pool": [
        {
            "url": "$POOL",
            "user": "$WALLET",
            "pass": "x"
        }
    ],
    "donate-level": 1,
    "log-file": "xmrig.log",
    "max-cpu-usage": 75
}
EOF

    # Запуск XMRig
    log_message "Запуск XMRig"
    ./xmrig --config=config.json | tee xmrig.log
}

# Запуск функции установки
install_xmrig
