output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.gmao_vm.id
}

output "public_ip" {
  description = "IP publique de la VM"
  value       = aws_instance.gmao_vm.public_ip
}

output "public_dns" {
  description = "DNS public de la VM"
  value       = aws_instance.gmao_vm.public_dns
}
