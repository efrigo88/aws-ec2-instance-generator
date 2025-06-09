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

echo "Clone the private repo using the copied SSH key"
REPO_URL="git@github.com:MuttData/tram-case-research.git"
if [ -f /home/ubuntu/.ssh/id_rsa ]; then
  echo "Cloning private repo into /home/ubuntu/app/repository..."
  export GIT_SSH_COMMAND="ssh -i /home/ubuntu/.ssh/id_rsa -o StrictHostKeyChecking=no"
  git clone $REPO_URL /home/ubuntu/app/repository || echo "Repo clone failed. Check SSH key permissions."
else
  echo "SSH key not found, skipping repo clone."
fi

echo "----------------------------------------"
echo "Setup completed at $(date)"