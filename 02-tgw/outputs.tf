output "vpc1_instance_id" { value = aws_instance.vpc1_instance.id }
output "vpc2_instance_id" { value = aws_instance.vpc2_instance.id }
output "vpc3_instance_id" { value = aws_instance.vpc3_instance.id }

output "vpc1_private_ip" { value = aws_instance.vpc1_instance.private_ip }
output "vpc2_private_ip" { value = aws_instance.vpc2_instance.private_ip }
output "vpc3_private_ip" { value = aws_instance.vpc3_instance.private_ip }
