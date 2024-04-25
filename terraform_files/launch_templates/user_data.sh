#!/bin/bash

# Setup Docker Repo

echo "Installs docker engine..."

sudo apt update -y
sudo apt install -y ca-certificates curl gnupg lsb-release jq unzip
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -a -G docker ubuntu

sudo runuser -l ubuntu -c 'mkdir -p /home/ubuntu/.docker && curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s --'

sudo systemctl restart docker

docker run --rm hello-world

docker scout version

# Install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install