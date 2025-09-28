#!/bin/bash

LOG_FILE="/var/log/stress_test.log"
PID_FILE="/tmp/stress_test.pid"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log_message "🧹 Limpiando procesos de stress..."
    if [ -f "$PID_FILE" ]; then
        while read pid; do
            kill -9 "$pid" 2>/dev/null
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    pkill -f "stress-ng" 2>/dev/null
    pkill -f "dd if=/dev/zero" 2>/dev/null
    log_message "✅ Limpieza completada"
}

cpu_stress() {
    local duration=$${1:-300}
    local cores=$(nproc)
    
    log_message "🔥 Iniciando stress de CPU: $cores cores por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        stress-ng --cpu $cores --timeout $${duration}s --metrics-brief
    else
        > "$PID_FILE"
        for ((i=1; i<=cores; i++)); do
            dd if=/dev/zero of=/dev/null bs=1M &
            echo $! >> "$PID_FILE"
        done
        sleep $duration
        cleanup
    fi
    
    log_message "✅ Stress de CPU completado"
}

memory_stress() {
    local duration=$${1:-300}
    local memory_mb=$${2:-512}
    
    log_message "🧠 Iniciando stress de memoria: $${memory_mb}MB por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        stress-ng --vm 2 --vm-bytes $${memory_mb}M --timeout $${duration}s --metrics-brief
    else
        dd if=/dev/zero of=/tmp/memory_test bs=1M count=$memory_mb &
        echo $! >> "$PID_FILE"
        sleep $duration
        rm -f /tmp/memory_test
        cleanup
    fi
    
    log_message "✅ Stress de memoria completado"
}

io_stress() {
    local duration=$${1:-300}
    local workers=$${2:-4}
    
    log_message "💾 Iniciando stress de I/O: $workers workers por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        stress-ng --io $workers --timeout $${duration}s --metrics-brief
    else
        > "$PID_FILE"
        for ((i=1; i<=workers; i++)); do
            dd if=/dev/zero of=/tmp/io_test_$i bs=1M count=100 oflag=direct &
            echo $! >> "$PID_FILE"
        done
        sleep $duration
        rm -f /tmp/io_test_*
        cleanup
    fi
    
    log_message "✅ Stress de I/O completado"
}

combined_stress() {
    local duration=$${1:-300}
    
    log_message "⚡ Iniciando stress combinado por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        local cores=$(nproc)
        stress-ng --cpu $((cores/2)) --vm 2 --vm-bytes 256M --io 2 --timeout $${duration}s --metrics-brief
    else
        cpu_stress $duration &
        memory_stress $duration 256 &
        io_stress $duration 2 &
        wait
    fi
    
    log_message "✅ Stress combinado completado"
}

random_stress() {
    log_message "🎲 Iniciando stress aleatorio continuo..."
    
    while true; do
        stress_type=$((RANDOM % 4))
        duration=$((60 + RANDOM % 240))
        
        case $stress_type in
            0) log_message "🎯 Stress aleatorio: CPU por $duration segundos"; cpu_stress $duration ;;
            1) log_message "🎯 Stress aleatorio: Memoria por $duration segundos"; memory_stress $duration $((256 + RANDOM % 512)) ;;
            2) log_message "🎯 Stress aleatorio: I/O por $duration segundos"; io_stress $duration $((2 + RANDOM % 4)) ;;
            3) log_message "🎯 Stress aleatorio: Combinado por $duration segundos"; combined_stress $duration ;;
        esac
        
        pause=$((30 + RANDOM % 120))
        log_message "⏸️ Pausa de $pause segundos..."
        sleep $pause
    done
}

case "$${1:-help}" in
    cpu) cpu_stress $${2:-300} ;;
    memory|mem) memory_stress $${2:-300} $${3:-512} ;;
    io) io_stress $${2:-300} $${3:-4} ;;
    combined|all) combined_stress $${2:-300} ;;
    random) random_stress ;;
    stop) log_message "🛑 Deteniendo stress..."; cleanup; pkill -f "stress.sh" ;;
    status)
        if pgrep -f "stress" > /dev/null; then
            echo "✅ Procesos de stress ejecutándose"
            tail -5 "$LOG_FILE" 2>/dev/null || echo "No hay logs disponibles"
        else
            echo "❌ No hay procesos de stress ejecutándose"
        fi
        ;;
    *)
        echo "🚀 Script de Stress Testing"
        echo "Uso: $0 <comando> [duración] [parámetros]"
        echo "Comandos: cpu, memory, io, combined, random, stop, status"
        ;;
esac

trap cleanup EXIT INT TERM
