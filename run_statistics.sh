#!/bin/bash

# Diretórios
LOG_DIR="logs"
RESULTS_DIR="results"
SUMMARY_FILE="$RESULTS_DIR/resumo_consultas.txt"
STATS_FILE="$RESULTS_DIR/estatisticas.txt"

# Cria diretório de resultados se não existir
mkdir -p "$RESULTS_DIR"

# Função de log com timestamp
log_with_time() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Extrai tempos dos arquivos de log e salva no resumo
extract_hive_times() {
    log_with_time "Extraindo tempos dos logs Hive..."
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

        tempo=$(grep -Eo 'rows? selected \([0-9.]+ seconds\)' "$log" | grep -Eo '[0-9.]+' | tail -n 1)
        if [ -z "$tempo" ]; then
            tempo="N/A"
        fi

        iteracao=$(echo "$filename" | grep -oE '_[0-9]+$' | tr -d '_')
        if [ -z "$iteracao" ]; then
            iteracao="N/A"
        fi

        echo "$filename;$paralelismo;$iteracao;$tempo" >> "$SUMMARY_FILE"
    done

    log_with_time "Resumo salvo em $SUMMARY_FILE"
}

# Calcula estatísticas a partir do resumo
calculate_statistics() {
    log_with_time "Calculando estatísticas..."

    if [[ ! -f "$SUMMARY_FILE" ]]; then
        echo "ERRO: Arquivo $SUMMARY_FILE não encontrado!"
        return 1
    fi

    {
        echo "=== ESTATÍSTICAS DETALHADAS ==="
        echo "Data: $(date)"
        echo ""

        tail -n +2 "$SUMMARY_FILE" | awk -F';' '
        $4 != "N/A" && $4 != "" {
            query = $1
            sub(/_parallel_(true|false)_[0-9]+$/, "", query)
            time = $4 + 0
            if ($2 == "Não") {
                seq_sum[query] += time
                seq_count[query]++
                if ((query in seq_min) == 0 || time < seq_min[query]) seq_min[query] = time
                if ((query in seq_max) == 0 || time > seq_max[query]) seq_max[query] = time
            } else if ($2 == "Sim") {
                par_sum[query] += time
                par_count[query]++
                if ((query in par_min) == 0 || time < par_min[query]) par_min[query] = time
                if ((query in par_max) == 0 || time > par_max[query]) par_max[query] = time
            }
        }
        END {
            printf "%-25s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s | %-8s\n", 
                   "Query", "Seq.Avg", "Par.Avg", "Seq.Min", "Seq.Max", "Par.Min", "Par.Max", "Speedup";
            printf "%-25s-+-%-8s-+-%-8s-+-%-8s-+-%-8s-+-%-8s-+-%-8s-+-%-8s\n", 
                   "-------------------------", "--------", "--------", "--------", "--------", "--------", "--------", "--------";
            
            for (query in seq_sum) {
                if (query in par_sum) {
                    seq_avg = seq_sum[query] / seq_count[query]
                    par_avg = par_sum[query] / par_count[query]
                    speedup = seq_avg / par_avg
                    printf "%-25s | %7.3fs | %7.3fs | %7.3fs | %7.3fs | %7.3fs | %7.3fs | %6.2fx\n",
                           query, seq_avg, par_avg,
                           seq_min[query], seq_max[query],
                           par_min[query], par_max[query],
                           speedup
                }
            }
        }'

        echo ""
        echo "=== RESUMO GERAL ==="

        tail -n +2 "$SUMMARY_FILE" | awk -F';' '
        $4 != "N/A" && $4 != "" {
            query = $1
            sub(/_parallel_(true|false)_[0-9]+$/, "", query)
            time = $4 + 0
            if ($2 == "Não") {
                seq_sum[query] += time
                seq_count[query]++
            } else if ($2 == "Sim") {
                par_sum[query] += time
                par_count[query]++
            }
        }
        END {
            total_speedup = 0
            valid_queries = 0
            for (query in seq_sum) {
                if (query in par_sum) {
                    seq_avg = seq_sum[query] / seq_count[query]
                    par_avg = par_sum[query] / par_count[query]
                    speedup = seq_avg / par_avg
                    total_speedup += speedup
                    valid_queries++
                }
            }
            if (valid_queries > 0) {
                avg_speedup = total_speedup / valid_queries
                printf "Speedup médio: %.2fx\n", avg_speedup
                printf "Queries analisadas: %d\n", valid_queries
                if (avg_speedup > 1.2) {
                    print "Resultado: Paralelização EFETIVA"
                } else if (avg_speedup > 0.8) {
                    print "Resultado: Paralelização NEUTRA"
                } else {
                    print "Resultado: Paralelização PREJUDICIAL"
                }
            }
        }'

    } > "$STATS_FILE"

    log_with_time "Estatísticas salvas em: $STATS_FILE"
}

# Executar etapas
extract_hive_times
calculate_statistics
