#!/bin/bash

# Exit on error
set -e

# Source environment variables
source .env

# Export AWS credentials from .env
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION


echo "🚀 Starting cleanup process..."
cd terraform

echo "🔧 Initializing Terraform..."
terraform init

# Destroy all infrastructure
echo "🗑️  Destroying all infrastructure..."
terraform destroy -auto-approve

echo "🧹 Cleaning up local Terraform state files..."
find . -type d -name ".terraform" -exec rm -rf {} +
find . -type d -name "terraform.tfstate.d" -exec rm -rf {} +
find . -type f \( \
    -name ".terraform.lock.hcl" \
    -o -name ".terraform.tfstate.lock.info" \
    -o -name "terraform.tfstate.backup" \
    -o -name "terraform.tfstate" \
    -o -name "myplan" \
\) -exec rm -f {} +

# Change back to root directory
cd ..

echo "✅ Cleanup completed successfully!"
echo "All AWS resources and local Terraform state files have been destroyed."
