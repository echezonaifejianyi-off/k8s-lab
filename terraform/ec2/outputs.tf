output "instance_public_ip" {
  description = "Public IP address of the k3s node"
  value       = aws_instance.k3s_node.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the k3s node"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.k3s_node.public_ip}"
}