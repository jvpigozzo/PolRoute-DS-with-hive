#!/bin/bash

LOG_DIR="logs"
RESULTS_DIR="results"
SUMMARY_FILE="$RESULTS_DIR/resumo_consultas.txt"

mkdir -p "$RESULTS_DIR"

echo "Consulta;Paralelismo;Iteração;Tempo(s)" > "$SUMMARY_FILE"

for log in "$LOG_DIR"/q*.log; do
    [ -e "$log" ] || continue

    filename=$(basename "$log" .log)

    if [[ "$filename" == *"parallel_false"* ]]; then
        paralelismo="Não"
    elif [[ "$filename" == *"parallel_true"* ]]; then
        paralelismo="Sim"
    else
        paralelismo="Indefinido"
    fi

    # Extrai tempo do log com "row(s) selected"
    tempo=$(grep -Eo 'rows? selected \([0-9.]+ seconds\)' "$log" | \
            grep -Eo '[0-9.]+' | tail -n 1)
    if [ -z "$tempo" ]; then
        tempo="N/A"
    fi

    iteracao=$(echo "$filename" | grep -oE '_[0-9]+$' | tr -d '_')
    if [ -z "$iteracao" ]; then
        iteracao="N/A"
    fi

    echo "$filename;$paralelismo;$iteracao;$tempo" >> "$SUMMARY_FILE"
done

echo "Resumo salvo em $SUMMARY_FILE"
