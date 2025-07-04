data "aws_ami" "latest_amazon_linux_2_ap_south_1" {
  provider    = aws.mum
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "aws_mumbai_available" {
  provider = aws.mum
  state    = "available"
}

resource "aws_vpc" "vpc_a" {
  provider             = aws.mum
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name    = "VPC-A"
    Project = "VPN-Demo"
  }
}

resource "aws_subnet" "private_a" {
  provider                = aws.mum
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = cidrsubnet(aws_vpc.vpc_a.cidr_block, 8, 0)
  availability_zone       = data.aws_availability_zones.aws_mumbai_available.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "VPC-A-Private-Subnet-1"
  }
}

# Define Route Table for VPC-A
resource "aws_route_table" "vpc_a_private_rt" {
  provider = aws.mum
  vpc_id   = aws_vpc.vpc_a.id  # Replace with your VPC-A ID

  tags = {
    Name = "VPC-A-Private-RT"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  provider        = aws.mum
  subnet_id       = aws_subnet.private_a.id  # Replace with your private subnet ID
  route_table_id  = aws_route_table.vpc_a_private_rt.id  # The VPC-A-Private-RT route table
}

resource "aws_security_group" "ec2_a_sg" {
  provider = aws.mum
  name     = "EC2-A-SG"
  vpc_id   = aws_vpc.vpc_a.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.2.0.0/16"]
  }
  # Allow All ICMP traffic from VPC-B
  ingress {
    from_port   = -1  # ICMP type (no specific port for ICMP)
    to_port     = -1  # ICMP type (no specific port for ICMP)
    protocol    = "icmp"  # Allow ICMP traffic
    cidr_blocks = ["10.2.0.0/16"]  # VPC-B CIDR block
  }
  # Allow All TCP traffic from VPC-B
  ingress {
    from_port   = 0
    to_port     = 65535  # TCP port range (0-65535)
    protocol    = "tcp"  # Allow only TCP traffic
    cidr_blocks = ["10.2.0.0/16"]  # VPC-B CIDR block
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_a" {
  provider                    = aws.mum
  ami                         = data.aws_ami.latest_amazon_linux_2_ap_south_1.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_a_sg.id]
  associate_public_ip_address = false
  key_name                    = var.key_name
  tags = {
    Name = "AWS Side Private Instance"
  }
}





