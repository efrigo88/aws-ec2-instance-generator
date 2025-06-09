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

# Install NVIDIA drivers
apt install -y nvidia-driver-535

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

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt update
apt install -y nvidia-docker2

# Set NVIDIA as default runtime for Docker
mkdir -p /etc/docker
cat <<EOF_DOCKER_CONF > /etc/docker/daemon.json
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF_DOCKER_CONF

# Restart Docker to apply NVIDIA runtime config
systemctl restart docker

# Wait for NVIDIA drivers to be ready
echo "Waiting for NVIDIA drivers to be ready..."
sleep 15

# Verify GPU setup
echo "Verifying GPU setup at $(date)"
echo "NVIDIA Driver Version:"
nvidia-smi || echo "NVIDIA driver not ready yet"

echo "Verifying Docker GPU support:"
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi || echo "Docker GPU support not ready yet"

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