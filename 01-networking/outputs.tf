output "vpc1_id" { value = aws_vpc.vpc1.id }
output "vpc2_id" { value = aws_vpc.vpc2.id }
output "vpc3_id" { value = aws_vpc.vpc3.id }

# Private subnet IDs — EC2 instances and TGW attachments land here
output "subnet1_id" { value = aws_subnet.private1.id }
output "subnet2_id" { value = aws_subnet.private2.id }
output "subnet3_id" { value = aws_subnet.private3.id }

# Private route table IDs — cross-VPC TGW routes are added here in stage 2
output "rt1_id" { value = aws_route_table.private_rt1.id }
output "rt2_id" { value = aws_route_table.private_rt2.id }
output "rt3_id" { value = aws_route_table.private_rt3.id }

# VPC1 public route table — needs spoke return routes added in stage 2
# so NAT Gateway can send return traffic back through TGW to VPC2/VPC3
output "public_rt1_id" { value = aws_route_table.public_rt1.id }
