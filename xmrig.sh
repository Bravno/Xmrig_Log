#!/bin/bash

# Определение пути к скрипту
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# Установка прав на выполнение для самого скрипта
chmod +x "$SCRIPT_PATH"

# Функция для установки зависимостей
install_dependencies() {
    if [ -f /etc/redhat-release ]; then
        # Для Red Hat/CentOS
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y cmake hwloc-devel libuv-devel
    else
        # Для Debian/Ubuntu
        sudo apt update
        sudo apt install -y cmake build-essential libhwloc-dev libuv1-dev python3-pip
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
    git clone https://github.com/xmrig/xmrig.git
    cd xmrig || { echo "Не удалось перейти в директорию xmrig"; exit 1; }

    # Создание директории для сборки и сборка XMRig
    mkdir -p build
    cd build || { echo "Не удалось перейти в директорию build"; exit 1; }
    cmake .. || { echo "Ошибка конфигурации CMake"; exit 1; }
    make || { echo "Ошибка сборки XMRig"; exit 1; }
}

# Функция для создания конфигурационного файла
create_config_file() {
    cat <<EOL > config.json
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
    LOGFILE="/root/Xmrig_Log/xmrig/build/xmrig.log"
    
    # Создание директории для файла лога
    mkdir -p "$(dirname "$LOGFILE")" || { echo "Не удалось создать директорию для файла лога"; exit 1; }
    
    # Создание файла лога
    touch "$LOGFILE"

    # Запуск XMRig и логирование в реальном времени
    ./xmrig --config=config.json | tee -a "$LOGFILE"
}

# Запуск всех функций
install_dependencies
install_python_packages
build_xmrig
create_config_file
run_xmrig
