#!/bin/bash

# Start logging
exec 1> >(tee -a /home/ubuntu/setup.log)
exec 2>&1

echo "Starting setup at $(date)"
echo "----------------------------------------"

# Create app directory
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app

# Update system and install base packages
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# Install AWS CLI
apt install -y awscli

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Verify installations
echo "----------------------------------------"
echo "Verifying installations at $(date)"
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker-compose --version

# Install and setup Opik
echo "----------------------------------------"
echo "Setting up Opik at $(date)"

# Clone the Opik repository
echo "Cloning Opik repository..."
git clone https://github.com/comet-ml/opik.git
cd opik

# Make the opik.sh script executable
chmod +x opik.sh

# Start Opik in the background
echo "Starting Opik platform..."
nohup ./opik.sh > /home/ubuntu/opik.log 2>&1 &

echo "Opik setup completed. Check /home/ubuntu/opik.log for startup logs."
echo "Opik should be available at port 5173"

echo "----------------------------------------"
echo "Setup completed at $(date)"