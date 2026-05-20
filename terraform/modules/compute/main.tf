resource "aws_iam_role" "ec2_role" {
  name = "starttech-ec2-role"

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

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "starttech-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# --- THIS IS THE LOAD BALANCER THAT WAS MISSING OR MISNAMED ---
resource "aws_lb" "backend_alb" {
  name               = "starttech-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}
resource "aws_lb_target_group" "backend_tg" {
  name     = "starttech-backend-tg-v6" # <-- Make sure this is v6
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    port                = "8080"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true # <-- Add this block here to break the listener lock
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "starttech-backend-"
  image_id      = "ami-04b70fa74e45c3917" # Official Ubuntu 24.04 LTS
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

network_interfaces {
    associate_public_ip_address = true 
    security_groups             = [aws_security_group.backend_sg_clean.id] 
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s2>/dev/console) 2>&1

              echo "Starting deployment..."
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              
              sudo docker run -d --name backend-app --restart always -p 8080:80 nginx
              
              sleep 7
              
              sudo docker exec backend-app mkdir -p /usr/share/nginx/html/health
              sudo docker exec backend-app sh -c 'echo "OK" > /usr/share/nginx/html/health/index.html'
              echo "Deployment script finished successfully!"
              EOF
  )
}

resource "aws_autoscaling_group" "backend_asg" {
  vpc_zone_identifier = var.public_subnet_ids 
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]

  desired_capacity = 2
  min_size         = 2
  max_size         = 5

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "starttech-backend-worker"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "backend_sg_clean" { 
  name        = "starttech-backend-sg-fresh-v7"  
  description = "Allow traffic from ALB to Backend"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on app port"
    from_port       = 8080 
    to_port         = 8080 
    protocol        = "tcp"
    security_groups = [var.alb_sg_id] 
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "starttech-backend-sg"
  }
}