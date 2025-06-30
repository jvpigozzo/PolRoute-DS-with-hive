#!/bin/bash

set -e

echo "=== Carregando arquivos CSV no Apache Hive ==="

CSV_FILES=("crime.csv" "district.csv" "neighborhood.csv" "segment.csv" "time.csv" "vertice.csv")
CONTAINER_NAME="hive4"
DATA_DIR="data"
TMP_SQL_DIR="/tmp"
SQL_DIR="src"

echo "1. Verificando se a pasta de dados existe..."
if [ ! -d "$DATA_DIR" ]; then
    echo "ERRO: Pasta '$DATA_DIR' não encontrada!"
    exit 1
fi

echo "2. Removendo cabeçalhos dos arquivos CSV..."
for file in "${CSV_FILES[@]}"; do
    input_file="${DATA_DIR}/${file}"
    output_file="${DATA_DIR}/${file%.*}_no_header.csv"

    if [ ! -f "$input_file" ]; then
        echo "ERRO: Arquivo $input_file não encontrado!"
        exit 1
    fi

    tail -n +2 "$input_file" > "$output_file"
    echo "Processado $input_file -> $output_file"
done

echo "3. Copiando os arquivos CSV para o container..."
for file in "${CSV_FILES[@]}"; do
    no_header_file="${DATA_DIR}/${file%.*}_no_header.csv"
    container_dest="${TMP_SQL_DIR}/${file%.*}.csv"

    docker cp "$no_header_file" "$CONTAINER_NAME:$container_dest"
    echo "Copiado $no_header_file para $container_dest no container"
done

echo "4. Criando esquema e tabelas no Hive..."
CREATE_SQL="${SQL_DIR}/create_tables.sql"
if [ ! -f "$CREATE_SQL" ]; then
    echo "ERRO: Arquivo $CREATE_SQL não encontrado!"
    exit 1
fi

docker cp "$CREATE_SQL" "$CONTAINER_NAME:${TMP_SQL_DIR}/create_tables.sql"

echo "Executando o script de criação das tabelas..."
docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' -f "${TMP_SQL_DIR}/create_tables.sql"

echo "5. Carregando dados nas tabelas..."
LOAD_SQL="${SQL_DIR}/load_data.sql"
if [ ! -f "$LOAD_SQL" ]; then
    echo "ERRO: Arquivo $LOAD_SQL não encontrado!"
    exit 1
fi

docker cp "$LOAD_SQL" "$CONTAINER_NAME:${TMP_SQL_DIR}/load_data.sql"
docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' -f "${TMP_SQL_DIR}/load_data.sql"

echo "6. Limpando arquivos temporários..."
for file in "${CSV_FILES[@]}"; do
    rm -f "${DATA_DIR}/${file%.*}_no_header.csv"
    echo "Removido ${DATA_DIR}/${file%.*}_no_header.csv"
done

echo "=== Processo concluído! ==="
echo "Interface Web do Hive: http://localhost:10002/"
echo "Beeline CLI: docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'"
