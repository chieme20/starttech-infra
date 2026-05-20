variable "vpc_id" {
  type        = string
  description = "The VPC ID passed from the networking module"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the Redis cluster"
}

variable "backend_sg_id" {
  type        = string
  description = "The Security Group ID of the backend app tier to allow access"
}