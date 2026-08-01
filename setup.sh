#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# MySQL Initialization
initialize_databases() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    echo -e "${YELLOW}Executing MySQL SQL files...${NC}"
    local mysql_ok=1
    for sql_file in \
            "$script_dir/docker/mysql/init-db.sql"; do
        [ -f "$sql_file" ] || continue
        echo -e "  Running ${CYAN}$(basename "$sql_file")${NC}..."
        out=$(docker exec -i db_mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-root}" < "$sql_file" 2>&1)
        if [ $? -ne 0 ]; then
            mysql_ok=0
            echo -e "${RED}  $(basename "$sql_file") failed.${NC}"
            echo "$out"
        fi
    done
    if [ $mysql_ok -eq 1 ]; then
        echo -e "${GREEN}MySQL initialization completed successfully.${NC}"
    else
        echo -e "${RED}MySQL initialization failed.${NC}"
    fi
    echo -e "${CYAN}----------------------------------------${NC}"
}

# Show a checkbox menu to select tasks
selected=$(whiptail --title "Select Tasks to Run" --checklist \
"Choose the tasks you want to execute:" 20 78 10 \
"1" "Database Initialization (MySQL)" ON \
"2" "Initialize Applications" ON 3>&1 1>&2 2>&3)

# Check which steps were selected by the user
for task in $selected; do
    case $task in
        "\"1\"")
            # Combined MySQL and SQL Server Initialization
            initialize_databases
            ;;
        "\"2\"")
            # Initialize Applications
            echo -e "${CYAN}Initializing applications...${NC}"
            applications=(
                "adminpanel"
                "config-server"
                "device-service"
                "crm-service"
                "notification-server"
                "auth-server"
                "staff-service"
            )
            for app_name in "${applications[@]}"; do
                container_name="$app_name"
                app_start_time=$(date +%s)
                if docker ps --format '{{.Names}}' | grep -q "$container_name"; then
                    echo -e "Initializing ${YELLOW}$app_name${NC}..."
                    docker exec -i "$container_name" bash -c "cd /var/www/html && composer install && composer update"
                    composer_exit=$?
                    app_end_time=$(date +%s)
                    app_total_time=$((app_end_time - app_start_time))
                    if [ $composer_exit -eq 0 ]; then
                        echo -e "${YELLOW}$app_name ${GREEN}initialized successfully in ${CYAN}$app_total_time${GREEN} seconds.${NC}"
                    else
                        echo -e "${YELLOW}$app_name ${RED}failed to initialize in ${CYAN}$app_total_time${RED} seconds.${NC}"
                    fi
                else
                    echo -e "${RED}Error: No such container: ${YELLOW}$container_name${NC}"
                fi
                echo -e "${CYAN}----------------------------------------${NC}"
            done
            ;;
    esac
done

# Finished
echo -e "${GREEN}All selected operations completed.${NC}"
