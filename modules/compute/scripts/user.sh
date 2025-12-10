#!/bin/bash

# Enable logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting User Data Script for ${environment} environment..."

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create App Directory
mkdir -p /app
cd /app

# Create docker-compose.yml
cat <<EOF > docker-compose.yml
services:
  frontend:
    image: ${dockerhub_username}/donation-app-frontend:latest
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: always

  backend:
    image: ${dockerhub_username}/donation-app-backend:latest
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}:5432/${db_name}
      - PORT=5000
      - NODE_ENV=production
    restart: always
EOF

# Start Application
echo "Starting application..."
/usr/local/bin/docker-compose up -d

# Health Check
echo "Waiting for services to start..."
sleep 10
if curl -f http://localhost:5000/api/health; then
    echo "Backend is healthy!"
else
    echo "Backend health check failed!"
fi

if curl -f http://localhost; then
    echo "Frontend is reachable!"
else
    echo "Frontend check failed!"
fi

echo "User Data Script Completed!"