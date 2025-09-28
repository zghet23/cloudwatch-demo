# 🚀 CloudWatch Demo - Terraform

Esta demo demuestra las capacidades clave de Amazon CloudWatch siguiendo la presentación de Julio Granados.

## 📋 Componentes de la Demo

### 🎯 Infraestructura
- **VPC** con subnet pública en México Central (mx-central-1)
- **EC2 Instance** (t3.micro) con nginx
- **Security Groups** para HTTP y SSH
- **IAM Roles** para CloudWatch

### 📊 CloudWatch Components
- **Métricas**: CPU, Network In/Out
- **Alarmas**: CPU > 70%, Network traffic
- **Log Groups**: Nginx logs, Application logs
- **Dashboard**: Vista unificada de métricas y logs
- **Insights**: Búsquedas de errores HTTP 500

## 🚀 Despliegue

### 1. Prerrequisitos
```bash
# Instalar Terraform
brew install terraform  # macOS
# o descargar desde https://terraform.io

# Configurar AWS CLI
aws configure
# Asegúrate de tener permisos para mx-central-1
```

### 2. Configurar Variables
```bash
# Editar variables.tf o crear terraform.tfvars
echo 'notification_email = "tu-email@ejemplo.com"' > terraform.tfvars
```

### 3. Desplegar Infraestructura
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

## 🎭 Ejecutar la Demo

### 1. Acceder al Servidor
```bash
# Opción 1: Usar AWS Console
# Ve a EC2 → Instances → Seleccionar instancia → Connect → Session Manager

# Opción 2: AWS CLI
aws ssm start-session --target <INSTANCE_ID> --region mx-central-1
```

### 2. Scripts de Demo Disponibles

#### 🌐 Tráfico Normal
```bash
sudo /opt/demo-scripts/generate_traffic.sh
```

#### 🔥 Generar Errores HTTP 500
```bash
sudo /opt/demo-scripts/generate_errors.sh
```

#### ⚡ Carga de CPU (Activar Alarmas)
```bash
sudo /opt/demo-scripts/generate_cpu_load.sh
```

#### 🎯 Demo Completa
```bash
sudo /opt/demo-scripts/full_demo.sh
```

### 3. Endpoints Web
- **Página Principal**: `http://<IP>/`
- **Error 500**: `http://<IP>/error500`
- **CPU Load**: `http://<IP>/cpu-load`

## 📊 Monitoreo en CloudWatch

### 1. Dashboard
Accede al dashboard desde el output `dashboard_url` o:
```
CloudWatch Console → Dashboards → CloudWatch-Demo-Dashboard
```

### 2. Métricas Clave
- **CPUUtilization**: Monitorea uso de CPU
- **NetworkIn/NetworkOut**: Tráfico de red
- **Custom Metrics**: Métricas de aplicación

### 3. Alarmas
- **High CPU**: Se activa cuando CPU > 70%
- **High Network**: Se activa con tráfico alto

### 4. Log Insights Queries

#### Buscar Errores HTTP 500
```sql
fields @timestamp, @message
| filter @message like /500/
| sort @timestamp desc
| limit 20
```

#### Buscar Errores de Aplicación
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

#### Análisis de Tráfico
```sql
fields @timestamp, @message
| stats count() by bin(5m)
| sort @timestamp desc
```

## 🎪 Flujo de la Demo

### 1. Introducción (5 min)
- Mostrar la infraestructura desplegada
- Explicar los componentes de CloudWatch

### 2. Métricas en Tiempo Real (10 min)
- Abrir el dashboard
- Ejecutar `generate_traffic.sh`
- Mostrar métricas de CPU y red en tiempo real

### 3. Alarmas (10 min)
- Ejecutar `generate_cpu_load.sh`
- Mostrar cómo se activa la alarma de CPU > 70%
- Explicar las notificaciones SNS

### 4. Logs e Insights (10 min)
- Ejecutar `generate_errors.sh`
- Usar CloudWatch Insights para buscar errores HTTP 500
- Demostrar queries personalizadas

### 5. Dashboard Unificado (5 min)
- Mostrar la vista completa en el dashboard
- Explicar cómo correlacionar métricas y logs

## 🔧 Personalización

### Modificar Umbrales de Alarmas
Edita `cloudwatch.tf`:
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  threshold = "80"  # Cambiar de 70 a 80
  # ...
}
```

### Agregar Métricas Personalizadas
```bash
# En el servidor EC2
aws cloudwatch put-metric-data \
  --region mx-central-1 \
  --namespace "Demo/Application" \
  --metric-data MetricName=CustomMetric,Value=100
```

## 🧹 Limpieza

```bash
terraform destroy
```

## 📚 Recursos Adicionales

- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [CloudWatch Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [CloudWatch Metrics](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html)

## 🎯 Key Takeaways

1. **Observabilidad Proactiva**: Las alarmas detectan problemas antes que los usuarios
2. **Correlación de Datos**: Dashboard unifica métricas y logs
3. **Insights Poderosos**: Búsquedas complejas en logs con SQL-like syntax
4. **Automatización**: Respuestas automáticas a eventos críticos

---

**"Observability is not just monitoring, it's a business enabler"** 🚀
