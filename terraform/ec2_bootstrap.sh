#!/bin/bash

# Start logging
exec 1> >(tee -a /home/ubuntu/setup.log)
exec 2>&1

echo "Starting setup at $(date)"
echo "----------------------------------------"

# Update system and install base packages
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release awscli

# Install NVIDIA drivers
apt install -y nvidia-driver-535

# Install CloudWatch Agent
echo "Installing CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent for setup logs
echo "Configuring CloudWatch Agent..."
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Create config in the correct location
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ubuntu/setup.log",
            "log_group_name": "/aws/ec2-ollama-engine/logs",
            "log_stream_name": "${INSTANCE_ID}-setup",
            "timezone": "UTC",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

# Also create the config in the bin directory for the fetch-config command
cp /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/bin/config.json

# Start CloudWatch Agent with proper error handling
echo "Starting CloudWatch Agent..."

# Use the fetch-config command which will place the config in the correct location
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

# Enable and start the service
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Wait for CloudWatch Agent to start
echo "Waiting for CloudWatch Agent to start..."
sleep 10

# Verify CloudWatch Agent is running
echo "Verifying CloudWatch Agent status..."
if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "✅ CloudWatch Agent is running successfully"
    systemctl status amazon-cloudwatch-agent --no-pager
else
    echo "❌ CloudWatch Agent failed to start"
    systemctl status amazon-cloudwatch-agent --no-pager
    journalctl -u amazon-cloudwatch-agent --no-pager -n 20
fi

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

# Verify GPU setup
echo "Verifying GPU setup at $(date)"
echo "NVIDIA Driver Version:"
nvidia-smi || echo "NVIDIA driver not ready yet"

echo "----------------------------------------"
echo "Setup completed at $(date)"