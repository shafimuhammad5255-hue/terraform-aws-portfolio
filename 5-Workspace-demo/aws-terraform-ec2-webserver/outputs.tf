output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.custom_vpc.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 Instance"
  value       = aws_instance.ssh_server.public_ip
}