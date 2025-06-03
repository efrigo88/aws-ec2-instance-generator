locals {
  # https://aws.amazon.com/ec2/instance-types/
  instance_type = "g5.xlarge"
  volume_size   = 200
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "aws-ec2-lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.ssh_key.key_name

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "2.0" # Maximum price you're willing to pay per hour
    }
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = local.volume_size
    volume_type           = "gp3"
  }

  user_data = <<-EOF
        #!/bin/bash

        # Start logging
        exec 1> >(tee -a /home/ubuntu/setup.log)
        exec 2>&1

        echo "Starting setup at \$(date)"
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
        https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io

        # Install Docker Compose
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        # Add ubuntu user to docker group
        usermod -aG docker ubuntu

        # Install NVIDIA Container Toolkit
        distribution=\$(. /etc/os-release; echo \$ID\$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/\$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
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
        sleep 30

        # Verify GPU setup
        echo "----------------------------------------"
        echo "Verifying GPU setup at \$(date)"
        echo "NVIDIA Driver Version:"
        nvidia-smi || echo "NVIDIA driver not ready yet"
        echo "----------------------------------------"
        echo "Verifying Docker GPU support:"
        docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi || echo "Docker GPU support not ready yet"
        echo "----------------------------------------"
        echo "Setup completed at \$(date)"
EOF
}

output "ec2_public_ip" {
  value       = aws_instance.aws-ec2-lab.public_ip
  description = "Public IP address of the EC2 instance"
}
