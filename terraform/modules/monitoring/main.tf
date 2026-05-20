resource "aws_cloudwatch_log_group" "backend_log_group" {
  name              = "/aws/ec2/starttech-backend-apps"
  retention_in_days = 7 # Keeps logs for 7 days to manage costs

  tags = {
    Environment = "production"
    Application = "starttech-backend"
  }
}

resource "aws_iam_role" "ec2_monitoring_role" {
  name = "starttech-ec2-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "starttech-ec2-instance-profile"
  role = aws_iam_role.ec2_monitoring_role.name
}