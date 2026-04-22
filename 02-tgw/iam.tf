# ================================================================================
# IAM Role and Instance Profile for SSM
# IAM is global — one role and profile work across all three regions
# ================================================================================

resource "aws_iam_role" "ec2_ssm_role" {
  provider = aws.us_east_1
  name     = "tgw-demo-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "tgw-demo-ec2-ssm-role" }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  provider   = aws.us_east_1
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  provider = aws.us_east_1
  name     = "tgw-demo-ec2-ssm-profile"
  role     = aws_iam_role.ec2_ssm_role.name
}
