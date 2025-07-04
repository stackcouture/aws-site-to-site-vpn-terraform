output "ireland_ec2_public_ip" {
  value = aws_instance.ec2_b.public_ip
}

output "mumbai_ec2_private_ip" {
  value = aws_instance.ec2_a.private_ip
}