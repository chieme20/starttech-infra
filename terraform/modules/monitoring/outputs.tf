output "ec2_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_profile.name
  description = "The name of the IAM instance profile for EC2 logging"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.backend_log_group.name
  description = "The name of the CloudWatch log group"
}