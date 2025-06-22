#!/bin/bash

set -e  # Exit immediately on error

echo "=== Loading CSVs into Apache Hive ==="

# Constants
CSV_FILES=("crime.csv" "district.csv" "neighborhood.csv" "segment.csv" "time.csv" "vertice.csv")
CONTAINER_NAME="hive4"
DATA_DIR="data"
TMP_SQL_DIR="/tmp"

# Step 1: Check for data folder
echo "1. Checking if data folder exists..."
if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: '$DATA_DIR' folder not found!"
    exit 1
fi

# Step 2: Remove headers
echo "2. Removing headers from CSVs..."
for file in "${CSV_FILES[@]}"; do
    input_file="${DATA_DIR}/${file}"
    output_file="${DATA_DIR}/${file%.*}_no_header.csv"

    if [ ! -f "$input_file" ]; then
        echo "ERROR: File $input_file not found!"
        exit 1
    fi

    tail -n +2 "$input_file" > "$output_file"
    echo "Processed $input_file -> $output_file"
done

# Step 3: Copy CSVs to container
echo "3. Copying CSVs to container..."
for file in "${CSV_FILES[@]}"; do
    no_header_file="${DATA_DIR}/${file%.*}_no_header.csv"
    container_dest="${TMP_SQL_DIR}/${file%.*}.csv"

    docker cp "$no_header_file" "$CONTAINER_NAME:$container_dest"
    echo "Copied $no_header_file to $container_dest in container"
done

# Step 4: Create tables
echo "4. Creating schema and tables in Hive..."
if [ ! -f "create_tables.sql" ]; then
    echo "ERROR: create_tables.sql not found!"
    exit 1
fi

docker cp create_tables.sql "$CONTAINER_NAME:${TMP_SQL_DIR}/create_tables.sql"

echo "Executing table creation script..."
docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' -f "${TMP_SQL_DIR}/create_tables.sql"

# Step 5: Load data
echo "5. Loading data into tables..."
if [ ! -f "load_data.sql" ]; then
    echo "ERROR: load_data.sql not found!"
    exit 1
fi

docker cp load_data.sql "$CONTAINER_NAME:${TMP_SQL_DIR}/load_data.sql"
docker exec -i "$CONTAINER_NAME" beeline -u 'jdbc:hive2://localhost:10000/' -f "${TMP_SQL_DIR}/load_data.sql"

# Step 6: Cleanup
echo "6. Cleaning up temporary files..."
for file in "${CSV_FILES[@]}"; do
    rm -f "${DATA_DIR}/${file%.*}_no_header.csv"
    echo "Deleted ${DATA_DIR}/${file%.*}_no_header.csv"
done

echo "=== Process completed! ==="
echo "Hive Web UI: http://localhost:10002/"
echo "Beeline CLI: docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'"
