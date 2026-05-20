output "alb_sg_id" {
  value       = aws_security_group.alb_sg.id
  description = "The ID of the security group for the Application Load Balancer"
}