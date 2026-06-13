provider "aws" {
  region = var.aws_region
}

# --- Variables ---
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID jisme resources banana hai"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Sirf is IP ko SSH allow hoga"
  type        = string
  default     = "0.0.0.0/0" # Apna IP daal yahan: "1.2.3.4/32"
}

# --- AMI (dynamic) ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- Subnets ---
resource "aws_subnet" "terraform-subnet-1" {
  vpc_id            = var.vpc_id        #  var se
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "terraform-subnet-2" {
  vpc_id            = var.vpc_id        #  var se
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# --- Security Groups (alag alag) ---
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "ALB ke liye - public HTTP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "EC2 ke liye - sirf ALB se HTTP, restricted SSH"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]               
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 Instance ---
resource "aws_instance" "example" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.terraform-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true  
  
  tags = {
    Name = "JenkinsTerraform"
  }
}

resource "aws_lb" "terraform-alb" {                    
  name               = "terraform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [                                
    aws_subnet.terraform-subnet-1.id,
    aws_subnet.terraform-subnet-2.id
  ]

  tags = {
    Name = "ExampleALB"
  }
}
