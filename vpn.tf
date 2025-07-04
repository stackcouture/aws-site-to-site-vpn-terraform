resource "aws_vpn_gateway" "vpgw" {
  provider = aws.mum
  vpc_id   = aws_vpc.vpc_a.id
  tags = {
    Name = "VPC-A-VPGW"
  }
}

resource "aws_customer_gateway" "cgw" {
  provider   = aws.mum
  bgp_asn    = 65000
  ip_address = aws_instance.ec2_b.public_ip
  type       = "ipsec.1"
  tags = {
    Name = "VPC-B-CGW"
  }
  depends_on = [aws_instance.ec2_b]
}

resource "aws_vpn_connection" "vpn" {
  provider            = aws.mum
  vpn_gateway_id      = aws_vpn_gateway.vpgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "VPC-A-VPC-B-VPN"
  }
}

resource "aws_route" "vpn_route" {
  provider               = aws.mum
  route_table_id         = aws_route_table.vpc_a_private_rt.id
  destination_cidr_block = "10.2.0.0/16"           # VPC-B CIDR block
  gateway_id             = aws_vpn_gateway.vpgw.id # Add route to VPN Gateway
}

resource "aws_vpn_gateway" "vpgw_b" {
  provider = aws.irl # Use the Ireland provider
  vpc_id   = aws_vpc.vpc_b.id
  tags = {
    Name = "VPC-B-VPGW"
  }
}

resource "aws_route" "vpn_route_vpc_b" {
  provider               = aws.irl
  route_table_id         = aws_route_table.route_table_b.id
  destination_cidr_block = "10.1.0.0/16" # VPC-A CIDR block
  gateway_id             = aws_vpn_gateway.vpgw_b.id
}

resource "aws_vpn_gateway_route_propagation" "vpc_a_propagation" {
  provider       = aws.mum
  route_table_id = aws_route_table.vpc_a_private_rt.id
  vpn_gateway_id = aws_vpn_gateway.vpgw.id
}