locals {
  # https://aws.amazon.com/ec2/instance-types/
  # instance_type = "g5.4xlarge"
  instance_type = "m5.4xlarge"
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
              
              echo "Starting setup at $(date)"
              echo "----------------------------------------"
              
              # Create app directory
              echo "Creating app directory..."
              mkdir -p /home/ubuntu/app
              cd /home/ubuntu/app
              
              # Update system and install required packages
              echo "Updating system and installing required packages..."
              sudo apt update
              sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
              
              # Install AWS CLI
              echo "Installing AWS CLI..."
              sudo apt install -y awscli
              
              # Install NVIDIA drivers
              # echo "Installing NVIDIA drivers..."
              # sudo apt install -y nvidia-driver-535
              
              # Install Docker and Docker Compose
              echo "Installing Docker and Docker Compose..."
              # Add Docker's official GPG key
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              
              # Install Docker Engine
              sudo apt update
              sudo apt install -y docker-ce docker-ce-cli containerd.io
              
              # Install Docker Compose
              sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              
              # Add ubuntu user to docker group
              echo "Adding ubuntu user to docker group..."
              sudo usermod -aG docker ubuntu
              
              # Install NVIDIA Container Toolkit
              # echo "Installing NVIDIA Container Toolkit..."
              # distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
              # curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
              # curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
              # sudo apt update
              # sudo apt install -y nvidia-docker2
              # sudo systemctl restart docker
              
              # Verify installations
              echo "----------------------------------------"
              echo "Verifying installations at $(date)"
              echo "Docker version:"
              docker --version
              echo "Docker Compose version:"
              docker-compose --version
              # echo "NVIDIA installation:"
              # nvidia-smi
              
              echo "----------------------------------------"
              echo "Setup completed at $(date)"
              EOF
}

output "ec2_public_ip" {
  value       = aws_instance.aws-ec2-lab.public_ip
  description = "Public IP address of the EC2 instance"
}
