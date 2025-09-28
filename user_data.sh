#!/bin/bash
yum update -y

# Install nginx, CloudWatch agent and stress tools
yum install -y nginx amazon-cloudwatch-agent epel-release
yum install -y stress-ng htop iotop

# Configure nginx
systemctl start nginx
systemctl enable nginx

# Create custom nginx config with detailed logging
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        root /usr/share/nginx/html;

        location / {
            index index.html index.htm;
        }

        # Endpoint que genera errores 500 para la demo
        location /error500 {
            return 500 "Internal Server Error for Demo";
        }

        # Endpoint que consume CPU para la demo
        location /cpu-load {
            return 200 "CPU Load Test Endpoint";
        }

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
}
EOF

# Create custom index page
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>CloudWatch Demo Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .endpoint { background: #f4f4f4; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .button { background: #007cba; color: white; padding: 10px 20px; text-decoration: none; border-radius: 3px; display: inline-block; margin: 5px; }
        .stress { background: #ff6b6b; }
        .normal { background: #51cf66; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CloudWatch Demo Server</h1>
        <p>Este servidor está configurado para demostrar las capacidades de Amazon CloudWatch.</p>
        
        <h2>Endpoints de Prueba:</h2>
        
        <div class="endpoint">
            <h3>🔥 Generar Error 500</h3>
            <p>Genera errores HTTP 500 para demostrar CloudWatch Logs Insights</p>
            <a href="/error500" class="button">Generar Error 500</a>
        </div>
        
        <div class="endpoint">
            <h3>⚡ Test de Carga CPU</h3>
            <p>Endpoint para generar carga de CPU y activar alarmas</p>
            <a href="/cpu-load" class="button">Test CPU</a>
        </div>
        
        <h2>🎯 Scripts de Stress Testing:</h2>
        <div class="endpoint">
            <h3>Comandos disponibles via SSH:</h3>
            <code>
            /opt/demo-scripts/stress.sh cpu 600<br>
            /opt/demo-scripts/stress.sh memory 300 1024<br>
            /opt/demo-scripts/stress.sh combined 180<br>
            /opt/demo-scripts/stress.sh random<br>
            /opt/demo-scripts/stress.sh status<br>
            /opt/demo-scripts/stress.sh stop
            </code>
        </div>
        
        <h2>📊 Métricas Monitoreadas:</h2>
        <ul>
            <li><strong>CPU Utilization</strong> - Alarma cuando > 70%</li>
            <li><strong>Memory Usage</strong> - Monitoreo de RAM</li>
            <li><strong>Disk I/O</strong> - Operaciones de disco</li>
            <li><strong>Network In/Out</strong> - Monitoreo de tráfico de red</li>
            <li><strong>HTTP 500 Errors</strong> - Búsqueda en logs con Insights</li>
            <li><strong>Application Errors</strong> - Logs de aplicación</li>
        </ul>
    </div>
</body>
</html>
EOF

# Restart nginx
systemctl restart nginx

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "nginx-access-{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "nginx-error-{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/application.log",
            "log_group_name": "/aws/ec2/application",
            "log_stream_name": "application-{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/stress_test.log",
            "log_group_name": "/aws/ec2/stress",
            "log_stream_name": "stress-{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create application log file and add some sample entries
touch /var/log/application.log
chown nginx:nginx /var/log/application.log

# Add sample application logs
cat >> /var/log/application.log << EOF
$(date '+%Y-%m-%d %H:%M:%S') INFO Application started successfully
$(date '+%Y-%m-%d %H:%M:%S') INFO Database connection established
$(date '+%Y-%m-%d %H:%M:%S') WARN High memory usage detected
EOF

# Create demo scripts directory
mkdir -p /opt/demo-scripts

# Script para generar tráfico normal
cat > /opt/demo-scripts/generate_traffic.sh << 'EOF'
#!/bin/bash
echo "🚀 Generando tráfico normal al servidor..."
for i in {1..100}; do
    curl -s http://localhost/ > /dev/null
    curl -s http://localhost/cpu-load > /dev/null
    sleep 0.1
done
echo "✅ Tráfico normal completado"
EOF

# Script para generar errores 500
cat > /opt/demo-scripts/generate_errors.sh << 'EOF'
#!/bin/bash
echo "🔥 Generando errores HTTP 500..."
for i in {1..20}; do
    curl -s http://localhost/error500 > /dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR HTTP 500 generated for demo purposes" >> /var/log/application.log
    sleep 0.5
done
echo "✅ Errores 500 generados"
EOF

# Script mejorado de stress testing
cat > /opt/demo-scripts/stress.sh << 'EOF'
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
        stress-ng --cpu $cores --timeout $${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
    else
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
        stress-ng --vm 2 --vm-bytes $${memory_mb}M --timeout $${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
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
        stress-ng --io $workers --timeout $${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
    else
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
        stress-ng --cpu $((cores/2)) --vm 2 --vm-bytes 256M --io 2 --timeout $${duration}s --metrics-brief &
        echo $! >> "$PID_FILE"
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
EOF

# Script combinado para demo completa
cat > /opt/demo-scripts/full_demo.sh << 'EOF'
#!/bin/bash
echo "🎯 Iniciando demo completa de CloudWatch..."

echo "1️⃣ Generando tráfico normal..."
/opt/demo-scripts/generate_traffic.sh

sleep 10

echo "2️⃣ Generando errores HTTP 500..."
/opt/demo-scripts/generate_errors.sh

sleep 10

echo "3️⃣ Generando stress combinado por 3 minutos..."
/opt/demo-scripts/stress.sh combined 180

echo "🎉 Demo completa finalizada!"
EOF

# Make scripts executable
chmod +x /opt/demo-scripts/*.sh

# Create a simple cron job to generate some background traffic
echo "*/5 * * * * /opt/demo-scripts/generate_traffic.sh" | crontab -

echo "✅ CloudWatch Demo Server configurado exitosamente!"
echo "Scripts disponibles en /opt/demo-scripts/"


# Conectarse via Session Manager y ejecutar:
# sudo /opt/demo-scripts/stress.sh cpu 600        # CPU por 10 min
# sudo /opt/demo-scripts/stress.sh memory 300 1024  # 1GB RAM por 5 min
# sudo /opt/demo-scripts/stress.sh combined 180     # Todo por 3 min
# sudo /opt/demo-scripts/stress.sh random           # Aleatorio continuo
# sudo /opt/demo-scripts/stress.sh status           # Ver estado
# sudo /opt/demo-scripts/stress.sh stop             # Detener todo