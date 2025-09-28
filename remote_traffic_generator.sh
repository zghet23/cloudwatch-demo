#!/bin/bash

# Script optimizado para generar tráfico real desde EC2
LOG_FILE="/home/ec2-user/cloudwatch-demo/traffic.log"
ALB_DNS="testing-replication-1273644599.us-east-1.elb.amazonaws.com"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "🎯 Iniciando generador de tráfico real desde EC2..."

# Función para generar tráfico HTTP
generate_web_traffic() {
    log_message "📈 Generando tráfico web..."
    for i in {1..5}; do
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS" >> "$LOG_FILE" 2>&1 &
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/health" >> "$LOG_FILE" 2>&1 &
    done
    wait
    log_message "✅ Tráfico web generado"
}

# Función para generar stress en CPU local
generate_cpu_stress() {
    log_message "🔥 Generando stress en CPU local..."
    # Usar dd para generar carga CPU
    dd if=/dev/zero of=/dev/null bs=1M count=500 2>/dev/null &
    DD_PID=$!
    sleep 30
    kill $DD_PID 2>/dev/null || true
    log_message "✅ Stress en CPU completado"
}

while true; do
    log_message "$(date '+%H:%M:%S') - Ciclo de tráfico iniciado..."
    
    # Generar tráfico web
    generate_web_traffic
    
    # Cada 4 ciclos, generar stress en CPU
    if [ $((RANDOM % 4)) -eq 0 ]; then
        generate_cpu_stress
    fi
    
    log_message "$(date '+%H:%M:%S') - Ciclo completado. Esperando 45s..."
    sleep 45
done
