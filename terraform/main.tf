terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source = "./modules/networking"
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnets   
  private_subnet_ids = module.networking.private_subnets  
  alb_sg_id          = module.networking.alb_sg_id
}

module "monitoring" {
  source = "./modules/monitoring"
}

module "storage" {
  source             = "./modules/storage"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnets  
  backend_sg_id      = module.compute.backend_sg_id 
}
# --- Redis Security Group ---
resource "aws_security_group" "redis_sg" {
  name        = "starttech-redis-sg-final"
  description = "Allow port 6379 from backend worker nodes"
  vpc_id      = module.networking.vpc_id # Pulls from your networking module

  ingress {
    description     = "Redis traffic from Backend workers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.compute.backend_sg_id] # Restricts access strictly to backend workers
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Redis Subnet Group ---
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "starttech-redis-subnets"
  subnet_ids = module.networking.private_subnet_ids # Keeps Redis safe in private lanes
}

# --- Redis Cluster Resource (Rubric Requirement) ---
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
}