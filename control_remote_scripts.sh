#!/bin/bash

# Script para controlar el generador CloudWatch Demo en EC2
INSTANCE_ID="i-0d76841bfe028eadc"

case "$1" in
    "start")
        echo "🚀 Iniciando CloudWatch Demo script en EC2..."
        aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["cd /home/ec2-user/cloudwatch-demo","su - ec2-user -c \"cd /home/ec2-user/cloudwatch-demo && nohup ./complete_demo.sh > complete_demo.log 2>&1 &\"","echo \"CloudWatch Demo script iniciado\"","sleep 2","ps aux | grep complete_demo | grep -v grep"]' \
            --region us-east-1
        ;;
    "stop")
        echo "🛑 Deteniendo CloudWatch Demo script en EC2..."
        aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["pkill -f complete_demo.sh","echo \"CloudWatch Demo script detenido\""]' \
            --region us-east-1
        ;;
    "status")
        echo "📊 Verificando estado del CloudWatch Demo script..."
        aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["cd /home/ec2-user/cloudwatch-demo","echo \"=== PROCESO ACTIVO ===\"","ps aux | grep complete_demo | grep -v grep || echo \"No hay proceso activo\"","echo \"","echo \"=== ARCHIVOS ===\"","ls -la complete_demo.sh complete_demo.log 2>/dev/null","echo \"","echo \"=== ÚLTIMAS LÍNEAS DEL LOG ===\"","tail -10 complete_demo.log 2>/dev/null || echo \"No hay log\""]' \
            --region us-east-1
        ;;
    "logs")
        echo "📋 Obteniendo logs del CloudWatch Demo..."
        aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["cd /home/ec2-user/cloudwatch-demo","echo \"=== COMPLETE DEMO LOG (últimas 30 líneas) ===\"","tail -30 complete_demo.log 2>/dev/null || echo \"No hay log\""]' \
            --region us-east-1
        ;;
    "restart")
        echo "🔄 Reiniciando CloudWatch Demo script..."
        aws ssm send-command \
            --instance-ids "$INSTANCE_ID" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["pkill -f complete_demo.sh","sleep 2","cd /home/ec2-user/cloudwatch-demo","su - ec2-user -c \"cd /home/ec2-user/cloudwatch-demo && nohup ./complete_demo.sh > complete_demo.log 2>&1 &\"","echo \"CloudWatch Demo script reiniciado\"","sleep 2","ps aux | grep complete_demo | grep -v grep"]' \
            --region us-east-1
        ;;
    *)
        echo "🎛️ Control CloudWatch Demo Script"
        echo "=================================="
        echo ""
        echo "Uso: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Comandos:"
        echo "  start   - Iniciar script en background"
        echo "  stop    - Detener script"
        echo "  restart - Reiniciar script"
        echo "  status  - Ver estado del proceso"
        echo "  logs    - Ver logs del script"
        echo ""
        echo "Script: complete_demo.sh"
        echo "Instancia: $INSTANCE_ID (Nginx-WebServer)"
        echo "Log: complete_demo.log"
        ;;
esac
