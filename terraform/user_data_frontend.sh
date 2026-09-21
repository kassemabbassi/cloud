#!/bin/bash
set -e

# Mise à jour du système
apt-get update -y
apt-get upgrade -y

# Installation de Node.js, Nginx, Git et AWS CLI
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs nginx git awscli

# Récupérer l'URL de l'ALB depuis AWS Parameter Store
ALB_URL=$(aws ssm get-parameter \
  --name "/${project_name}/alb-url" \
  --region ${aws_region} \
  --query "Parameter.Value" \
  --output text)

echo "ALB URL récupérée : $ALB_URL"

# Cloner le repo
cd /home/ubuntu
git clone ${github_repo} app
cd app/frontend

# Injecter l'URL ALB dans environment.prod.ts
sed -i "s|http://ALB_URL|http://$ALB_URL|g" \
  src/environments/environment.prod.ts

# Installer et builder Angular
npm install
npm run build -- --configuration production

# Copier vers Nginx
cp -r /home/ubuntu/app/frontend/dist/client/browser/* /var/www/html/

# Démarrer Nginx
systemctl enable nginx
systemctl start nginx

echo "Déploiement frontend terminé ✅"