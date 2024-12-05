#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root. Use 'sudo' to execute it."
   exit 1
fi

echo "Updating and upgrading the system..."
apt update && apt upgrade -y

echo "Installing prerequisites..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg lsb-release

echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker Engine..."
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Starting and enabling Docker service..."
systemctl start docker
systemctl enable docker

echo "Adding current user to Docker group for non-root access..."
usermod -aG docker $SUDO_USER

echo "Installing Docker Compose (latest version)..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Testing Docker installation..."
docker --version
docker-compose --version

echo "Configuring Docker security (optional)..."
echo '{"icc": false, "userns-remap": "default"}' > /etc/docker/daemon.json

echo "Restarting Docker service to apply changes..."
systemctl restart docker

echo "Docker and Docker Compose setup complete."
echo "You may need to log out and back in for the Docker group permissions to take effect."
