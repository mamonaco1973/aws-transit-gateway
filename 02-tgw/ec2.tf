# ================================================================================
# EC2 Instances — one per VPC
# Amazon Linux 2023 with SSM agent pre-installed; nginx serves the identity page
# ================================================================================

resource "aws_instance" "vpc1_instance" {
  provider               = aws.us_east_1
  ami                    = data.aws_ssm_parameter.al2023_us_east_1.value
  instance_type          = "t3.micro"
  subnet_id              = var.subnet1_id
  vpc_security_group_ids = [var.sg1_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum install -y nginx
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)
    echo "$IP - Welcome to VPC us-east-1" > /usr/share/nginx/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = { Name = "tgw-vpc1-instance" }
}

resource "aws_instance" "vpc2_instance" {
  provider               = aws.us_east_2
  ami                    = data.aws_ssm_parameter.al2023_us_east_2.value
  instance_type          = "t3.micro"
  subnet_id              = var.subnet2_id
  vpc_security_group_ids = [var.sg2_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum install -y nginx
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)
    echo "$IP - Welcome to VPC us-east-2" > /usr/share/nginx/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = { Name = "tgw-vpc2-instance" }
}

resource "aws_instance" "vpc3_instance" {
  provider               = aws.us_west_2
  ami                    = data.aws_ssm_parameter.al2023_us_west_2.value
  instance_type          = "t3.micro"
  subnet_id              = var.subnet3_id
  vpc_security_group_ids = [var.sg3_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum install -y nginx
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)
    echo "$IP - Welcome to VPC us-west-2" > /usr/share/nginx/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = { Name = "tgw-vpc3-instance" }
}
