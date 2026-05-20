resource "aws_security_group" "redis_sg" {
  name        = "starttech-redis-sg"
  description = "Allow Redis traffic from backend instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.backend_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "starttech-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "starttech-redis"
  replication_group_description = "Redis cluster for StartTech caching"
  node_type                     = "cache.t2.micro" # Free-tier / low cost friendly
  num_cache_clusters            = 1
  parameter_group_name          = "default.redis7"
  port                          = 6379
  security_group_ids            = [aws_security_group.redis_sg.id]
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnets.name
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = false

  tags = {
    Name = "starttech-redis-cluster"
  }
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}