terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── AMI Ubuntu 20.04 LTS (Canonical) ──────────────────────────────────────────
data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC par défaut (référence explicite) ───────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

# ── Security Group (idempotent avec name_prefix) ──────────────────────────────
resource "aws_security_group" "gmao_sg" {
  name_prefix = "gmao-sg-"          # Terraform génère un suffixe unique → plus de conflit
  vpc_id      = data.aws_vpc.default.id
  description = "GMAO app : SSH + Spring Boot + Angular"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Spring Boot Backend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Angular Frontend"
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "gmao-sg" }

  # Crée le nouveau SG avant de détruire l'ancien → zéro downtime
  lifecycle {
    create_before_destroy = true
  }
}

# ── EC2 Instance ───────────────────────────────────────────────────────────────
resource "aws_instance" "gmao_vm" {
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = var.instance_type    # t2.large
  key_name               = var.key_name          # vockey
  vpc_security_group_ids = [aws_security_group.gmao_sg.id]

  root_block_device {
    volume_size = 20    # Go — suffisant pour Maven + PostgreSQL + Node
    volume_type = "gp2"
  }

  tags = { Name = "gmao-server" }
}
