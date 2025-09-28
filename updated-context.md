# 📊 Contexto Actualizado - CloudWatch Demo

## 🎯 **Estado Actual de Dashboards DEMO:**

### 📋 **Dashboards Disponibles (6 total):**

1. **🎯 DEMO-Executive-Summary** 
   - **Última modificación:** 2025-09-24T04:36:43+00:00
   - **Contenido:** KPIs ejecutivos con costos EC2, S3, RDS, ELB
   - **Métricas:** Lambda invocations, ALB requests, DB connections, errores
   - **Período:** 60 segundos (actualización cada minuto)

2. **💰 DEMO-Dashboard-Finanzas**
   - **Última modificación:** 2025-09-24T04:37:24+00:00
   - **Tamaño:** 6032 bytes (dashboard más grande)
   - **Enfoque:** Análisis financiero y billing

3. **👨‍💻 DEMO-Dashboard-Desarrollo**
   - **Última modificación:** 2025-09-24T04:37:47+00:00
   - **Tamaño:** 3596 bytes
   - **Enfoque:** Métricas de aplicaciones y desarrollo

4. **🏢 DEMO-Dashboard-Arquitectura**
   - **Última modificación:** 2025-09-24T04:38:13+00:00
   - **Tamaño:** 3467 bytes
   - **Enfoque:** Vista de infraestructura

5. **🗄️ DEMO-Dashboard-Database** (NUEVO)
   - **Última modificación:** 2025-09-24T04:38:40+00:00
   - **Contenido:** Monitoreo específico de RDS
   - **Métricas:** CPU, conexiones, errores de DB
   - **KPIs:** CPU actual, conexiones activas, errores totales, costo RDS

6. **🚨 DEMO-Dashboard-Alerts** (NUEVO)
   - **Última modificación:** 2025-09-24T04:39:05+00:00
   - **Contenido:** Dashboard de alertas y notificaciones
   - **Email:** zghet23@gmail.com
   - **SNS Topic:** CloudWatch-Demo-Alerts
   - **Alertas configuradas:**
     - 💰 High Monthly Costs (EC2 > $130)
     - ⚠️ Lambda High Errors (> 3 errors/min)
     - 🚨 ALB 5XX Errors (> 5 errors/min)
     - 🗄️ RDS High CPU (> 60% for 10min)
     - 🐌 Lambda High Duration (> 2500ms for 10min)

## 🖥️ **Instancia EC2 para Generación de Métricas:**

- **Instance ID:** i-0d76841bfe028eadc
- **Tipo:** t2.micro
- **Estado:** running
- **Nombre:** Nginx-WebServer
- **IP Privada:** 10.170.17.45
- **Zona:** us-east-1a
- **Directorio del script:** `/home/ec2-user/cloudwatch-demo`
- **IAM Role:** AmazonSSMRoleForInstancesQuickSetup (permite CloudWatch)

## 📈 **Métricas Actualizadas:**

### **Namespaces en uso:**
- `Demo/Billing` - Costos estimados por servicio
- `Demo/Lambda` - Métricas de funciones Lambda
- `Demo/ApplicationELB` - Load Balancer con nuevo target: `app/testing-replication/87b3e0a53332fa27`
- `Demo/RDS` - Base de datos con nueva métrica: `DatabaseErrors`
- `Demo/EC2` - Instancias y Auto Scaling

### **Nuevas métricas detectadas:**
- **RDS DatabaseErrors:** Errores de base de datos
- **ALB HTTPCode_Target_5XX_Count:** Errores 5XX del ALB
- **Nuevo Load Balancer:** `app/testing-replication/87b3e0a53332fa27`

## 🔔 **Sistema de Alertas:**

### **Configuración de notificaciones:**
- **Email destino:** zghet23@gmail.com
- **Tópico SNS:** CloudWatch-Demo-Alerts
- **Frecuencia:** Tiempo real (1 minuto)
- **Estado:** Configurado y monitoreando

### **Umbrales de alertas:**
1. **Costos EC2:** > $130 USD
2. **Errores Lambda:** > 3 por minuto
3. **Errores ALB 5XX:** > 5 por minuto
4. **CPU RDS:** > 60% por 10 minutos
5. **Duración Lambda:** > 2500ms por 10 minutos

## 🎬 **Flujo de Presentación Actualizado:**

1. **🎯 Executive Summary** (3 min) - Vista general con KPIs
2. **🚨 Alerts Dashboard** (4 min) - Sistema de alertas y notificaciones
3. **💰 Finanzas** (4 min) - Análisis de costos
4. **🗄️ Database** (4 min) - Monitoreo específico de RDS
5. **👨‍💻 Desarrollo** (4 min) - Métricas de aplicaciones
6. **🏢 Arquitectura** (4 min) - Vista de infraestructura
7. **Q&A** (2 min)

**Duración total:** 25 minutos

## 🔧 **Comandos para verificar el script en EC2:**

```bash
# Conectar a la instancia (si tienes acceso SSH)
ssh -i nht-lab1.pem ec2-user@10.170.17.45

# O usar Session Manager
aws ssm start-session --target i-0d76841bfe028eadc --region us-east-1

# Verificar el directorio del script
ls -la /home/ec2-user/cloudwatch-demo/

# Verificar si el script está corriendo
ps aux | grep cloudwatch
```

## 📊 **URLs Actualizadas:**

1. https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=DEMO-Executive-Summary
2. https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=DEMO-Dashboard-Alerts
3. https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=DEMO-Dashboard-Finanzas
4. https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=DEMO-Dashboard-Database
5. https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=DEMO-Dashboard-Desarrollo
6. https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=DEMO-Dashboard-Arquitectura

## ⚠️ **Notas importantes:**

- Los dashboards tienen períodos de 60 segundos (más frecuente que antes)
- Hay un nuevo Load Balancer target en las métricas
- Se agregaron métricas de errores de base de datos
- El sistema de alertas está completamente configurado
- La instancia EC2 está corriendo el script desde `/home/ec2-user/cloudwatch-demo`
