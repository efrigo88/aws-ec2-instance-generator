#!/bin/bash

# Exit on error
set -e

# Source environment variables
source .env

# Export AWS credentials from .env
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# Initialize and apply Terraform
cd terraform
terraform init
terraform apply -auto-approve

# Configuration
AWS_REGION=${AWS_DEFAULT_REGION}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get the bucket name and EC2 IP from Terraform outputs
EC2_IP=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "EC2_IP_NOT_AVAILABLE")
cd ..

# Add permissions to the key
chmod 400 ./key.pem

echo "Copying GitHub SSH keys to EC2..."
SSH_KEY_ROOT_PATH=~/.ssh
SSH_KEY_FILE_NAME="mutt"
SSH_KEY_PATH="$SSH_KEY_ROOT_PATH/$SSH_KEY_FILE_NAME"
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "GitHub SSH key not found at $SSH_KEY_PATH. Please ensure the key exists."
  exit 1
fi

scp -i ./key.pem -o StrictHostKeyChecking=no "$SSH_KEY_PATH" ubuntu@${EC2_IP}:/home/ubuntu/.ssh/id_rsa
scp -i ./key.pem -o StrictHostKeyChecking=no "$SSH_KEY_PATH.pub" ubuntu@${EC2_IP}:/home/ubuntu/.ssh/id_rsa.pub

echo "Set permissions and add GitHub to known_hosts on EC2"
ssh -i ./key.pem -o StrictHostKeyChecking=no ubuntu@${EC2_IP} << 'EOF'
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_rsa
  chmod 644 ~/.ssh/id_rsa.pub
  chmod 644 ~/.ssh/known_hosts
  ssh-keyscan github.com >> ~/.ssh/known_hosts
EOF

echo "To connect to the EC2 instance:"
echo "   ssh -i key.pem ubuntu@${EC2_IP}"
echo ""
echo "Note: The EC2 instance may take a few minutes to fully initialize."

echo "✅ Deployment completed successfully!"