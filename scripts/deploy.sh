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

# Get the bucket name and EC2 IP from Terraform outputs
EC2_IP=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "EC2_IP_NOT_AVAILABLE")
cd ..

# Add permissions to the key
chmod 400 ./key.pem

echo "Waiting for EC2 instance to be ready..."
while ! nc -z ${EC2_IP} 22; do
  sleep 5
done
echo "EC2 instance is ready at ${EC2_IP}"

echo "To connect to the EC2 instance:"
echo "   ssh -i key.pem ubuntu@${EC2_IP}"
echo ""
echo "Note: The EC2 instance may take a few minutes to fully initialize."

echo "✅ Deployment completed successfully!"