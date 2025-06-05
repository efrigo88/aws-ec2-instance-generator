locals {
  instance_type = "g5.xlarge"
  init_script   = file("${path.module}/scripts/setup_gpu.sh")
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

  # In case the instance type is spot, uncomment the following block
  # instance_market_options {
  #   market_type = "spot"
  #   spot_options {
  #     max_price = "2.0" # Maximum price you're willing to pay per hour
  #   }
  # }

  root_block_device {
    delete_on_termination = true
    volume_size           = local.volume_size
    volume_type           = "gp3"
  }

  user_data = local.init_script
}

output "ec2_public_ip" {
  value       = aws_instance.aws-ec2-lab.public_ip
  description = "Public IP address of the EC2 instance"
}
