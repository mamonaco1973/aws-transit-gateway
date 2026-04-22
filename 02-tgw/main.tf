# ================================================================================
# Provider Configuration
# Three provider aliases — one per region for this multi-region deployment
# ================================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

# ================================================================================
# AMI Data Sources
# Amazon Linux 2023 — SSM agent pre-installed, no bootstrap install needed
# ================================================================================

data "aws_ssm_parameter" "al2023_us_east_1" {
  provider = aws.us_east_1
  name     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "al2023_us_east_2" {
  provider = aws.us_east_2
  name     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "al2023_us_west_2" {
  provider = aws.us_west_2
  name     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
