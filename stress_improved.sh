#!/bin/bash

# Script mejorado para stress testing con múltiples opciones
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

install_stress_tools() {
    if ! command -v stress-ng &> /dev/null; then
        log_message "📦 Instalando herramientas de stress..."
        yum install -y epel-release
        yum install -y stress-ng htop iotop
        log_message "✅ Herramientas instaladas"
    fi
}

# Stress de CPU
cpu_stress() {
    local duration=${1:-300}  # 5 minutos por defecto
    local cores=$(nproc)
    
    log_message "🔥 Iniciando stress de CPU: $cores cores por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        stress-ng --cpu $cores --timeout ${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
    else
        # Fallback con dd
        for ((i=1; i<=cores; i++)); do
            dd if=/dev/zero of=/dev/null bs=1M &
            echo $! >> "$PID_FILE"
        done
        sleep $duration
        cleanup
    fi
    
    log_message "✅ Stress de CPU completado"
}

# Stress de memoria
memory_stress() {
    local duration=${1:-300}
    local memory_mb=${2:-512}  # 512MB por defecto
    
    log_message "🧠 Iniciando stress de memoria: ${memory_mb}MB por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        stress-ng --vm 2 --vm-bytes ${memory_mb}M --timeout ${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
    else
        # Fallback básico
        dd if=/dev/zero of=/tmp/memory_test bs=1M count=$memory_mb &
        echo $! >> "$PID_FILE"
        sleep $duration
        rm -f /tmp/memory_test
        cleanup
    fi
    
    log_message "✅ Stress de memoria completado"
}

# Stress de I/O
io_stress() {
    local duration=${1:-300}
    local workers=${2:-4}
    
    log_message "💾 Iniciando stress de I/O: $workers workers por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        stress-ng --io $workers --timeout ${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
    else
        # Fallback con dd
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

# Stress combinado (CPU + Memoria + I/O)
combined_stress() {
    local duration=${1:-300}
    
    log_message "⚡ Iniciando stress combinado por $duration segundos"
    
    if command -v stress-ng &> /dev/null; then
        local cores=$(nproc)
        stress-ng --cpu $((cores/2)) --vm 2 --vm-bytes 256M --io 2 --timeout ${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
    else
        # Ejecutar todos los stress en paralelo
        cpu_stress $duration &
        memory_stress $duration 256 &
        io_stress $duration 2 &
        wait
    fi
    
    log_message "✅ Stress combinado completado"
}

# Stress aleatorio (simula carga real variable)
random_stress() {
    log_message "🎲 Iniciando stress aleatorio continuo..."
    
    while true; do
        # Seleccionar tipo de stress aleatoriamente
        stress_type=$((RANDOM % 4))
        duration=$((60 + RANDOM % 240))  # 1-4 minutos
        
        case $stress_type in
            0)
                log_message "🎯 Stress aleatorio: CPU por $duration segundos"
                cpu_stress $duration
                ;;
            1)
                log_message "🎯 Stress aleatorio: Memoria por $duration segundos"
                memory_stress $duration $((256 + RANDOM % 512))
                ;;
            2)
                log_message "🎯 Stress aleatorio: I/O por $duration segundos"
                io_stress $duration $((2 + RANDOM % 4))
                ;;
            3)
                log_message "🎯 Stress aleatorio: Combinado por $duration segundos"
                combined_stress $duration
                ;;
        esac
        
        # Pausa aleatoria entre tests
        pause=$((30 + RANDOM % 120))  # 30 segundos a 2 minutos
        log_message "⏸️ Pausa de $pause segundos..."
        sleep $pause
    done
}

# Función principal
main() {
    install_stress_tools
    
    case "${1:-help}" in
        cpu)
            cpu_stress ${2:-300}
            ;;
        memory|mem)
            memory_stress ${2:-300} ${3:-512}
            ;;
        io)
            io_stress ${2:-300} ${3:-4}
            ;;
        combined|all)
            combined_stress ${2:-300}
            ;;
        random)
            random_stress
            ;;
        stop)
            log_message "🛑 Deteniendo todos los procesos de stress..."
            cleanup
            pkill -f "stress_improved.sh"
            ;;
        status)
            if pgrep -f "stress" > /dev/null; then
                echo "✅ Procesos de stress ejecutándose:"
                pgrep -f "stress" | head -5
                echo ""
                echo "📊 Últimos logs:"
                tail -5 "$LOG_FILE" 2>/dev/null || echo "No hay logs disponibles"
            else
                echo "❌ No hay procesos de stress ejecutándose"
            fi
            ;;
        help|*)
            echo "🚀 Script de Stress Testing Mejorado"
            echo ""
            echo "Uso: $0 <comando> [duración] [parámetros]"
            echo ""
            echo "Comandos disponibles:"
            echo "  cpu [duración]              - Stress de CPU (defecto: 300s)"
            echo "  memory [duración] [MB]      - Stress de memoria (defecto: 300s, 512MB)"
            echo "  io [duración] [workers]     - Stress de I/O (defecto: 300s, 4 workers)"
            echo "  combined [duración]         - Stress combinado (defecto: 300s)"
            echo "  random                      - Stress aleatorio continuo"
            echo "  stop                        - Detener todos los procesos"
            echo "  status                      - Ver estado actual"
            echo ""
            echo "Ejemplos:"
            echo "  $0 cpu 600                 # CPU stress por 10 minutos"
            echo "  $0 memory 300 1024         # Memoria stress 1GB por 5 minutos"
            echo "  $0 combined 180             # Stress combinado por 3 minutos"
            echo "  $0 random                   # Stress aleatorio continuo"
            ;;
    esac
}

trap cleanup EXIT INT TERM
main "$@"
