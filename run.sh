#!/bin/bash

set -e

# Configurações globais
CONTAINER_NAME="hive4"
HIVE_VERSION="4.0.1"
CSV_FILES=("crime.csv" "district.csv" "neighborhood.csv" "segment.csv" "time.csv" "vertice.csv")
DATA_DIR="data"
SQL_DIR="src"
QUERY_DIR="queries"
LOG_DIR="logs"
RESULTS_DIR="results"
TMP_SQL_DIR="/tmp"

# Configurações de performance
CPUS="10.0"
MEMORY="8g"
PARALLEL_THREADS=12
PARALLEL_REDUCES=12

# Função para logging com timestamp
log_with_time() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Função para verificar dependências
check_dependencies() {
    log_with_time "Verificando dependências..."
    
    if ! command -v docker &> /dev/null; then
        echo "ERRO: Docker não encontrado!"
        exit 1
    fi
    
    local required_dirs=("$DATA_DIR" "$SQL_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "ERRO: Diretório '$dir' não encontrado!"
            exit 1
        fi
    done
    
    for file in "${CSV_FILES[@]}"; do
        if [[ ! -f "${DATA_DIR}/${file}" ]]; then
            echo "ERRO: Arquivo ${DATA_DIR}/${file} não encontrado!"
            exit 1
        fi
    done
    
    if [[ ! -f "${SQL_DIR}/create_tables.sql" ]]; then
        echo "ERRO: Arquivo ${SQL_DIR}/create_tables.sql não encontrado!"
        exit 1
    fi
    
    if [[ ! -f "${SQL_DIR}/load_data.sql" ]]; then
        echo "ERRO: Arquivo ${SQL_DIR}/load_data.sql não encontrado!"
        exit 1
    fi
    
    log_with_time "Dependências verificadas com sucesso!"
}

# Função para configurar container Hive
setup_container() {
    log_with_time "=== Configurando container Hive ==="
    
    if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_with_time "Removendo container existente..."
        docker rm -f "$CONTAINER_NAME"
    fi
    
    log_with_time "Criando container com $CPUS CPUs e $MEMORY de RAM..."
    docker run -d \
        -p 10000:10000 \
        -p 10002:10002 \
        --cpus="$CPUS" \
        --memory="$MEMORY" \
        --env SERVICE_NAME=hiveserver2 \
        --name "$CONTAINER_NAME" \
        apache/hive:$HIVE_VERSION
    
    log_with_time "Aguardando container inicializar..."
    sleep 30
    
    if ! docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "ERRO: Container não está rodando!"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
    
    log_with_time "Container configurado com sucesso!"
    log_with_time "Interface Web: http://localhost:10002/"
}

# Função para carregar dados
load_data() {
    log_with_time "=== Carregando dados no Hive ==="
    
    log_with_time "Removendo cabeçalhos dos CSVs..."
    for file in "${CSV_FILES[@]}"; do
        input_file="${DATA_DIR}/${file}"
        output_file="${DATA_DIR}/${file%.*}_no_header.csv"
        tail -n +2 "$input_file" > "$output_file"
        log_with_time "Processado: $file"
    done
    
    log_with_time "Copiando CSVs para container..."
    for file in "${CSV_FILES[@]}"; do
        no_header_file="${DATA_DIR}/${file%.*}_no_header.csv"
        container_dest="${TMP_SQL_DIR}/${file%.*}.csv"
        docker cp "$no_header_file" "$CONTAINER_NAME:$container_dest"
    done
    
    log_with_time "Criando esquema e tabelas..."
    docker cp "${SQL_DIR}/create_tables.sql" "$CONTAINER_NAME:${TMP_SQL_DIR}/create_tables.sql"
    docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' \
        -f "${TMP_SQL_DIR}/create_tables.sql"
    
    log_with_time "Carregando dados nas tabelas..."
    docker cp "${SQL_DIR}/load_data.sql" "$CONTAINER_NAME:${TMP_SQL_DIR}/load_data.sql"
    docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' \
        -f "${TMP_SQL_DIR}/load_data.sql"
    
    log_with_time "Limpando arquivos temporários..."
    for file in "${CSV_FILES[@]}"; do
        rm -f "${DATA_DIR}/${file%.*}_no_header.csv"
    done
    
    log_with_time "Dados carregados com sucesso!"
}

# Função para executar query individual
run_query() {
    local mode=$1
    local query_file=$2
    local iteration=$3

    local base_name
    base_name=$(basename "$query_file")
    local tmp_query="/tmp/tmp_${base_name%.sql}_parallel_${mode}_$iteration.sql"

    {
        echo "-- Configurações de paralelismo: $mode"
        echo "SET hive.exec.parallel=${mode};"
        if [[ "$mode" == "true" ]]; then
            echo "SET hive.exec.parallel.thread.number=${PARALLEL_THREADS};"
            echo "SET mapreduce.job.reduces=${PARALLEL_REDUCES};"
            echo "SET hive.vectorized.execution.enabled=true;"
            echo "SET mapreduce.input.fileinputformat.split.maxsize=67108864;"
        fi
        echo ""
        cat "$query_file"
    } > "$tmp_query"

    local container_path="${TMP_SQL_DIR}/$(basename "$tmp_query")"
    docker cp "$tmp_query" "$CONTAINER_NAME:$container_path"

    local log_file="${LOG_DIR}/${base_name%.sql}_parallel_${mode}_$iteration.log"
    
    log_with_time "Executando: $base_name (parallel=$mode, iteração=$iteration)"
    docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' -f "$container_path" > "$log_file" 2>&1
    log_with_time "Query executada: $base_name"
    
    rm -f "$tmp_query"
    sleep 2
}

# Função para executar benchmark
run_benchmark() {
    log_with_time "=== Iniciando benchmark de performance ==="
    
    mkdir -p "$LOG_DIR" "$RESULTS_DIR"
    
    if [[ ! -d "$QUERY_DIR" ]]; then
        echo "ERRO: Diretório $QUERY_DIR não encontrado!"
        exit 1
    fi
    
    if ! ls "$QUERY_DIR"/*.sql >/dev/null 2>&1; then
        echo "ERRO: Nenhum arquivo .sql encontrado em $QUERY_DIR"
        exit 1
    fi
    
    local total_queries
    total_queries=$(ls "$QUERY_DIR"/*.sql | wc -l)
    log_with_time "Encontradas $total_queries queries para testar"
    
    for i in {1..1}; do
        log_with_time "--- Iteração $i ---"
        for query_file in "$QUERY_DIR"/*.sql; do
            if [[ -f "$query_file" ]]; then
                run_query false "$query_file" "$i"
                run_query true "$query_file" "$i"
            fi
        done
    done

    log_with_time "=== Benchmark finalizado ==="
}

# Função principal
main() {
    local action=${1:-"all"}
    
    case $action in
        "setup")
            check_dependencies
            setup_container
            ;;
        "load")
            load_data
            ;;
        "benchmark")
            run_benchmark
            ;;
        "all")
            log_with_time "=== INICIANDO SETUP COMPLETO DO HIVE ==="
            check_dependencies
            setup_container
            load_data
            run_benchmark
            log_with_time "=== SETUP COMPLETO FINALIZADO ==="
            log_with_time "Interface Web: http://localhost:10002/"
            log_with_time "Beeline CLI: docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'"
            ;;
        *)
            echo "Uso: $0 [setup|load|benchmark|all]"
            echo "  setup     - Apenas configura o container"
            echo "  load      - Apenas carrega os dados"
            echo "  benchmark - Apenas executa o benchmark"
            echo "  all       - Executa tudo (padrão)"
            exit 1
            ;;
    esac
}

# Executar
main "$@"
