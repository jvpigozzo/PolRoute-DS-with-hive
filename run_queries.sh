#!/bin/bash

set -e

CONTAINER_NAME="hive4"
TMP_SQL_DIR="/tmp"
QUERY_DIR="queries"
LOG_DIR="logs"

mkdir -p "$LOG_DIR"

run_query() {
    local mode=$1
    local query_file=$2
    local iteration=$3

    local base_name
    base_name=$(basename "$query_file")
    local tmp_query="/tmp/tmp_${base_name%.sql}_parallel_${mode}_$iteration.sql"

    echo "SET hive.exec.parallel=${mode};" > "$tmp_query"
    cat "$query_file" >> "$tmp_query"

    local container_path="${TMP_SQL_DIR}/$(basename "$tmp_query")"
    docker cp "$tmp_query" "$CONTAINER_NAME:$container_path"

    docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' -f "$container_path" \
        > "${LOG_DIR}/${base_name%.sql}_parallel_${mode}_$iteration.log" 2>&1

    rm -f "$tmp_query"
}

echo "=== Executando consultas com e sem paralelismo Hive (10 vezes) ==="
for i in {1..1}; do
    echo "--- Iteração $i ---"
    for query_file in "$QUERY_DIR"/*.sql; do
        run_query false "$query_file" "$i"
        run_query true "$query_file" "$i"
    done
done

echo "=== Consultas finalizadas ==="
echo "Logs salvos no diretório: $LOG_DIR"
