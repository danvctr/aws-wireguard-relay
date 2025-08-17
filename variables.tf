# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Change to your preferred region
}

variable "key_name" {
  description = "The name of your AWS EC2 key pair for SSH access."
  type        = string
  default = "wireguard-relay"
}

# variable "my_ip" {
#   description = "Your public IP address to restrict SSH access. IMPORTANT for security."
#   type        = string
#   # To find your IP, you can google "what is my ip"
# }