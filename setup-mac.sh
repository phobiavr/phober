#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure dialog is available (macOS does not ship whiptail)
if ! command -v dialog &> /dev/null; then
    if command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing dialog via Homebrew...${NC}"
        brew install dialog
    else
        echo -e "${RED}dialog not found and Homebrew is not installed.${NC}"
        echo -e "Install Homebrew from https://brew.sh, then run: brew install dialog"
        exit 1
    fi
fi

# macOS-compatible spinner: /proc does not exist on macOS
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinner='|/-\'

    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\r%s " "${spinner:$i:1}"
            sleep $delay
        done
    done
    printf "\r"
}

# Function to run migration or seeding commands for services
run_command() {
    local service_name=$1
    local command=$2
    local action=$3

    echo -e "Running ${action} for ${YELLOW}${service_name}${NC}..."
    docker-compose exec ${service_name} php artisan ${command} 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${service_name} ${action} completed successfully.${NC}"
    else
        echo -e "${RED}${service_name} ${action} failed.${NC}"
    fi
    echo -e "${CYAN}----------------------------------------${NC}"
}

# Combined MySQL and SQL Server Initialization
initialize_databases() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    echo -e "${YELLOW}Executing MySQL SQL files...${NC}"
    local mysql_ok=1
    for sql_file in \
            "$script_dir/docker/mysql/00-init-db.sql" \
            "$script_dir/docker/mysql/10-structure.sql" \
            "$script_dir/docker/mysql/20-data.sql"; do
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

    echo -e "${YELLOW}Executing SQL Server SQL files...${NC}"
    local sqlsrv_ok=1
    for sql_file in \
            "$script_dir/docker/sqlsrv/00-init-db.sql" \
            "$script_dir/docker/sqlsrv/10-structure.sql" \
            "$script_dir/docker/sqlsrv/20-data.sql"; do
        [ -f "$sql_file" ] || continue
        echo -e "  Running ${CYAN}$(basename "$sql_file")${NC}..."
        out=$(docker exec -i db_mssql bash -c "cat > /tmp/_init.sql && /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P '${MSSQL_SA_PASSWORD:-Password1*}' -C -i /tmp/_init.sql" < "$sql_file" 2>&1)
        if [ $? -ne 0 ]; then
            sqlsrv_ok=0
            echo -e "${RED}  $(basename "$sql_file") failed.${NC}"
            echo "$out"
        fi
    done
    if [ $sqlsrv_ok -eq 1 ]; then
        echo -e "${GREEN}SQL Server initialization completed successfully.${NC}"
    else
        echo -e "${RED}SQL Server initialization failed.${NC}"
    fi
    echo -e "${CYAN}----------------------------------------${NC}"
}

# Show a checkbox menu to select tasks (dialog instead of whiptail)
selected=$(dialog --title "Select Tasks to Run" --checklist \
"Choose the tasks you want to execute:" 20 78 10 \
"1" "Database Initialization (MySQL & SQL Server)" ON \
"2" "Initialize Applications and Copy .env" ON \
"3" "Run Config Updates" ON \
"4" "Run Storage Link" ON \
"5" "Run Migrations" ON \
"6" "Run Hostname updates" ON \
"7" "Run Seeders" OFF 3>&1 1>&2 2>&3)

exitcode=$?
if [ $exitcode -ne 0 ]; then
    echo -e "${RED}Cancelled.${NC}"
    exit 0
fi

if [ -z "$selected" ]; then
    echo -e "${YELLOW}No tasks selected. Exiting.${NC}"
    exit 0
fi

# Strip quotes from dialog output (dialog outputs: 1 2 3, whiptail outputs: "1" "2" "3")
selected=$(echo "$selected" | tr -d '"')

# Check which steps were selected by the user
for task in $selected; do
    case $task in
        "1")
            initialize_databases
            ;;
        "2")
            echo -e "${CYAN}Initializing applications and copying .env files...${NC}"
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
                    if ! docker exec -i "$container_name" bash -c "test -f /var/www/html/.env"; then
                        if docker exec -i "$container_name" bash -c "test -f /var/www/html/.env.example"; then
                            docker exec -i "$container_name" bash -c "cp /var/www/html/.env.example /var/www/html/.env"
                            echo -e "Copied .env for ${YELLOW}$app_name${NC}"
                        else
                            echo -e "${RED}.env.example not found for ${YELLOW}$app_name${NC}"
                        fi
                    fi
                    echo -e "Initializing ${YELLOW}$app_name${NC}..."
                    docker exec -i "$container_name" bash -c "cd /var/www/html && composer install" > /dev/null 2>&1 &
                    show_spinner $!
                    app_end_time=$(date +%s)
                    app_total_time=$((app_end_time - app_start_time))
                    if [ $? -eq 0 ]; then
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
        "3")
            config_clients=(
                "notification-server"
                "auth-server"
                "device-service"
                "crm-service"
                "staff-service"
            )
            for service in "${config_clients[@]}"; do
                run_command $service "config-client:update" "config update"
            done
            ;;
        "4")
            storage_services=(
                "adminpanel"
                "device-service"
            )
            for service in "${storage_services[@]}"; do
                run_command $service "storage:link" "storage link creation"
            done
            ;;
        "5")
            migration_services=(
                "adminpanel"
                "auth-server"
                "notification-server"
            )
            for service in "${migration_services[@]}"; do
                run_command $service "migrate" "migration"
            done
            ;;
        "6")
            hostname_services=(
                "auth-server"
                "notification-server"
                "device-service"
                "crm-service"
                "config-server"
                "staff-service"
            )
            for service in "${hostname_services[@]}"; do
                run_command $service "hostname:update $service" "hostname update"
            done
            ;;
        "7")
            run_command "adminpanel" "db:seed" "seeding"
            ;;
    esac
done

echo -e "${GREEN}All selected operations completed.${NC}"
