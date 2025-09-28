#!/bin/bash

# Script optimizado para ejecutar en EC2 instance
# Genera métricas demo para CloudWatch

LOG_FILE="/home/ec2-user/cloudwatch-demo/demo_metrics.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "🎬 Iniciando generador de métricas DEMO en EC2..."

while true; do
    # Generar valores aleatorios realistas
    EC2_COST=$(echo "scale=2; 120 + $RANDOM % 20" | bc)
    S3_COST=$(echo "scale=2; 30 + $RANDOM % 10" | bc)
    ELB_COST=$(echo "scale=2; 15 + $RANDOM % 8" | bc)
    VPC_COST=$(echo "scale=2; 5 + $RANDOM % 5" | bc)
    
    LAMBDA_DURATION=$((1000 + $RANDOM % 2000))
    LAMBDA_INVOCATIONS=$((40 + $RANDOM % 20))
    LAMBDA_ERRORS=$((0 + $RANDOM % 5))
    
    ALB_REQUESTS=$((800 + $RANDOM % 300))
    ALB_SUCCESS=$((ALB_REQUESTS - $RANDOM % 50))
    
    RDS_CPU=$(echo "scale=1; 40 + $RANDOM % 30" | bc)
    RDS_CONNECTIONS=$((20 + $RANDOM % 15))
    
    EC2_CPU=$(echo "scale=1; 30 + $RANDOM % 25" | bc)
    EC2_NETWORK_IN=$((5000000 + $RANDOM % 3000000))
    
    log_message "📊 Enviando métricas..."
    
    # Métricas de Billing
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/Billing" --metric-data \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonEC2}],Value=$EC2_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonS3}],Value=$S3_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AWSELB}],Value=$ELB_COST,Unit=None" \
        "MetricName=EstimatedCharges,Dimensions=[{Name=Currency,Value=USD},{Name=ServiceName,Value=AmazonVPC}],Value=$VPC_COST,Unit=None" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Métricas de Lambda
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/Lambda" --metric-data \
        "MetricName=Duration,Dimensions=[{Name=FunctionName,Value=lb-alarm-correlator-dev}],Value=$LAMBDA_DURATION,Unit=Milliseconds" \
        "MetricName=Invocations,Dimensions=[{Name=FunctionName,Value=lb-alarm-correlator-dev}],Value=$LAMBDA_INVOCATIONS,Unit=Count" \
        "MetricName=Errors,Dimensions=[{Name=FunctionName,Value=lb-alarm-correlator-dev}],Value=$LAMBDA_ERRORS,Unit=Count" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Métricas de ALB
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/ApplicationELB" --metric-data \
        "MetricName=RequestCount,Dimensions=[{Name=LoadBalancer,Value=app/terraform-workshop-alb/21ac98175298729e}],Value=$ALB_REQUESTS,Unit=Count" \
        "MetricName=HTTPCode_Target_2XX_Count,Dimensions=[{Name=LoadBalancer,Value=app/terraform-workshop-alb/21ac98175298729e}],Value=$ALB_SUCCESS,Unit=Count" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Métricas de RDS
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/RDS" --metric-data \
        "MetricName=CPUUtilization,Dimensions=[{Name=DBInstanceIdentifier,Value=terraform-workshop-db}],Value=$RDS_CPU,Unit=Percent" \
        "MetricName=DatabaseConnections,Dimensions=[{Name=DBInstanceIdentifier,Value=terraform-workshop-db}],Value=$RDS_CONNECTIONS,Unit=Count" \
        2>&1 | tee -a "$LOG_FILE"
    
    # Métricas de EC2
    aws cloudwatch put-metric-data --region us-east-1 --namespace "Demo/EC2" --metric-data \
        "MetricName=CPUUtilization,Dimensions=[{Name=AutoScalingGroupName,Value=terraform-workshop-asg-mission_app}],Value=$EC2_CPU,Unit=Percent" \
        "MetricName=NetworkIn,Dimensions=[{Name=AutoScalingGroupName,Value=terraform-workshop-asg-mission_app}],Value=$EC2_NETWORK_IN,Unit=Bytes" \
        2>&1 | tee -a "$LOG_FILE"
    
    log_message "✅ Métricas enviadas - Esperando 30s"
    sleep 30
done
