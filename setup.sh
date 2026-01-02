#!/bin/bash

###############################################################################
# Online Banking Microservices - Setup Script
# Fast, cache-safe, Docker Compose v1/v2 compatible
###############################################################################

set -euo pipefail

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
TIMEOUT=300
CHECK_INTERVAL=5

# ---------------------------------------------------------------------------
# Detect Docker Compose (v2 preferred, v1 fallback)
# ---------------------------------------------------------------------------
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo -e "${RED}✗ Docker Compose not found${NC}"
  exit 1
fi

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
print_header() {
  echo -e "\n${BLUE}============================================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}============================================================${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ $1${NC}"; }

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------
check_prerequisites() {
  print_header "Checking Prerequisites"

  command -v docker >/dev/null || { print_error "Docker not installed"; exit 1; }
  docker info >/dev/null || { print_error "Docker daemon not running"; exit 1; }

  print_success "Docker OK: $(docker --version)"
  print_success "Compose OK: $($COMPOSE_CMD version 2>/dev/null | head -n1)"

  AVAILABLE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
  if [ "$AVAILABLE" -lt 5 ]; then
    print_warning "Low disk space: ${AVAILABLE}GB"
  else
    print_success "Disk space: ${AVAILABLE}GB"
  fi
}

# ---------------------------------------------------------------------------
# Health helpers
# ---------------------------------------------------------------------------
wait_for_service() {
  local name=$1
  local url=$2
  local max=$((TIMEOUT / CHECK_INTERVAL))

  print_info "Waiting for $name..."

  for ((i=1;i<=max;i++)); do
    if curl -sf "$url" >/dev/null 2>&1; then
      print_success "$name is healthy"
      return 0
    fi
    sleep $CHECK_INTERVAL
  done

  print_error "$name failed to become healthy"
  return 1
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build_services() {
  print_header "Building Services (Cache Enabled)"

  print_info "Using: $COMPOSE_CMD build"
  print_info "Maven cache is shared (BuildKit)"

  $COMPOSE_CMD build
  print_success "Images built successfully"
}

# ---------------------------------------------------------------------------
# Infrastructure
# ---------------------------------------------------------------------------
start_infrastructure() {
  print_header "Starting Infrastructure"

  $COMPOSE_CMD up -d \
    postgresql mongodb kafka zookeeper mail-dev zipkin keycloak

  print_info "Waiting for PostgreSQL..."
  for i in {1..30}; do
    if docker exec ms_pg_sql pg_isready -U postgres >/dev/null 2>&1; then
      print_success "PostgreSQL is ready"
      return
    fi
    sleep 2
  done

  print_error "PostgreSQL failed to start"
  exit 1
}

# ---------------------------------------------------------------------------
# Core services
# ---------------------------------------------------------------------------
start_discovery_and_config() {
  print_header "Starting Discovery & Config"

  $COMPOSE_CMD up -d config-server
  wait_for_service "Config Server" "http://localhost:8888/actuator/health"

  $COMPOSE_CMD up -d discovery
  wait_for_service "Discovery" "http://localhost:8761"
}

start_gateway() {
  print_header "Starting API Gateway"

  $COMPOSE_CMD up -d gateway
  wait_for_service "API Gateway" "http://localhost:8222/actuator/health"
}

# ---------------------------------------------------------------------------
# Business services
# ---------------------------------------------------------------------------
start_business_services() {
  print_header "Starting Business Services"

  $COMPOSE_CMD up -d \
    auth-service account-service \
    transaction-service loan-service notification-service

  sleep 5
}

# ---------------------------------------------------------------------------
# Health checks
# ---------------------------------------------------------------------------
check_service_health() {
  print_header "Running Health Checks"

  local ok=true

  wait_for_service "Auth Service" "http://localhost:10070/actuator/health" || ok=false
  wait_for_service "Account Service" "http://localhost:10080/actuator/health" || ok=false
  wait_for_service "Transaction Service" "http://localhost:10090/actuator/health" || ok=false
  wait_for_service "Loan Service" "http://localhost:10060/actuator/health" || ok=false
  wait_for_service "Notification Service" "http://localhost:10050/actuator/health" || ok=false

  $ok || exit 1
  print_success "All services healthy"
}

# ---------------------------------------------------------------------------
# Smoke tests
# ---------------------------------------------------------------------------
run_smoke_tests() {
  print_header "Smoke Tests"

  curl -sf http://localhost:8761 >/dev/null && print_success "Eureka OK"
  curl -sf http://localhost:8222/swagger-aggregator.html >/dev/null && print_success "Swagger OK"
}


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
cleanup() {
  print_header "Cleaning Up"
  $COMPOSE_CMD down
  print_success "Cleanup complete"
}


# ---------------------------------------------------------------------------
# Build Only
# ---------------------------------------------------------------------------
build_only() {
  print_header "Building Services Only"
  build_services
  print_success "Build complete"
}

# ---------------------------------------------------------------------------
# Check Healths
# ---------------------------------------------------------------------------
check_healths() {
  print_header "Checking Healths"
  check_service_health
  print_success "Healths checked"
}



# ---------------------------------------------------------------------------
# Deploy flow
# ---------------------------------------------------------------------------
deploy() {
  print_header "Online Banking Microservices Deployment"

  check_prerequisites

  if [ "${BUILD_IMAGES:-true}" = "true" ]; then
    build_services
  else
    print_info "Skipping image build"
  fi

  start_infrastructure
  start_discovery_and_config
  start_gateway
  start_business_services
  check_service_health
  run_smoke_tests

  print_header "Deployment Complete"
  print_success "System is up and running"
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
case "${1:-}" in
  --skip-build)
    BUILD_IMAGES=false
    deploy
    ;;
  --health-check)
    check_service_health
    ;;
  --build-only)
    build_only
    ;;
  *)
    deploy
    ;;
esac
