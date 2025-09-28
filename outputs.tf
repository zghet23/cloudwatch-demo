output "instance_id" {
  description = "Instance ID for Session Manager connection"
  value       = aws_instance.demo_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the demo instance"
  value       = aws_instance.demo_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the demo instance"
  value       = aws_instance.demo_instance.public_dns
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://mx-central-1.console.aws.amazon.com/cloudwatch/home?region=mx-central-1#dashboards:name=${aws_cloudwatch_dashboard.demo_dashboard.dashboard_name}"
}

output "log_groups" {
  description = "CloudWatch Log Groups created"
  value = {
    nginx_logs       = aws_cloudwatch_log_group.nginx_logs.name
    application_logs = aws_cloudwatch_log_group.application_logs.name
  }
}

output "demo_commands" {
  description = "Commands to run the demo"
  value = {
    session_manager_url   = "https://mx-central-1.console.aws.amazon.com/systems-manager/session-manager/${aws_instance.demo_instance.id}?region=mx-central-1"
    generate_traffic      = "sudo /opt/demo-scripts/generate_traffic.sh"
    generate_errors       = "sudo /opt/demo-scripts/generate_errors.sh"
    generate_cpu_load     = "sudo /opt/demo-scripts/generate_cpu_load.sh"
    full_demo            = "sudo /opt/demo-scripts/full_demo.sh"
  }
}

output "web_endpoints" {
  description = "Web endpoints for testing"
  value = {
    main_page    = "http://${aws_instance.demo_instance.public_ip}/"
    error_500    = "http://${aws_instance.demo_instance.public_ip}/error500"
    cpu_load     = "http://${aws_instance.demo_instance.public_ip}/cpu-load"
  }
}

output "cloudwatch_insights_queries" {
  description = "Sample CloudWatch Insights queries"
  value = {
    http_500_errors = "fields @timestamp, @message | filter @message like /500/ | sort @timestamp desc | limit 20"
    app_errors      = "fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
    traffic_analysis = "fields @timestamp, @message | stats count() by bin(5m) | sort @timestamp desc"
  }
}
