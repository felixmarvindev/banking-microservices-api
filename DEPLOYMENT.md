# VPS Deployment Guide

This guide provides step-by-step instructions for deploying the Online Banking Microservices API on a VPS.

## Prerequisites

### VPS Requirements
- **OS**: Ubuntu 20.04 LTS or later (recommended)
- **RAM**: Minimum 4GB (8GB recommended for production)
- **CPU**: 2+ cores
- **Storage**: 50GB+ free space
- **Network**: Public IP address with ports 80, 443, 8222, and others open

### Software Requirements
- Docker 20.10+
- Docker Compose 1.29+
- Git
- Basic firewall configuration (UFW recommended)

## Step-by-Step Deployment

### Step 1: Initial VPS Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y docker.io docker-compose git ufw

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Configure Firewall

```bash
# Allow SSH (important - do this first!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow API Gateway
sudo ufw allow 8222/tcp

# Allow Eureka Discovery (optional, for monitoring)
sudo ufw allow 8761/tcp

# Enable firewall
sudo ufw enable
sudo ufw status
```

### Step 3: Clone Repository

```bash
# Clone the repository
git clone <your-repository-url>
cd online-banking-microservices-api

# Or if you're uploading files, create the directory
mkdir -p ~/online-banking-microservices-api
cd ~/online-banking-microservices-api
```

### Step 4: Configure Environment Variables

Create a `.env` file in the root directory (optional, for overriding defaults):

```bash
cat > .env << EOF
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here

# Keycloak
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=your_keycloak_password

# MongoDB
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=your_mongo_password
EOF
```

**Important**: Change all default passwords before production deployment!

### Step 5: Update Configuration for VPS

Update the following configuration files to use your VPS hostname/IP:

1. **Update Kafka configuration** in `docker-compose.yml`:
   - Replace `localhost` with your VPS IP or domain name in `KAFKA_ADVERTISED_LISTENERS`

2. **Update service URLs** in config files:
   - Update `services/config-server/src/main/resources/configurations/*.yml` files
   - Replace `localhost` with your VPS IP or domain name

3. **Update Keycloak issuer URI** in gateway configuration:
   - Update `services/config-server/src/main/resources/configurations/gateway-service.yml`
   - Change `issuer-uri` to your VPS domain/IP

### Step 6: Build and Start Services

```bash
# Build all services (this may take 10-15 minutes on first run)
docker-compose build

# Start infrastructure services first
docker-compose up -d postgresql zookeeper kafka mongodb mail-dev

# Wait for databases to be ready (30-60 seconds)
sleep 60

# Start discovery and config server
docker-compose up -d discovery config-server

# Wait for config server to be ready
sleep 30

# Start all microservices
docker-compose up -d

# Check service status
docker-compose ps
```

### Step 7: Verify Services

```bash
# Check logs for any errors
docker-compose logs -f

# Check specific service logs
docker-compose logs discovery
docker-compose logs gateway
docker-compose logs auth-service

# Check if services are running
docker ps
```

### Step 8: Access Services

After deployment, services will be available at:

- **API Gateway**: `http://your-vps-ip:8222`
- **Eureka Discovery**: `http://your-vps-ip:8761`
- **Swagger Aggregator**: `http://your-vps-ip:8222/swagger-aggregator.html`
- **Auth Service Swagger**: `http://your-vps-ip:8222/auth-service/swagger-ui/index.html`
- **Account Service Swagger**: `http://your-vps-ip:8222/account-service/swagger-ui/index.html`
- **Transaction Service Swagger**: `http://your-vps-ip:8222/transaction-service/swagger-ui/index.html`
- **Loan Service Swagger**: `http://your-vps-ip:8222/loan-service/swagger-ui/index.html`
- **Notification Service Swagger**: `http://your-vps-ip:8222/notification-service/swagger-ui/index.html`

### Step 9: Setup Reverse Proxy (Optional but Recommended)

For production, set up Nginx as a reverse proxy:

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/banking-api
```

Add the following configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8222;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/banking-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 10: Setup SSL with Let's Encrypt (Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Certbot will automatically configure Nginx and set up auto-renewal
```

## Service Ports Reference

| Service | Port | Description |
|---------|------|-------------|
| API Gateway | 8222 | Main entry point |
| Eureka Discovery | 8761 | Service registry |
| Config Server | 8888 | Configuration service |
| Auth Service | 10070 | Authentication |
| Account Service | 10080 | Account management |
| Transaction Service | 10090 | Transactions |
| Loan Service | 10060 | Loan management |
| Notification Service | 10050 | Notifications |
| PostgreSQL | 5432 | Database |
| MongoDB | 27017 | NoSQL database |
| Kafka | 9092 | Message broker |
| Keycloak | 9098 | Identity provider |
| Zipkin | 9411 | Distributed tracing |

## Monitoring and Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f gateway-service

# Last 100 lines
docker-compose logs --tail=100 gateway-service
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart gateway-service
```

### Update Services

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose build
docker-compose up -d
```

### Backup Databases

```bash
# Backup PostgreSQL
docker exec ms_pg_sql pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# Backup MongoDB
docker exec mongo_db mongodump --out /backup
```

## Troubleshooting

### Services Not Starting

1. Check logs: `docker-compose logs <service-name>`
2. Verify dependencies are running: `docker-compose ps`
3. Check port conflicts: `sudo netstat -tulpn | grep <port>`
4. Verify network connectivity: `docker network ls`

### Database Connection Issues

1. Ensure PostgreSQL is running: `docker-compose ps postgresql`
2. Check database credentials in configuration files
3. Verify network connectivity between services

### Kafka Connection Issues

1. Ensure Zookeeper is running first
2. Check Kafka advertised listeners configuration
3. Verify Kafka is accessible: `docker exec ms_kafka kafka-topics --list --bootstrap-server localhost:9092`

### Service Discovery Issues

1. Ensure Eureka is running: `http://your-vps-ip:8761`
2. Check service registration in Eureka dashboard
3. Verify service names match in configuration

## Production Considerations

1. **Security**:
   - Change all default passwords
   - Use strong passwords for databases
   - Enable SSL/TLS
   - Configure firewall properly
   - Regular security updates

2. **Performance**:
   - Monitor resource usage
   - Scale services as needed
   - Configure proper JVM memory settings
   - Use connection pooling

3. **High Availability**:
   - Set up database replication
   - Use load balancers
   - Implement health checks
   - Set up monitoring and alerting

4. **Backup**:
   - Regular database backups
   - Configuration backups
   - Disaster recovery plan

## Support

For issues or questions, please refer to the main README.md or create an issue in the repository.




