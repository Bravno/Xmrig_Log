#!/bin/bash

# Определение пути к скрипту
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# Установка прав на выполнение для самого скрипта
chmod +x "$SCRIPT_PATH"

# Обновление и установка необходимых пакетов
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

# Установка Python-пакетов
pip3 install --upgrade pip
pip3 install requests

# Клонирование репозитория XMRig
git clone https://github.com/xmrig/xmrig.git
cd xmrig

# Создание директории для сборки и сборка XMRig
mkdir build
cd build
cmake ..
make

# Создание конфигурационного файла config.json
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

# Создание файла лога
LOGFILE="/root/Xmrig_Log/xmrig/build/xmrig.log"
touch $LOGFILE

# Запуск XMRig и логирование в реальном времени
./xmrig --config=config.json | tee -a $LOGFILE
