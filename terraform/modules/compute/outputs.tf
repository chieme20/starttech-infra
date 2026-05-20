output "alb_dns_name" {
  value = aws_lb.backend_alb.dns_name
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg_clean.id
}