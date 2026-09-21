output "alb_dns_name" {
  description = "URL de l'ALB — point d'entrée de votre API backend"
  value       = "http://${aws_lb.main.dns_name}"
}

output "frontend_public_ip" {
  description = "IP publique de l'instance frontend"
  value       = aws_instance.frontend.public_ip
}

output "frontend_url" {
  description = "URL du frontend"
  value       = "http://${aws_instance.frontend.public_ip}"
}

output "rds_endpoint" {
  description = "Endpoint RDS (host de la base de données)"
  value       = aws_db_instance.main.address
}

output "ssh_frontend" {
  description = "Commande SSH pour se connecter au frontend"
  value       = "ssh -i ~/.ssh/projet-cloud-key ubuntu@${aws_instance.frontend.public_ip}"
}