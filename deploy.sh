#!/bin/bash

# Online Banking Microservices Deployment Script
# This script automates the deployment process on a VPS

set -e  # Exit on error

echo "=========================================="
echo "Online Banking Microservices Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose are installed${NC}"

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker daemon is not running. Please start Docker.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker daemon is running${NC}"

# Build services
echo -e "${YELLOW}Building Docker images...${NC}"
docker-compose build

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Docker images${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker images built successfully${NC}"

# Start infrastructure services first
echo -e "${YELLOW}Starting infrastructure services...${NC}"
docker-compose up -d postgresql zookeeper kafka mongodb mail-dev

echo -e "${YELLOW}Waiting for databases to be ready (60 seconds)...${NC}"
sleep 60

# Start discovery and config server
echo -e "${YELLOW}Starting discovery and config server...${NC}"
docker-compose up -d discovery config-server

echo -e "${YELLOW}Waiting for config server to be ready (30 seconds)...${NC}"
sleep 30

# Start all microservices
echo -e "${YELLOW}Starting all microservices...${NC}"
docker-compose up -d

# Wait for services to start
echo -e "${YELLOW}Waiting for services to start (30 seconds)...${NC}"
sleep 30

# Check service status
echo -e "${YELLOW}Checking service status...${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}=========================================="
echo "Deployment completed successfully!"
echo "==========================================${NC}"
echo ""
echo "Services are available at:"
echo "  - API Gateway: http://localhost:8222"
echo "  - Eureka Discovery: http://localhost:8761"
echo "  - Swagger Aggregator: http://localhost:8222/swagger-aggregator.html"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"
echo ""

