# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider to use the specified region
provider "aws" {
  region = var.aws_region
}

# --- VPC and Networking ---
resource "aws_vpc" "wg_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "WireGuard-VPC"
  }
}

resource "aws_subnet" "wg_subnet" {
  vpc_id     = aws_vpc.wg_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true # Assign public IPs to instances in this subnet
  tags = {
    Name = "WireGuard-Subnet"
  }
}

resource "aws_internet_gateway" "wg_gw" {
  vpc_id = aws_vpc.wg_vpc.id
  tags = {
    Name = "WireGuard-GW"
  }
}

resource "aws_route_table" "wg_rt" {
  vpc_id = aws_vpc.wg_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wg_gw.id
  }
  tags = {
    Name = "WireGuard-RouteTable"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.wg_subnet.id
  route_table_id = aws_route_table.wg_rt.id
}

# --- Security Group (Firewall) ---
resource "aws_security_group" "wg_sg" {
  name        = "wireguard-sg"
  description = "Allow WireGuard and SSH traffic"
  vpc_id      = aws_vpc.wg_vpc.id

  # Allow SSH access ONLY from your IP
  # Would be nice, but I'm literally behind a CGNAT so can't do this...
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    #cidr_blocks = ["${var.my_ip}/32"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow WireGuard traffic from anywhere
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WireGuard-SG"
  }
}

# --- EC2 Instance ---
# Find the latest Ubuntu 22.04 AMI automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical's owner ID
}

# Create the EC2 instance
resource "aws_instance" "wg_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small" # Free Tier eligible
  key_name      = var.key_name
  subnet_id     = aws_subnet.wg_subnet.id

  # Run the install script on first boot
  user_data = file("install_wireguard.sh")

  tags = {
    Name = "WireGuard-Server"
  }
}

# --- Outputs ---
output "instance_public_ip" {
  value = aws_instance.wg_server.public_ip
  description = "The public IP address of the WireGuard server."
}