# ================================================================================
# Transit Gateways — one per region
# ================================================================================

resource "aws_ec2_transit_gateway" "tgw1" {
  provider    = aws.us_east_1
  description = "TGW for VPC1 (10.0.0.0/16) in us-east-1 - internet egress hub"
  tags = { Name = "tgw-demo-tgw1" }
}

resource "aws_ec2_transit_gateway" "tgw2" {
  provider    = aws.us_east_2
  description = "TGW for VPC2 (172.16.0.0/16) in us-east-2"
  tags = { Name = "tgw-demo-tgw2" }
}

resource "aws_ec2_transit_gateway" "tgw3" {
  provider    = aws.us_west_2
  description = "TGW for VPC3 (192.168.0.0/16) in us-west-2"
  tags = { Name = "tgw-demo-tgw3" }
}

# ================================================================================
# VPC Attachments — connect each VPC to its regional TGW
# ================================================================================

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1_attach" {
  provider           = aws.us_east_1
  transit_gateway_id = aws_ec2_transit_gateway.tgw1.id
  vpc_id             = var.vpc1_id
  subnet_ids         = [var.subnet1_id]
  tags = { Name = "tgw-vpc1-attach" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2_attach" {
  provider           = aws.us_east_2
  transit_gateway_id = aws_ec2_transit_gateway.tgw2.id
  vpc_id             = var.vpc2_id
  subnet_ids         = [var.subnet2_id]
  tags = { Name = "tgw-vpc2-attach" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc3_attach" {
  provider           = aws.us_west_2
  transit_gateway_id = aws_ec2_transit_gateway.tgw3.id
  vpc_id             = var.vpc3_id
  subnet_ids         = [var.subnet3_id]
  tags = { Name = "tgw-vpc3-attach" }
}

# ================================================================================
# TGW Peering — full mesh between all three regions
# ================================================================================

resource "aws_ec2_transit_gateway_peering_attachment" "peer_ue1_ue2" {
  provider                = aws.us_east_1
  transit_gateway_id      = aws_ec2_transit_gateway.tgw1.id
  peer_region             = "us-east-2"
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw2.id
  tags = { Name = "peer-ue1-ue2" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept_ue1_ue2" {
  provider                      = aws.us_east_2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.peer_ue1_ue2.id
  tags = { Name = "accept-ue1-ue2" }
}

resource "aws_ec2_transit_gateway_peering_attachment" "peer_ue1_uw2" {
  provider                = aws.us_east_1
  transit_gateway_id      = aws_ec2_transit_gateway.tgw1.id
  peer_region             = "us-west-2"
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw3.id
  tags = { Name = "peer-ue1-uw2" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept_ue1_uw2" {
  provider                      = aws.us_west_2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.peer_ue1_uw2.id
  tags = { Name = "accept-ue1-uw2" }
}

resource "aws_ec2_transit_gateway_peering_attachment" "peer_ue2_uw2" {
  provider                = aws.us_east_2
  transit_gateway_id      = aws_ec2_transit_gateway.tgw2.id
  peer_region             = "us-west-2"
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw3.id
  tags = { Name = "peer-ue2-uw2" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "accept_ue2_uw2" {
  provider                      = aws.us_west_2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.peer_ue2_uw2.id
  tags = { Name = "accept-ue2-uw2" }
}

# ================================================================================
# TGW1 Route Table (us-east-1 — hub)
# Spoke traffic arriving here for 0.0.0.0/0 is forwarded to VPC1's NAT Gateway
# ================================================================================

resource "aws_ec2_transit_gateway_route" "tgw1_to_vpc2" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw1.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue1_ue2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue1_ue2]
}

resource "aws_ec2_transit_gateway_route" "tgw1_to_vpc3" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "192.168.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw1.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue1_uw2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue1_uw2]
}

# Default route sends spoke internet traffic into VPC1 where the NAT Gateway lives
resource "aws_ec2_transit_gateway_route" "tgw1_default" {
  provider                       = aws.us_east_1
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw1.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc1_attach.id
}

# ================================================================================
# TGW2 Route Table (us-east-2 — spoke)
# Internet-bound traffic is sent to TGW1 via peering; TGW1 forwards to VPC1 NAT
# ================================================================================

resource "aws_ec2_transit_gateway_route" "tgw2_to_vpc1" {
  provider                       = aws.us_east_2
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw2.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue1_ue2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue1_ue2]
}

resource "aws_ec2_transit_gateway_route" "tgw2_to_vpc3" {
  provider                       = aws.us_east_2
  destination_cidr_block         = "192.168.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw2.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue2_uw2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue2_uw2]
}

resource "aws_ec2_transit_gateway_route" "tgw2_default" {
  provider                       = aws.us_east_2
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw2.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue1_ue2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue1_ue2]
}

# ================================================================================
# TGW3 Route Table (us-west-2 — spoke)
# ================================================================================

resource "aws_ec2_transit_gateway_route" "tgw3_to_vpc1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw3.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue1_uw2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue1_uw2]
}

resource "aws_ec2_transit_gateway_route" "tgw3_to_vpc2" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw3.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue2_uw2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue2_uw2]
}

resource "aws_ec2_transit_gateway_route" "tgw3_default" {
  provider                       = aws.us_west_2
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw3.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.peer_ue1_uw2.id
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.accept_ue1_uw2]
}

# ================================================================================
# VPC Route Table Entries
# ================================================================================

# VPC1 private subnet — cross-VPC traffic to spokes via TGW
# (0.0.0.0/0 already points to NAT GW from stage 1)
resource "aws_route" "rt1_to_vpc2" {
  provider               = aws.us_east_1
  route_table_id         = var.rt1_id
  destination_cidr_block = "172.16.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc1_attach]
}

resource "aws_route" "rt1_to_vpc3" {
  provider               = aws.us_east_1
  route_table_id         = var.rt1_id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc1_attach]
}

# VPC1 public subnet — return routes so NAT Gateway can send responses back to spokes
resource "aws_route" "public_rt1_to_vpc2" {
  provider               = aws.us_east_1
  route_table_id         = var.public_rt1_id
  destination_cidr_block = "172.16.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc1_attach]
}

resource "aws_route" "public_rt1_to_vpc3" {
  provider               = aws.us_east_1
  route_table_id         = var.public_rt1_id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw1.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc1_attach]
}

# VPC2 private subnet — all traffic through TGW2 (internet and cross-VPC)
resource "aws_route" "rt2_default" {
  provider               = aws.us_east_2
  route_table_id         = var.rt2_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw2.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc2_attach]
}

resource "aws_route" "rt2_to_vpc1" {
  provider               = aws.us_east_2
  route_table_id         = var.rt2_id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw2.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc2_attach]
}

resource "aws_route" "rt2_to_vpc3" {
  provider               = aws.us_east_2
  route_table_id         = var.rt2_id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw2.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc2_attach]
}

# VPC3 private subnet — all traffic through TGW3 (internet and cross-VPC)
resource "aws_route" "rt3_default" {
  provider               = aws.us_west_2
  route_table_id         = var.rt3_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw3.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc3_attach]
}

resource "aws_route" "rt3_to_vpc1" {
  provider               = aws.us_west_2
  route_table_id         = var.rt3_id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw3.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc3_attach]
}

resource "aws_route" "rt3_to_vpc2" {
  provider               = aws.us_west_2
  route_table_id         = var.rt3_id
  destination_cidr_block = "172.16.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw3.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc3_attach]
}
