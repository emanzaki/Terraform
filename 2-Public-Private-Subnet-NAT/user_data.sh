#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
echo "Hi from terraform" > /var/www/html/index.html
sudo systemctl start apache2
sudo systemctl enable apache2
sudo ufw allow 'Apache'
