#!/bin/bash
set -e

# Mise à jour du système
apt-get update -y
apt-get upgrade -y

# Installation de Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs git

# Cloner le repo
cd /home/ubuntu
git clone ${github_repo} app
cd app/backend

# Créer le fichier .env avec les infos de la base de données
cat > .env << EOF
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
PORT=${app_port}
EOF

# Installer les dépendances et démarrer
npm install
npm install -g pm2
pm2 start index.js --name backend
pm2 startup
pm2 save