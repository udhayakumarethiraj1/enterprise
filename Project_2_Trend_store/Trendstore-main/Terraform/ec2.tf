#---------------------------------
# Ubuntu AMI Auto Lookup
#---------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#---------------------------------
# Security Group
#---------------------------------
resource "aws_security_group" "ec2_sg" {
  name   = "${local.name}-ec2-sg"
  vpc_id = module.vpc.vpc_id

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
    Name        = "${local.name}-ec2-sg"
    Project     = local.name
  }
}

#---------------------------------
# EC2 INSTANCE
#---------------------------------
resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = "trendstore-key"

  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name        = "${local.name}-ec2"
    Project     = local.name
    ManagedBy   = "Terraform"
  }
}

