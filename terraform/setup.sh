#!/bin/bash

# Start logging
exec 1> >(tee -a /home/ubuntu/setup.log)
exec 2>&1

echo "Starting setup at $(date)"
echo "----------------------------------------"

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent for setup logs
cat >/opt/aws/amazon-cloudwatch-agent/bin/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ubuntu/setup.log",
            "log_group_name": "/aws/ec2-ollama-engine/logs",
            "log_stream_name": "{instance_id}-setup",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2-ollama-engine/logs",
            "log_stream_name": "{instance_id}-system",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "/aws/ec2-ollama-engine/logs",
            "log_stream_name": "{instance_id}-auth",
            "timezone": "UTC"
          }
        ]
      }
    },
    "systemd": {
      "logs_collected": {
        "units": [
          "ollama",
          "amazon-cloudwatch-agent"
        ]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Update system and install base packages
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# Install Ollama
echo "Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
echo "Starting Ollama service..."
systemctl enable ollama
systemctl start ollama

# Configure Ollama to bind to all interfaces via systemd drop-in
echo "Configuring Ollama to bind to all interfaces via systemd..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

# Reload systemd and restart Ollama to apply the new environment variable
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Wait a moment for the service to start
sleep 5

# Verify installations
echo "----------------------------------------"
echo "Verifying installations at $(date)"
echo "Ollama version:"
ollama --version

echo "Ollama service status:"
systemctl status ollama --no-pager

echo "Ollama is running on port 11434"

echo "----------------------------------------"
echo "Setup completed at $(date)"