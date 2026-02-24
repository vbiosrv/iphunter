# 🎯 VK Cloud Subnet Hunter

<p align="center">
  <img src="https://img.shields.io/badge/version-3.3-blue.svg" alt="Version 3.3">
  <img src="https://img.shields.io/badge/platform-linux-lightgrey.svg" alt="Platform Linux">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License MIT">
  <img src="https://img.shields.io/badge/OpenStack-compatible-orange.svg" alt="OpenStack Compatible">
</p>

<p align="center">
  <b>Автоматический охотник за IP-адресами с нужными префиксами в VK Cloud</b><br>
  <i>Интеллектуальный перебор подсетей OpenStack с защитой важного IP</i>
</p>

---

## 📋 Оглавление

- [📖 Описание](#-описание)
- [💡 Для чего это нужно?](#-для-чего-это-нужно)
- [✨ Возможности](#-возможности)
- [💻 Требования](#-требования)
- [🚀 Быстрая установка](#-быстрая-установка)
- [⚙️ Настройка](#️-настройка)
- [🎮 Использование](#-использование)
- [🔄 Как это работает](#-как-это-работает)
- [📊 Примеры работы](#-примеры-работы)
- [🔧 Устранение проблем](#-устранение-проблем)
- [❓ FAQ](#-faq)
- [🔒 Безопасность](#-безопасность)
- [📜 Лицензия](#-лицензия)

---

## 📖 Описание

**VK Cloud Subnet Hunter** — это Bash-скрипт для автоматического поиска публичных floating IP-адресов с заданными префиксами в облачной платформе VK Cloud (OpenStack).

Скрипт:

- Перебирает указанные внешние подсети  
- Создаёт floating IP  
- Проверяет соответствие заданным префиксам  
- Удаляет неподходящие IP  
- Останавливается при успешном совпадении  

Работает полностью автоматически 🔥

---

## 💡 Для чего это нужно?

- 🌍 Получение IP определённого региона
- ⚙ Автоматизация подбора «белых» IP
- 🧪 Тестирование доступности разных подсетей
- 🌐 Работа с гео-зависимыми сервисами
- 🔎 Анализ распределения адресов в облаке

---

## ✨ Возможности

- ✅ Перебор нескольких подсетей
- ✅ Гибкая настройка приоритетов префиксов
- ✅ Защита важного IP от удаления
- ✅ Цветной CLI-интерфейс
- ✅ Случайные задержки (anti-spam поведение)
- ✅ Детальная статистика попыток
- ✅ Работа через OpenStack CLI
- ✅ Linux / macOS / WSL

---

## 💻 Требования

### Система

- Linux (Ubuntu 18.04+, Debian 10+, CentOS 7+)
- или WSL
- Bash 4.0+
- Доступ к интернету

### OpenStack CLI

Установка через pip:

```bash
pip3 install python-openstackclient

Или через пакетный менеджер:

# Ubuntu / Debian
apt install python3-openstackclient

# CentOS / RHEL
yum install python3-openstackclient

# Arch
pacman -S python-openstackclient
В VK Cloud

Активный проект

OpenRC файл

Права на создание floating IP

Доступные внешние подсети

🚀 Быстрая установка
1️⃣ Клонирование
git clone https://github.com/idsmef/vk-cloud-subnet-hunter.git
cd vk-cloud-subnet-hunter
2️⃣ Права на запуск
chmod +x vk-subnet-hunter.sh
3️⃣ Получение OpenRC

Личный кабинет → API доступ → скачать project-openrc.sh

mv ~/Downloads/project-openrc.sh ./
4️⃣ Запуск
./vk-subnet-hunter.sh
⚙️ Настройка

В начале скрипта:

# Целевые подсети
TARGET_SUBNETS=("ext-sub19" "ext-sub21" "ext-sub24")

# Искомые префиксы (по приоритету)
PREFIXES=("89." "5." "95." "94.")

# Защищённый IP (не удаляется)
SAVED_IP="90.x.x.x"

# Задержки
MIN_DELAY=3
MAX_DELAY=7
Просмотр подсетей
openstack subnet list
🎮 Использование
Обычный запуск
./vk-subnet-hunter.sh
С передачей пароля
export OS_PASSWORD="your_password"
./vk-subnet-hunter.sh
В фоне
nohup ./vk-subnet-hunter.sh > hunter.log 2>&1 &
tail -f hunter.log
Через cron
0 3 * * * cd /home/user/vk-hunter && ./vk-subnet-hunter.sh >> /var/log/hunter.log 2>&1
🔄 Как это работает
СТАРТ
  ↓
Аутентификация
  ↓
Поиск подсетей
  ↓
Удаление старых IP (кроме saved)
  ↓
Создание нового IP
  ↓
Проверка префикса
  ↓
Совпало? → 🏆 УСПЕХ
Не совпало? → Задержка → Повтор

Алгоритм повторяется до успешного совпадения.

📊 Пример успешного поиска
│ 1 │ 95.67.89.10  │ ❌ Мимо
│ 2 │ 89.123.45.67 │ ✅ БИНГО!
🏆 ПОЗДРАВЛЯЮ! ЦЕЛЕВОЙ IP НАЙДЕН!
IP: 89.123.45.67
Попыток: 2
Время: 2024-01-15 14:23:45
🔧 Устранение проблем
❌ OpenStack не найден
which openstack
pip3 install python-openstackclient
❌ Ошибка аутентификации
source project-openrc.sh
openstack token issue
❌ Не найдены подсети
openstack subnet list
❌ Не хватает квоты
openstack quota show
openstack floating ip list
❓ FAQ

Сколько времени занимает поиск?
От 1 до 30 минут в среднем.

Это безопасно?
Да. Используются случайные задержки и имитация ручной работы.

Можно ли искать любые префиксы?
Да:

PREFIXES=("109." "176.")

Сколько это стоит?
Создание floating IP бесплатно.
Использование IP — тарифицируется согласно тарифам VK Cloud.

🔒 Безопасность
chmod 600 project-openrc.sh
chmod 700 vk-subnet-hunter.sh

Рекомендации:

🔐 Не храните пароль в открытом виде

📝 Ведите лог найденных IP

🗑️ Удаляйте неиспользуемые адреса

👤 Не передавайте credentials третьим лицам

📜 Лицензия

MIT License

Свободное использование, изменение и распространение.
