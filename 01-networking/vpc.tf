# ================================================================================
# VPC 1 — us-east-1, CIDR 10.0.0.0/16
# Hub VPC — the single NAT Gateway for all three VPCs lives here
# ================================================================================

resource "aws_vpc" "vpc1" {
  provider             = aws.us_east_1
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "tgw-vpc1" }
}

resource "aws_subnet" "public1" {
  provider          = aws.us_east_1
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "tgw-public1" }
}

resource "aws_subnet" "private1" {
  provider          = aws.us_east_1
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "tgw-private1" }
}

resource "aws_internet_gateway" "igw1" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.vpc1.id
  tags = { Name = "tgw-igw1" }
}

resource "aws_eip" "nat1" {
  provider = aws.us_east_1
  domain   = "vpc"
  tags = { Name = "tgw-nat-eip1" }
}

resource "aws_nat_gateway" "nat1" {
  provider      = aws.us_east_1
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public1.id
  tags = { Name = "tgw-nat1" }
}

# Public subnet routes internet outbound; return routes for spoke VPCs added in stage 2
resource "aws_route_table" "public_rt1" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.vpc1.id
  tags = { Name = "tgw-public-rt1" }
}

resource "aws_route" "public_rt1_internet" {
  provider               = aws.us_east_1
  route_table_id         = aws_route_table.public_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw1.id
}

resource "aws_route_table_association" "public_rta1" {
  provider       = aws.us_east_1
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt1.id
}

# Private subnet reaches internet via NAT; cross-VPC routes added in stage 2
resource "aws_route_table" "private_rt1" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.vpc1.id
  tags = { Name = "tgw-private-rt1" }
}

resource "aws_route" "private_rt1_nat" {
  provider               = aws.us_east_1
  route_table_id         = aws_route_table.private_rt1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat1.id
}

resource "aws_route_table_association" "private_rta1" {
  provider       = aws.us_east_1
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt1.id
}

# ================================================================================
# VPC 2 — us-east-2, CIDR 172.16.0.0/16
# Spoke VPC — no IGW or NAT; all internet traffic routes through TGW to VPC1
# ================================================================================

resource "aws_vpc" "vpc2" {
  provider             = aws.us_east_2
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "tgw-vpc2" }
}

resource "aws_subnet" "private2" {
  provider          = aws.us_east_2
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "us-east-2a"
  tags = { Name = "tgw-private2" }
}

resource "aws_route_table" "private_rt2" {
  provider = aws.us_east_2
  vpc_id   = aws_vpc.vpc2.id
  tags = { Name = "tgw-private-rt2" }
}

resource "aws_route_table_association" "private_rta2" {
  provider       = aws.us_east_2
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt2.id
}

# ================================================================================
# VPC 3 — us-west-2, CIDR 192.168.0.0/16
# Spoke VPC — no IGW or NAT; all internet traffic routes through TGW to VPC1
# ================================================================================

resource "aws_vpc" "vpc3" {
  provider             = aws.us_west_2
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "tgw-vpc3" }
}

resource "aws_subnet" "private3" {
  provider          = aws.us_west_2
  vpc_id            = aws_vpc.vpc3.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-west-2a"
  tags = { Name = "tgw-private3" }
}

resource "aws_route_table" "private_rt3" {
  provider = aws.us_west_2
  vpc_id   = aws_vpc.vpc3.id
  tags = { Name = "tgw-private-rt3" }
}

resource "aws_route_table_association" "private_rta3" {
  provider       = aws.us_west_2
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private_rt3.id
}
