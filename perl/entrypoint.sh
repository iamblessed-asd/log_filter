#!/bin/bash
set -e

until mysqladmin ping -h db --silent; do
  echo "Ожидаем MySQL..."
  sleep 2
done

echo "MySQL запущен!"

echo "Инициализация таблиц..."
export MYSQL_PWD="$MYSQL_PASSWORD"

mysql -h db -u "$MYSQL_USER" "$MYSQL_DATABASE" <<EOF
source /usr/src/app/init.sql;
EOF

# Функция для создания индекса только если его нет
create_index_if_not_exists() {
  local table="$1"
  local index="$2"
  local columns="$3"

  mysql -h db -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
    SET @exists := (SELECT COUNT(*) 
                    FROM INFORMATION_SCHEMA.STATISTICS 
                    WHERE table_schema=DATABASE() 
                      AND table_name='$table' 
                      AND index_name='$index');
    SET @sql := IF(@exists = 0, 'ALTER TABLE $table ADD INDEX $index ($columns);', 'SELECT \"Index exists\";');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  "
}

create_index_if_not_exists "message" "message_created_idx" "created"
create_index_if_not_exists "message" "message_int_id_idx" "int_id"
create_index_if_not_exists "log" "log_address_idx" "address"

#Скрипт с заполнением БД из лог файла
perl /usr/src/app/read_log.pl

exec apache2ctl -D FOREGROUND
