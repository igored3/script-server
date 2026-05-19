#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "******************************************"
echo "Installing dependencies..."
echo "******************************************"

echo "Updating the system and installing essential tools.."
apt update -y && apt upgrade -y
apt install -y openssh-server ufw btop curl wget git build-essential fastfetch samba
echo "Dependencies installed successfully."
echo "******************************************"

echo "Setting up UFW firewall..."
ufw allow OpenSSH
ufw allow 22/tcp
ufw allow 53/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
echo "UFW firewall configured successfully."
echo "******************************************"

echo "Installing Docker and Docker Compose.."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable --now docker
apt install -y docker-compose-plugin
echo "Docker and Docker Compose installed successfully."
echo "******************************************"

echo "Creating Docker network..."
mkdir -p /home/server/docker
cd /home/server/docker
cat <<EOF > docker-compose.yml
version: '3.8'
services:
    pi-hole:
        container_name: pi-hole
        image: pihole/pihole:latest
        ports:
            - "53:53/tcp"
            - "53:53/udp"
            - "8080:80/tcp"
        environment:
            TZ: 'America'
            WEBPASSWORD: 'admin'
        volumes:
            - './etc-pihole:/etc/pihole'
            - './etc-dnsmasq.d:/etc/dnsmasq.d'
        restart: unless-stopped
    portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped

volumes:
  portainer_data:
EOF

docker compose up -d
echo "*******************************************"
echo "Docker containers for Pi-hole and Portainer are up and running."
echo "Pi-hole is accessible at http://localhost:8080 with password 'admin'."
echo "Portainer is accessible at http://localhost:9000."
echo "*******************************************"