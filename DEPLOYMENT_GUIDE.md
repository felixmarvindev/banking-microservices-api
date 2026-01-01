# Deployment Guide

This guide explains how to deploy the Online Banking Microservices system using the automated scripts.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Setup Script](#setup-script)
- [Cleanup Script](#cleanup-script)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Manual Deployment](#manual-deployment)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Docker** (v20.10+)
- **Docker Compose** (v2.0+)
- **Git**
- **curl** (for health checks)
- At least **5GB** of free disk space

### For VPS Deployment

- Ubuntu 20.04+ or similar Linux distribution
- SSH access to the server
- `sudo` privileges

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd online-banking-microservices-api
```

### 2. Make Scripts Executable

```bash
chmod +x setup.sh cleanup.sh
```

### 3. Run Setup

```bash
./setup.sh
```

That's it! The script will:
- ✅ Check prerequisites
- ✅ Build Docker images
- ✅ Start all services in the correct order
- ✅ Run health checks
- ✅ Verify service registrations
- ✅ Run smoke tests

## Setup Script

### Usage

```bash
./setup.sh [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| (no option) | Full deployment with build |
| `--skip-build` | Skip building images (use existing) |
| `--health-check` | Only run health checks on running services |

### Examples

**Full deployment (recommended for first time):**
```bash
./setup.sh
```

**Quick restart (skip build):**
```bash
./setup.sh --skip-build
```

**Check running services:**
```bash
./setup.sh --health-check
```

### What the Script Does

1. **Prerequisite Checks**
   - Verifies Docker installation
   - Checks Docker daemon status
   - Validates available disk space

2. **Build Phase**
   - Builds all service Docker images with dependency caching
   - Takes ~5-10 minutes on first run
   - Subsequent builds are much faster (~1-2 minutes)

3. **Infrastructure Startup**
   - Starts PostgreSQL, MongoDB, Kafka, Zookeeper
   - Waits for databases to be ready
   - Verifies database initialization

4. **Core Services**
   - Starts Eureka Discovery Service
   - Starts Config Server
   - Waits for services to be healthy

5. **Gateway**
   - Starts API Gateway
   - Verifies connectivity

6. **Business Services**
   - Starts Auth, Account, Transaction, Loan, Notification services
   - Each service waits for dependencies

7. **Validation**
   - Health checks on all services
   - Eureka registration verification
   - Smoke tests on key endpoints

### Access Points After Deployment

- **Swagger Aggregator:** http://localhost:8222/swagger-aggregator.html
- **Eureka Dashboard:** http://localhost:8761
- **API Gateway:** http://localhost:8222
- **Zipkin Tracing:** http://localhost:9411
- **Maildev UI:** http://localhost:1080
- **PgAdmin:** http://localhost:5050

## Cleanup Script

### Usage

```bash
./cleanup.sh [OPTIONS]
```

### Options

| Option | Description |
|--------|-------------|
| (no option) | Stop and remove containers (preserve data) |
| `--stop` | Only stop services (containers remain) |
| `--remove` | Stop and remove containers |
| `--full` | Complete cleanup (removes everything including data) |
| `--prune` | Clean up unused Docker resources |
| `--status` | Show current status |
| `--help` | Show help message |

### Examples

**Stop services but keep containers:**
```bash
./cleanup.sh --stop
```

**Remove containers but keep data:**
```bash
./cleanup.sh --remove
```

**Complete cleanup (⚠️ deletes all data):**
```bash
./cleanup.sh --full
```

**Clean up unused Docker resources:**
```bash
./cleanup.sh --prune
```

## GitHub Actions CI/CD

### Overview

The repository includes a comprehensive CI/CD pipeline that:
- Runs tests on all microservices
- Builds Docker images
- Performs integration testing
- Deploys to VPS on main branch pushes

### Setup GitHub Secrets

To enable automatic deployment, add these secrets in your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:

| Secret Name | Description |
|-------------|-------------|
| `VPS_SSH_KEY` | Private SSH key for VPS access |
| `VPS_HOST` | VPS IP address or hostname |
| `VPS_USER` | SSH username (e.g., `ubuntu`) |
| `VPS_DEPLOY_PATH` | Deployment directory (e.g., `/home/ubuntu/banking-app`) |
| `DOCKER_USERNAME` | Docker Hub username (optional) |
| `DOCKER_PASSWORD` | Docker Hub password (optional) |

### Workflow Triggers

The CI/CD pipeline runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger via GitHub Actions UI

### Pipeline Stages

1. **Test** - Run unit tests for all services
2. **Build** - Build Docker images with caching
3. **Integration Test** - Start full stack and run tests
4. **Deploy** - Deploy to VPS (only on main branch)

### Monitoring Deployment

- View pipeline status on GitHub Actions tab
- Deployment logs show each step
- Automatic rollback on failure

## Manual Deployment

If you prefer manual deployment:

### Step 1: Start Infrastructure

```bash
docker-compose up -d postgresql mongodb kafka zookeeper mail-dev zipkin keycloak
```

### Step 2: Wait for Infrastructure

```bash
# Wait ~30 seconds for databases to initialize
sleep 30
```

### Step 3: Start Core Services

```bash
docker-compose up -d discovery config-server
sleep 30  # Wait for registration
```

### Step 4: Start Gateway

```bash
docker-compose up -d gateway
sleep 20
```

### Step 5: Start Business Services

```bash
docker-compose up -d auth-service account-service transaction-service loan-service notification-service
```

### Step 6: Verify Deployment

```bash
curl http://localhost:8761  # Eureka
curl http://localhost:8222/actuator/health  # Gateway
```

## Troubleshooting

### Services Not Starting

**Check Docker daemon:**
```bash
docker info
```

**Check service logs:**
```bash
docker-compose logs [service-name]
```

**Restart a specific service:**
```bash
docker-compose restart [service-name]
```

### Database Connection Issues

**Verify PostgreSQL:**
```bash
docker exec ms_pg_sql pg_isready -U postgres
```

**List databases:**
```bash
docker exec ms_pg_sql psql -U postgres -c "\l"
```

**Recreate databases:**
```bash
docker-compose down -v
docker-compose up -d postgresql
# Databases are auto-created
```

### Service Not Registered in Eureka

**Check Eureka dashboard:**
```bash
curl http://localhost:8761
```

**Verify service is running:**
```bash
docker-compose ps
```

**Restart the service:**
```bash
docker-compose restart [service-name]
```

### Port Already in Use

**Find process using port:**
```bash
# Linux/Mac
lsof -i :8761

# Windows
netstat -ano | findstr :8761
```

**Stop conflicting service or change port in docker-compose.yml**

### Out of Memory

**Check Docker resources:**
```bash
docker system df
```

**Increase Docker memory:**
- Docker Desktop → Settings → Resources → Memory
- Recommended: 4GB+

### Slow Build Times

**Use skip-build option:**
```bash
./setup.sh --skip-build
```

**Clean up Docker cache:**
```bash
docker builder prune -a
```

### Getting Help

**View all service logs:**
```bash
docker-compose logs -f
```

**View specific service:**
```bash
docker-compose logs -f [service-name]
```

**Check service status:**
```bash
./cleanup.sh --status
```

## Best Practices

1. **Always run cleanup before major updates:**
   ```bash
   ./cleanup.sh --remove
   git pull
   ./setup.sh
   ```

2. **Monitor logs during deployment:**
   ```bash
   ./setup.sh &
   docker-compose logs -f
   ```

3. **Regular backups:**
   ```bash
   # Backup PostgreSQL
   docker exec ms_pg_sql pg_dumpall -U postgres > backup.sql
   ```

4. **Use health checks:**
   ```bash
   ./setup.sh --health-check
   ```

5. **Keep images updated:**
   ```bash
   docker-compose pull
   ./setup.sh
   ```

## VPS Deployment

### Initial Setup on VPS

```bash
# SSH into VPS
ssh user@your-vps-ip

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone repository
git clone <repository-url>
cd online-banking-microservices-api

# Run setup
chmod +x setup.sh
./setup.sh
```

### Updating on VPS

```bash
cd online-banking-microservices-api
git pull
./cleanup.sh --remove
./setup.sh
```

### Monitoring on VPS

```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f

# Check resources
docker stats
```

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. View service logs
3. Check GitHub Issues
4. Review CLAUDE.md for architecture details
