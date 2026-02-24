#!/bin/bash

# ========== ЦВЕТА И СТИЛИ ==========
RESET='\033[0m'
BOLD='\033[1m'

# Обычные цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Яркие цвета
BRIGHT_RED='\033[1;31m'
BRIGHT_GREEN='\033[1;32m'
BRIGHT_YELLOW='\033[1;33m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_PURPLE='\033[1;35m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_WHITE='\033[1;37m'
BRIGHT_BLACK='\033[1;30m'

# ========== НАСТРОЙКИ ==========
# Список подсетей для охоты
TARGET_SUBNETS=("ext-sub19" "ext-sub21" "ext-sub24" "ext-sub35" "ext-sub37")

# Искомые префиксы (в порядке приоритета)
PREFIXES=("89." "5." "95." "95." "94." "37.")

# IP, который нельзя удалять (защищенный)
SAVED_IP="90.x.x.x"

# Задержки между попытками (секунды)
MIN_DELAY=3
MAX_DELAY=7

# ========== ШАПКА ==========
clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${CYAN}                                                                            ${RESET}"
echo -e "${CYAN}  ${BOLD}${BRIGHT_YELLOW}⚡ VK CLOUD SUBNET HUNTER v3.3 ⚡${RESET}                                          ${CYAN}${RESET}"
echo -e "${CYAN}  ${BRIGHT_GREEN}🎯 Охотник за российскими IP-адресами${RESET}                                       ${CYAN}${RESET}"
echo -e "${CYAN}                                                                            ${RESET}"
echo -e "${CYAN}  ${BRIGHT_PURPLE}✨ Создатель: ${BOLD}@idsmef${RESET}                                                  ${CYAN}${RESET}"
echo -e "${CYAN}  ${BRIGHT_BLUE}📱 Telegram: ${BOLD}https://t.me/idsmef${RESET}                                         ${CYAN}${RESET}"
echo -e "${CYAN}                                                                            ${RESET}"
echo -e "${CYAN}  ${BRIGHT_GREEN}📡 Целевые префиксы: ${BOLD}${PREFIXES[*]}${RESET}                       ${CYAN}${RESET}"
echo -e "${CYAN}  ${BRIGHT_RED}🛡️  Защищенный IP: ${BOLD}${SAVED_IP}${RESET}                                                ${CYAN}${RESET}"
echo -e "${CYAN}                                                                            ${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════${RESET}"
echo ""

# ========== ИНИЦИАЛИЗАЦИЯ ==========
echo -e "${BRIGHT_CYAN}🔧 Инициализация охоты...${RESET}"

# Загружаем переменные из project-openrc.sh
if [ -f "project-openrc.sh" ]; then
    source project-openrc.sh > /dev/null 2>&1
else
    echo -e "${YELLOW}⚠️  Файл project-openrc.sh не найден${RESET}"
fi

# Запрашиваем пароль если он не установлен
if [ -z "$OS_PASSWORD" ]; then
    echo -e "${YELLOW}🔐 Требуется аутентификация в VK Cloud${RESET}"
    echo -ne "${BRIGHT_CYAN}Введите ваш пароль: ${RESET}"
    read -s OS_PASSWORD
    echo ""
    export OS_PASSWORD
fi

# Проверка наличия openstack клиента
if ! command -v openstack &> /dev/null; then
    echo -e "${BRIGHT_RED}⛔️ ОШИБКА: OpenStack клиент не найден!${RESET}"
    exit 1
fi

# Проверка аутентификации
echo -ne "${YELLOW}🔍 Проверка аутентификации...${RESET}"
AUTH_CHECK=$(openstack token issue -f value -c expires 2>&1)
if [ $? -ne 0 ]; then
    echo -e "\n${BRIGHT_RED}⛔️ ОШИБКА: Не удалось аутентифицироваться. Проверьте пароль.${RESET}"
    exit 1
fi
echo -e " ${BRIGHT_GREEN}✅ Успешно${RESET}"

# 1. Находим ID внешней сети
echo -ne "${YELLOW}🔍 Поиск внешней сети...${RESET}"
NET_ID=$(openstack network list --external -f value -c ID | head -n 1)
if [ -z "$NET_ID" ]; then
    echo -e "\n${BRIGHT_RED}⛔️ ОШИБКА: Не найдена внешняя сеть.${RESET}"
    exit 1
fi
echo -e " ${BRIGHT_GREEN}✅ Найдена: ${BOLD}$NET_ID${RESET}"

# 2. Собираем ID подсетей по именам
echo -e "\n${BRIGHT_CYAN}🔍 Поиск целевых подсетей...${RESET}"
declare -A SUBNET_MAP
VALID_SUBNETS=()

for SUBNET_NAME in "${TARGET_SUBNETS[@]}"; do
    echo -ne "${YELLOW}  ⚡ Ищем $SUBNET_NAME...${RESET}"
    S_ID=$(openstack subnet list --name "$SUBNET_NAME" -f value -c ID)
    
    if [ ! -z "$S_ID" ]; then
        echo -e " ${BRIGHT_GREEN}✅ Найдена -> ${BOLD}$S_ID${RESET}"
        SUBNET_MAP[$SUBNET_NAME]=$S_ID
        VALID_SUBNETS+=("$S_ID")
    else
        echo -e " ${BRIGHT_RED}❌ Не найдена (пропускаем)${RESET}"
    fi
done

if [ ${#VALID_SUBNETS[@]} -eq 0 ]; then
    echo -e "\n${BRIGHT_RED}⛔️ ОШИБКА: Ни одна из указанных подсетей не найдена.${RESET}"
    echo -e "${YELLOW}Проверьте имена подсетей или регион в project-openrc.sh${RESET}"
    exit 1
fi

# ========== СТАРТ ОХОТЫ ==========
echo -e "\n${BRIGHT_GREEN}════════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${BRIGHT_YELLOW}${BOLD}                                  🚀 СТАРТ ОХОТЫ 🚀${RESET}"
echo -e "${BRIGHT_GREEN}════════════════════════════════════════════════════════════════════════════${RESET}\n"

# Заголовок таблицы
echo -e "${BOLD}${BRIGHT_CYAN}┌──────┬─────────────────┬──────────────────┬────────────────────────────┐${RESET}"
printf "${BOLD}${BRIGHT_CYAN}│${RESET} %-4s ${BOLD}${BRIGHT_CYAN}│${RESET} %-15s ${BOLD}${BRIGHT_CYAN}│${RESET} %-16s ${BOLD}${BRIGHT_CYAN}│${RESET} %-26s ${BOLD}${BRIGHT_CYAN}│${RESET}\n" "№" "IP Адрес" "Подсеть" "Статус"
echo -e "${BOLD}${BRIGHT_CYAN}├──────┼─────────────────┼──────────────────┼────────────────────────────┤${RESET}"

COUNT=0
HUNT_START_TIME=$(date +%s)

while true; do
    # Перебираем найденные подсети по кругу
    for CURRENT_SUB_ID in "${VALID_SUBNETS[@]}"; do
        ((COUNT++))
        
        # Рандомная задержка
        CURRENT_DELAY=$(( ( RANDOM % (MAX_DELAY - MIN_DELAY + 1) ) + MIN_DELAY ))

        # 3. ОЧИСТКА (кроме SAVED_IP)
        IDS_TO_DELETE=$(openstack floating ip list -f value -c ID -c "Floating IP Address" | grep -v "$SAVED_IP" | awk '{print $1}')
        if [ ! -z "$IDS_TO_DELETE" ]; then
            echo "$IDS_TO_DELETE" | xargs -r openstack floating ip delete > /dev/null 2>&1
            sleep 1
        fi

        # 4. СОЗДАНИЕ В КОНКРЕТНОЙ ПОДСЕТИ
        OUTPUT=$(openstack floating ip create "$NET_ID" --subnet "$CURRENT_SUB_ID" -f value -c floating_ip_address -c id 2>&1)
        EXIT_CODE=$?

        # Если ошибка (например, в подсети кончились IP или квота)
        if [ $EXIT_CODE -ne 0 ]; then
            CURRENT_TIME=$(date +"%H:%M:%S")
            printf "${BRIGHT_CYAN}│${RESET} %-4s ${BRIGHT_CYAN}│${RESET} %-15s ${BRIGHT_CYAN}│${RESET} %-16s ${BRIGHT_CYAN}│${RESET} %b ${BRIGHT_CYAN}│${RESET}\n" \
                "$COUNT" "ОШИБКА" "${CURRENT_SUB_ID:0:8}..." "${YELLOW}⚠️  Подсеть занята${RESET}"
            echo -e "${BRIGHT_CYAN}├──────┼─────────────────┼──────────────────┼────────────────────────────┤${RESET}"
            echo -e "${BRIGHT_BLACK}  ⏰ $CURRENT_TIME | Следующая попытка через 2с...${RESET}"
            sleep 2
            continue
        fi

        # Парсим результат
        NEW_IP=$(echo "$OUTPUT" | awk '{print $1}')
        NEW_ID=$(echo "$OUTPUT" | awk '{print $2}')
        CURRENT_TIME=$(date +"%H:%M:%S")

        if [ -z "$NEW_IP" ]; then
            # Если вдруг пусто (fallback)
            NEW_IP=$(openstack floating ip list -f value -c "Floating IP Address" | grep -v "$SAVED_IP" | head -n 1)
        fi

        SUBNET_SHORT="${CURRENT_SUB_ID:0:8}..."

        # 5. ПРОВЕРКА
        MATCH=0
        MATCHED_PREFIX=""
        for PRE in "${PREFIXES[@]}"; do
            if [[ "$NEW_IP" == "$PRE"* ]]; then
                MATCH=1
                MATCHED_PREFIX="$PRE"
                break
            fi
        done

        if [ $MATCH -eq 1 ]; then
            # БИНГО! Нашли нужный IP
            printf "${BRIGHT_CYAN}│${RESET} ${BOLD}${BRIGHT_GREEN}%-4s${RESET} ${BRIGHT_CYAN}│${RESET} ${BOLD}${BRIGHT_GREEN}%-15s${RESET} ${BRIGHT_CYAN}│${RESET} %-16s ${BRIGHT_CYAN}│${RESET} ${BOLD}${BRIGHT_GREEN}%-26s${RESET} ${BRIGHT_CYAN}│${RESET}\n" \
                "$COUNT" "$NEW_IP" "$SUBNET_SHORT" "✅ БИНГО! (${MATCHED_PREFIX}*)"
            echo -e "${BRIGHT_CYAN}└──────┴─────────────────┴──────────────────┴────────────────────────────┘${RESET}"
            
            # Красивое сообщение о победе
            echo -e "\n${BRIGHT_GREEN}════════════════════════════════════════════════════════════════════════════${RESET}"
            echo -e "${BOLD}${BRIGHT_YELLOW}🏆🏆🏆  ПОЗДРАВЛЯЮ! ЦЕЛЕВОЙ IP НАЙДЕН!  🏆🏆🏆${RESET}"
            echo -e "${BRIGHT_GREEN}════════════════════════════════════════════════════════════════════════════${RESET}"
            echo -e "${BRIGHT_CYAN}┌──────────────────────────────────────────────────────────────────────────┐${RESET}"
            printf "${BRIGHT_CYAN}│${RESET} ${BOLD}IP адрес:${RESET}     ${BRIGHT_GREEN}${BOLD}%-44s${RESET} ${BRIGHT_CYAN}│${RESET}\n" "$NEW_IP"
            printf "${BRIGHT_CYAN}│${RESET} ${BOLD}ID:${RESET}           ${BRIGHT_YELLOW}%-44s${RESET} ${BRIGHT_CYAN}│${RESET}\n" "$NEW_ID"
            printf "${BRIGHT_CYAN}│${RESET} ${BOLD}Подсеть ID:${RESET}   ${BRIGHT_PURPLE}%-44s${RESET} ${BRIGHT_CYAN}│${RESET}\n" "$CURRENT_SUB_ID"
            printf "${BRIGHT_CYAN}│${RESET} ${BOLD}Найден в:${RESET}     ${BRIGHT_BLUE}%-44s${RESET} ${BRIGHT_CYAN}│${RESET}\n" "$(date '+%Y-%m-%d %H:%M:%S')"
            printf "${BRIGHT_CYAN}│${RESET} ${BOLD}Попыток:${RESET}     ${BRIGHT_WHITE}%-44s${RESET} ${BRIGHT_CYAN}│${RESET}\n" "$COUNT"
            echo -e "${BRIGHT_CYAN}└──────────────────────────────────────────────────────────────────────────┘${RESET}"
            
            echo -e "\n${BRIGHT_BLACK}Для использования IP выполните:${RESET}"
            echo -e "${BRIGHT_GREEN}openstack floating ip set --port <PORT_ID> $NEW_IP${RESET}"
            echo -e "${BRIGHT_GREEN}openstack server add floating ip <SERVER_NAME> $NEW_IP${RESET}\n"
            
            exit 0
        else
            # Промах
            printf "${BRIGHT_CYAN}│${RESET} %-4s ${BRIGHT_CYAN}│${RESET} %-15s ${BRIGHT_CYAN}│${RESET} %-16s ${BRIGHT_CYAN}│${RESET} %-26s ${BRIGHT_CYAN}│${RESET}\n" \
                "$COUNT" "$NEW_IP" "$SUBNET_SHORT" "❌ Мимо"
            echo -e "${BRIGHT_CYAN}├──────┼─────────────────┼──────────────────┼────────────────────────────┤${RESET}"
            echo -e "${BRIGHT_BLACK}  ⏰ $CURRENT_TIME | Следующая попытка через ${CURRENT_DELAY}с...${RESET}"
        fi
        
        sleep $CURRENT_DELAY
    done
done
