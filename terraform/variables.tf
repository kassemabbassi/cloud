variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Préfixe pour nommer toutes les ressources"
  type        = string
  default     = "projet-cloud"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Nom de la paire de clés SSH dans AWS"
  type        = string
  default     = "projet-cloud-key"
}

variable "public_key_path" {
  description = "Chemin vers la clé publique SSH"
  type        = string
  default     = "~/.ssh/projet-cloud-key.pub"
}

variable "my_ip" {
  description = "Votre IP publique pour autoriser le SSH"
  type        = string
}

variable "app_port" {
  description = "Port sur lequel tourne votre API backend"
  type        = number
  default     = 3000
}

variable "github_repo" {
  description = "URL complète de votre dépôt GitHub"
  type        = string
}

variable "db_engine" {
  description = "Moteur de base de données : mysql ou postgres"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Version du moteur"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Nom d'utilisateur RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Mot de passe RDS"
  type        = string
  sensitive   = true
}