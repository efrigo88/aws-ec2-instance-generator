locals {
  instance_type = "g5.xlarge"
  init_script   = file("${path.module}/setup.sh")
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
  iam_instance_profile   = aws_iam_instance_profile.ec2_cloudwatch_instance_profile.name

  root_block_device {
    delete_on_termination = true
    volume_size           = local.volume_size
    volume_type           = "gp3"
  }

  user_data = local.init_script

  tags = {
    Name = var.project_name
  }
}

output "ec2_public_ip" {
  value       = aws_instance.aws-ec2-lab.public_ip
  description = "Public IP address of the EC2 instance"
}

output "ollama_api_endpoint" {
  value       = "http://${aws_instance.aws-ec2-lab.public_ip}:11434"
  description = "Ollama API endpoint URL"
}
