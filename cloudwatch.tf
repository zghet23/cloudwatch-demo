# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/aws/ec2/nginx"
  retention_in_days = 7
  
  tags = {
    Name        = "cloudwatch-demo-nginx-logs"
    auto-delete = "no"
  }
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/ec2/application"
  retention_in_days = 7
  
  tags = {
    Name        = "cloudwatch-demo-app-logs"
    auto-delete = "no"
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch-demo-alerts"
  
  tags = {
    Name        = "cloudwatch-demo-alerts"
    auto-delete = "no"
  }
}

resource "aws_sns_topic_subscription" "email_notification" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "cloudwatch-demo-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.demo_instance.id
  }
  
  tags = {
    Name        = "cloudwatch-demo-high-cpu-alarm"
    auto-delete = "no"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_network_in" {
  alarm_name          = "cloudwatch-demo-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1000000"  # 1MB
  alarm_description   = "This metric monitors ec2 network in"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.demo_instance.id
  }
  
  tags = {
    Name        = "cloudwatch-demo-high-network-alarm"
    auto-delete = "no"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "demo_dashboard" {
  dashboard_name = "CloudWatch-Demo-Dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.demo_instance.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "mx-central-1"
          title   = "CPU Utilization (%)"
          period  = 60
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.demo_instance.id],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "mx-central-1"
          title   = "Network Traffic (Bytes)"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.nginx_logs.name}'\n| fields @timestamp, @message\n| filter @message like /500/\n| sort @timestamp desc\n| limit 20"
          region  = "mx-central-1"
          title   = "HTTP 500 Errors"
          view    = "table"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.application_logs.name}'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
          region  = "mx-central-1"
          title   = "Application Errors"
          view    = "table"
        }
      }
    ]
  })
}
