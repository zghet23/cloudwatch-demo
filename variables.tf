variable "notification_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "zghet23@gmail.com"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "mx-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0bd21cfdc15e64494"  # Amazon Linux 2023 with kernel 6.12 (mx-central-1)
}
