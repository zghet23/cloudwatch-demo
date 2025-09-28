#!/bin/bash

echo "🎬 Iniciando generador de métricas para DEMO con estado de alarmas..."
echo "⏰ Generando métricas cada 30 segundos..."
echo "🛑 Presiona Ctrl+C para detener"

while true; do
    # Generar valores aleatorios realistas
    EC2_COST=$(echo "scale=2; 120 + $RANDOM % 20" | bc)
    S3_COST=$(echo "scale=2; 30 + $RANDOM % 10" | bc)
    ELB_COST=$(echo "scale=2; 15 + $RANDOM % 8" | bc)
    VPC_COST=$(echo "scale=2; 5 + $RANDOM % 5" | bc)
    RDS_COST=$(echo "scale=2; 25 + $RANDOM % 15" | bc)
    
    LAMBDA_DURATION=$((1000 + $RANDOM % 2000))
    LAMBDA_INVOCATIONS=$((40 + $RANDOM % 20))
    LAMBDA_ERRORS=$((0 + $RANDOM % 5))
    
    ALB_REQUESTS=$((800 + $RANDOM % 300))
    ALB_SUCCESS=$((ALB_REQUESTS - $RANDOM % 50))
    ALB_5XX_ERRORS=$((0 + $RANDOM % 10))
    
    RDS_CPU=$(echo "scale=1; 40 + $RANDOM % 30" | bc)
    RDS_CONNECTIONS=$((20 + $RANDOM % 15))
    RDS_ERRORS=$((0 + $RANDOM % 3))
    
    EC2_CPU=$(echo "scale=1; 30 + $RANDOM % 25" | bc)
    EC2_NETWORK_IN=$((5000000 + $RANDOM % 3000000))
    
    # Calcular estado de alarmas dinámicamente
    COST_ALARM=0
    DEV_ALARMS=0
    DB_ALARMS=0
    
    # Verificar umbrales de alarmas
    if (( $(echo "$EC2_COST > 130" | bc -l) )); then
        COST_ALARM=1
    fi
    
    if (( LAMBDA_ERRORS > 30 )); then
        DEV_ALARMS=$((DEV_ALARMS + 1))
    fi
    
    if (( LAMBDA_DURATION > 2500 )); then
        DEV_ALARMS=$((DEV_ALARMS + 1))
    fi
    
    if (( ALB_5XX_ERRORS > 50 )); then
        DEV_ALARMS=$((DEV_ALARMS + 1))
    fi
    
    if (( $(echo "$RDS_CPU > 60" | bc -l) )); then
        DB_ALARMS=1
    fi
    
    TOTAL_ACTIVE_ALARMS=$((COST_ALARM + DEV_ALARMS + DB_ALARMS))
    
    echo "📊 $(date '+%H:%M:%S') - Generando métricas y estado de alarmas..."
    echo "🚨 Alarmas activas: $TOTAL_ACTIVE_ALARMS/5 (Costo:$COST_ALARM, Dev:$DEV_ALARMS, DB:$DB_ALARMS)"
    
    # Métricas de Billing
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/Billing" --metric-data \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonEC2}],Value=$EC2_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonS3}],Value=$S3_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AWSELB}],Value=$ELB_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonVPC}],Value=$VPC_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonRDS}],Value=$RDS_COST,Unit=None"
    
    # Métricas de Lambda
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/Lambda" --metric-data \
        "MetricName=Duration,Dimensions=[{Name=FunctionName,Value=lb-alarm-correlator-dev}],Value=$LAMBDA_DURATION,Unit=Milliseconds" \
        "MetricName=Invocations,Dimensions=[{Name=FunctionName,Value=lb-alarm-correlator-dev}],Value=$LAMBDA_INVOCATIONS,Unit=Count" \
        "MetricName=Errors,Dimensions=[{Name=FunctionName,Value=lb-alarm-correlator-dev}],Value=$LAMBDA_ERRORS,Unit=Count"
    
    # Métricas de ALB
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/ApplicationELB" --metric-data \
        "MetricName=RequestCount,Dimensions=[{Name=LoadBalancer,Value=app/testing-replication/87b3e0a53332fa27}],Value=$ALB_REQUESTS,Unit=Count" \
        "MetricName=HTTPCode_Target_2XX_Count,Dimensions=[{Name=LoadBalancer,Value=app/testing-replication/87b3e0a53332fa27}],Value=$ALB_SUCCESS,Unit=Count" \
        "MetricName=HTTPCode_Target_5XX_Count,Dimensions=[{Name=LoadBalancer,Value=app/testing-replication/87b3e0a53332fa27}],Value=$ALB_5XX_ERRORS,Unit=Count"
    
    # Métricas de RDS
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/RDS" --metric-data \
        "MetricName=CPUUtilization,Dimensions=[{Name=DBInstanceIdentifier,Value=terraform-workshop-db}],Value=$RDS_CPU,Unit=Percent" \
        "MetricName=DatabaseConnections,Dimensions=[{Name=DBInstanceIdentifier,Value=terraform-workshop-db}],Value=$RDS_CONNECTIONS,Unit=Count" \
        "MetricName=DatabaseErrors,Dimensions=[{Name=DBInstanceIdentifier,Value=terraform-workshop-db}],Value=$RDS_ERRORS,Unit=Count"
    
    # Métricas de EC2
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/EC2" --metric-data \
        "MetricName=CPUUtilization,Dimensions=[{Name=AutoScalingGroupName,Value=terraform-workshop-asg-mission_app}],Value=$EC2_CPU,Unit=Percent" \
        "MetricName=NetworkIn,Dimensions=[{Name=AutoScalingGroupName,Value=terraform-workshop-asg-mission_app}],Value=$EC2_NETWORK_IN,Unit=Bytes"
    
    # Métricas de Estado de Alarmas (NUEVO)
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/Alarms" --metric-data \
        "MetricName=TotalAlarms,Value=5,Unit=Count" \
        "MetricName=ActiveAlarms,Value=$TOTAL_ACTIVE_ALARMS,Unit=Count" \
        "MetricName=CostAlarms,Value=$COST_ALARM,Unit=Count" \
        "MetricName=DevAlarms,Value=$DEV_ALARMS,Unit=Count" \
        "MetricName=DatabaseAlarms,Value=$DB_ALARMS,Unit=Count"
    
    echo "✅ Métricas enviadas - Próxima actualización en 30s"
    sleep 30
done
