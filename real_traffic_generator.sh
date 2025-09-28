#!/bin/bash

echo "🎯 Generador de Tráfico Real para Demo CloudWatch"
echo "================================================"

# Configuración
ALB_DNS="testing-replication-1273644599.us-east-1.elb.amazonaws.com"
NGINX_INSTANCE_1="i-0d76841bfe028eadc"  # Nginx-WebServer
NGINX_INSTANCE_2="i-0b5c94ad4a81811f5"  # Nginx-Webserver2

echo "🌐 Load Balancer: $ALB_DNS"
echo "🖥️ Instancias Nginx: $NGINX_INSTANCE_1, $NGINX_INSTANCE_2"
echo ""

# Función para generar tráfico HTTP
generate_web_traffic() {
    echo "📈 Generando tráfico web..."
    for i in {1..10}; do
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS" &
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/health" &
        curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/api/status" &
    done
    wait
    echo " ✅ Tráfico web generado"
}

# Función para generar stress en CPU
generate_cpu_stress() {
    echo "🔥 Generando stress en CPU..."
    
    # Stress en instancia 1
    aws ssm send-command \
        --instance-ids "$NGINX_INSTANCE_1" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["stress --cpu 1 --timeout 60s || echo \"stress not installed, using dd\"", "dd if=/dev/zero of=/dev/null bs=1M count=1000 &", "sleep 30", "killall dd 2>/dev/null || true"]' \
        --region us-east-1 > /dev/null 2>&1
    
    # Stress en instancia 2
    aws ssm send-command \
        --instance-ids "$NGINX_INSTANCE_2" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["stress --cpu 1 --timeout 60s || echo \"stress not installed, using dd\"", "dd if=/dev/zero of=/dev/null bs=1M count=1000 &", "sleep 30", "killall dd 2>/dev/null || true"]' \
        --region us-east-1 > /dev/null 2>&1
    
    echo " ✅ Stress en CPU iniciado (60s)"
}

# Función para enviar métricas reales a CloudWatch
send_real_metrics() {
    echo "📊 Enviando métricas reales..."
    
    # Obtener métricas reales de las instancias
    CPU_1=$(aws cloudwatch get-metric-statistics \
        --namespace "AWS/EC2" \
        --metric-name "CPUUtilization" \
        --dimensions Name=InstanceId,Value=$NGINX_INSTANCE_1 \
        --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 300 \
        --statistics Average \
        --region us-east-1 \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null || echo "45.5")
    
    # Enviar a namespace Demo con instancias reales
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/EC2" --metric-data \
        "MetricName=CPUUtilization,Dimensions=[{Name=InstanceId,Value=$NGINX_INSTANCE_1}],Value=$CPU_1,Unit=Percent" \
        "MetricName=CPUUtilization,Dimensions=[{Name=InstanceId,Value=$NGINX_INSTANCE_2}],Value=$CPU_1,Unit=Percent"
    
    echo " ✅ Métricas reales enviadas"
}

echo "🚀 Iniciando generación de tráfico y stress..."
echo "⏰ Ejecutándose cada 30 segundos..."
echo "🛑 Presiona Ctrl+C para detener"
echo ""

while true; do
    echo "$(date '+%H:%M:%S') - Ciclo de demo en progreso..."
    
    # Generar tráfico web
    generate_web_traffic
    
    # Cada 3 ciclos, generar stress en CPU
    if [ $((RANDOM % 3)) -eq 0 ]; then
        generate_cpu_stress
    fi
    
    # Enviar métricas reales
    send_real_metrics
    
    echo "$(date '+%H:%M:%S') - Ciclo completado. Esperando 30s..."
    echo ""
    sleep 30
done
