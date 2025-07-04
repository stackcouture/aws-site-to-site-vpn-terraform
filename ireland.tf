data "aws_ami" "latest_amazon_linux_2_eu_west_1" {
  provider    = aws.irl
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

data "aws_availability_zones" "available" {
  provider = aws.irl
  state    = "available"
}

resource "aws_vpc" "vpc_b" {
  provider             = aws.irl
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name    = "VPC-B"
    Project = "VPN-Demo"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway_b" {
  provider = aws.irl
  vpc_id   = aws_vpc.vpc_b.id
  tags = {
    Name    = "VPC-B-Internet-Gateway"
    Project = "VPN-Demo"
  }
}

resource "aws_subnet" "public_b" {
  provider   = aws.irl
  vpc_id     = aws_vpc.vpc_b.id
  cidr_block = cidrsubnet(aws_vpc.vpc_b.cidr_block, 8, 0)
  #cidr_block = "10.2.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "VPC-B-Public-Subnet-1"
  }
}

resource "aws_route_table" "route_table_b" {
  provider = aws.irl
  vpc_id   = aws_vpc.vpc_b.id
  tags = {
    Name    = "VPC-B-Route-Table"
    Project = "VPN-Demo"
  }
}

resource "aws_route" "route_to_igw_b" {
  provider               = aws.irl
  route_table_id         = aws_route_table.route_table_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway_b.id
}

# resource "aws_route" "vpn_route_vpc_b" {
#   provider               = aws.irl
#   route_table_id         = aws_route_table.route_table_b.id
#   destination_cidr_block = "10.1.0.0/16"  # VPC-A CIDR block
#   gateway_id             = aws_vpn_gateway.vpgw.id
# }


resource "aws_route_table_association" "route_table_association_b" {
  provider       = aws.irl
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.route_table_b.id
}

resource "aws_security_group" "ec2_b_sg" {
  provider = aws.irl
  name     = "EC2-B-SG"
  vpc_id   = aws_vpc.vpc_b.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["10.1.0.0/16"]
  # }

  ingress {
    from_port   = -1              # ICMP type (no specific port for ICMP)
    to_port     = -1              # ICMP type (no specific port for ICMP)
    protocol    = "icmp"          # Allow ICMP traffic
    cidr_blocks = ["10.1.0.0/16"] # VPC-B CIDR block
  }

  # Allow All TCP traffic from VPC-B
  ingress {
    from_port   = 0
    to_port     = 65535           # TCP port range (0-65535)
    protocol    = "tcp"           # Allow only TCP traffic
    cidr_blocks = ["10.1.0.0/16"] # VPC-B CIDR block
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

resource "aws_instance" "ec2_b" {
  provider                    = aws.irl
  ami                         = data.aws_ami.latest_amazon_linux_2_eu_west_1.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_b.id
  key_name                    = var.ireland_key_name
  vpc_security_group_ids      = [aws_security_group.ec2_b_sg.id]
  availability_zone           = data.aws_availability_zones.available.names[0]
  associate_public_ip_address = true
  root_block_device {
    volume_size = 8     # in GiB
    volume_type = "gp3" # General Purpose SSD
  }
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = {
    Name = "VPC-Server"
  }
}

# Null resource to install httpd and add content
resource "null_resource" "install_httpd" {
  depends_on = [aws_instance.ec2_b] # Ensures EC2 instance is created before running provisioner

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",                                                              # Update the instance packages
      "sudo yum install -y httpd",                                                       # Install Apache HTTP Server
      "echo '<h1>Hello from Terraform Server</h1>' | sudo tee /var/www/html/index.html", # Add content to index.html
      "sudo systemctl start httpd",                                                      # Start Apache
      "sudo systemctl enable httpd",                                                     # Enable Apache to start on boot
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"                                              # Default EC2 user for Amazon Linux 2
      private_key = file("${path.module}/site-to-site-vpn-ireland-key.pem") # Path to your private key
      host        = aws_instance.ec2_b.public_ip                            # EC2 Public IP
    }
  }
}

resource "null_resource" "install_vpn" {
  depends_on = [aws_instance.ec2_b] # Ensure EC2 instance is created before running provisioner

  provisioner "remote-exec" {
    inline = [
      # Update and install OpenSwan for IPSec VPN
      "sudo yum update -y",
      "sudo yum install -y openswan",

      # Configure OpenSwan (this could be a more complex script if needed)
      "echo 'include /etc/ipsec.d/*.conf' | sudo tee -a /etc/ipsec.conf", # Ensure OpenSwan is properly included

      # Enable IP forwarding and adjust sysctl settings
      "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf",
      "echo 'net.ipv4.conf.all_accept_redirects = 0' | sudo tee -a /etc/sysctl.conf",
      "echo 'net.ipv4.conf.all_send_redirects = 0' | sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p", # Apply sysctl settings

      # Restart network service for changes to take effect
      "sudo systemctl restart network",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"                                              # Default user for Amazon Linux 2
      private_key = file("${path.module}/site-to-site-vpn-ireland-key.pem") # Path to your private key
      host        = aws_instance.ec2_b.public_ip                            # Public IP of the EC2 instance
    }
  }
}

# Null resource to install IPSec configuration files for OpenSwan
resource "null_resource" "install_ipsec_config" {
  depends_on = [null_resource.install_vpn] # Ensure OpenSwan and Apache are installed first

  provisioner "remote-exec" {
    inline = [
      # Create the /etc/ipsec.d/aws.conf file for OpenSwan configuration
      "echo -e 'conn Tunnel1\n  authby=secret\n  auto=start\n  left=%defaultroute\n  leftid=54.229.177.254\n  right=15.207.90.59\n  type=tunnel\n  ikelifetime=8h\n  keylife=1h\n  keyexchange=ike\n  leftsubnet=10.2.0.0/16\n  rightsubnet=10.1.0.0/16\n  dpddelay=10\n  dpdtimeout=30\n  dpdaction=restart_by_peer' | sudo tee /etc/ipsec.d/aws.conf",

      # Create the /etc/ipsec.d/aws.secrets file for PSK (Pre-Shared Key)
      "echo '54.229.177.254 15.207.90.59: PSK \"SCvKFWwIHUj1iavJapmfn.lV6NtLKTD_\"' | sudo tee /etc/ipsec.d/aws.secrets"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"                                              # Default user for Amazon Linux 2
      private_key = file("${path.module}/site-to-site-vpn-ireland-key.pem") # Path to your private key
      host        = aws_instance.ec2_b.public_ip                            # Public IP of the EC2 instance
    }
  }
}