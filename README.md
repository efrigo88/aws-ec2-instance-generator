# AWS EC2 Instance Generator

A Terraform-based infrastructure as code (IaC) project for automating the creation and management of AWS EC2 instances with associated networking and security configurations.

## Project Structure

```
.
├── terraform/           # Terraform configuration files
│   ├── compute.tf      # EC2 instance configurations
│   ├── networking.tf   # VPC and subnet configurations
│   ├── sg.tf          # Security group rules
│   ├── key.tf         # SSH key pair management
│   ├── provider.tf    # AWS provider configuration
│   └── variables.tf   # Input variables
└── scripts/           # Utility scripts
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions

## Features

- Automated EC2 instance provisioning
- VPC and subnet configuration
- Security group management
- SSH key pair handling
- Customizable instance types and configurations

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/aws-ec2-instance-generator.git
   cd aws-ec2-instance-generator
   ```

2. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the planned changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

6. Commands to copy a repo to the EC2 instance:
   ```bash
    ssh -i key.pem ubuntu@<EC2-IP> "sudo mkdir -p /home/ubuntu/app/repository && sudo chown -R ubuntu:ubuntu /home/ubuntu/app"

    rsync -avz -e "ssh -i key.pem" --exclude='.venv' ../<PATH-TO-REPO>/ ubuntu@<EC2-IP>:/home/ubuntu/app/repository/
   ```

7. Command to copy the output from the EC2 instance to your PC:
   ```bash
   rsync -avz -e "ssh -i key.pem -o IdentitiesOnly=yes" ubuntu@<EC2-IP>:/home/ubuntu/app/repository/data/output/ ~/Downloads/
   ```

## Configuration

The project uses variables defined in `terraform/variables.tf` to customize the deployment. Key variables include:

- `instance_type`: The type of EC2 instance to launch
- `region`: AWS region for deployment
- `environment`: Deployment environment (e.g., dev, prod)
- `vpc_cidr`: CIDR block for the VPC
- `subnet_cidr`: CIDR block for the subnet

## Security

- Security groups are configured to allow only necessary traffic
- SSH key pairs are managed securely
- Network access is restricted to specified CIDR blocks

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the terms of the included LICENSE file.

## Support

For issues and feature requests, please create an issue in the GitHub repository.
