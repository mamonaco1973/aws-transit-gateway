# ================================================================================
# Security Groups — one per VPC
# Allow HTTP from all three VPC CIDRs; unrestricted egress for SSM + internet
# ================================================================================

resource "aws_security_group" "sg1" {
  provider    = aws.us_east_1
  name        = "tgw-demo-sg1"
  description = "Allow HTTP from VPC CIDRs, unrestricted egress"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tgw-demo-sg1" }
}

resource "aws_security_group" "sg2" {
  provider    = aws.us_east_2
  name        = "tgw-demo-sg2"
  description = "Allow HTTP from VPC CIDRs, unrestricted egress"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tgw-demo-sg2" }
}

resource "aws_security_group" "sg3" {
  provider    = aws.us_west_2
  name        = "tgw-demo-sg3"
  description = "Allow HTTP from VPC CIDRs, unrestricted egress"
  vpc_id      = aws_vpc.vpc3.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "172.16.0.0/16", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tgw-demo-sg3" }
}
