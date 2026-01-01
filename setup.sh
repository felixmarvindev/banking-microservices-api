#!/bin/bash

###############################################################################
# Online Banking Microservices - Setup Script
# This script automates the deployment with validation and health checks
###############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMEOUT=300  # 5 minutes timeout for service startup
CHECK_INTERVAL=5  # Check every 5 seconds

###############################################################################
# Utility Functions
###############################################################################

print_header() {
    echo -e "\n${BLUE}===================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

###############################################################################
# Pre-requisite Checks
###############################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_tools=()

    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    else
        print_success "Docker is installed: $(docker --version)"
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing_tools+=("docker-compose")
    else
        if docker compose version &> /dev/null; then
            print_success "Docker Compose is installed: $(docker compose version)"
        else
            print_success "Docker Compose is installed: $(docker-compose --version)"
        fi
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    else
        print_success "Docker daemon is running"
    fi

    # Report missing tools
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install missing tools and try again"
        exit 1
    fi

    # Check available disk space (at least 5GB)
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 5 ]; then
        print_warning "Low disk space: ${available_space}GB available (recommended: 5GB+)"
    else
        print_success "Sufficient disk space: ${available_space}GB available"
    fi
}

###############################################################################
# Service Health Checks
###############################################################################

wait_for_service() {
    local service_name=$1
    local health_url=$2
    local max_attempts=$((TIMEOUT / CHECK_INTERVAL))
    local attempt=1

    print_info "Waiting for $service_name to be healthy..."

    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$health_url" > /dev/null 2>&1; then
            print_success "$service_name is healthy"
            return 0
        fi

        echo -n "."
        sleep $CHECK_INTERVAL
        attempt=$((attempt + 1))
    done

    echo ""
    print_error "$service_name failed to start within ${TIMEOUT}s"
    return 1
}

check_service_health() {
    print_header "Checking Service Health"

    local all_healthy=true

    # Check PostgreSQL
    if docker exec ms_pg_sql pg_isready -U postgres > /dev/null 2>&1; then
        print_success "PostgreSQL is healthy"
    else
        print_error "PostgreSQL is not healthy"
        all_healthy=false
    fi

    # Check Eureka Discovery Service
    if wait_for_service "Eureka Discovery" "http://localhost:8761" ; then
        :
    else
        all_healthy=false
    fi

    # Check Config Server
    if wait_for_service "Config Server" "http://localhost:8888/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    # Check API Gateway
    if wait_for_service "API Gateway" "http://localhost:8222/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    # Check Auth Service
    if wait_for_service "Auth Service" "http://localhost:10070/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    # Check Account Service
    if wait_for_service "Account Service" "http://localhost:10080/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    # Check Transaction Service
    if wait_for_service "Transaction Service" "http://localhost:10090/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    # Check Loan Service
    if wait_for_service "Loan Service" "http://localhost:10060/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    # Check Notification Service
    if wait_for_service "Notification Service" "http://localhost:10050/actuator/health" ; then
        :
    else
        all_healthy=false
    fi

    if [ "$all_healthy" = true ]; then
        print_success "All services are healthy"
        return 0
    else
        print_error "Some services are not healthy"
        return 1
    fi
}

verify_databases() {
    print_header "Verifying Databases"

    local databases=("auth" "account" "transaction" "loan" "notification")
    local all_exist=true

    for db in "${databases[@]}"; do
        if docker exec ms_pg_sql psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$db"; then
            print_success "Database '$db' exists"
        else
            print_error "Database '$db' does not exist"
            all_exist=false
        fi
    done

    if [ "$all_exist" = true ]; then
        return 0
    else
        return 1
    fi
}

check_eureka_registrations() {
    print_header "Verifying Service Registrations in Eureka"

    local services=("AUTH-SERVICE" "ACCOUNT-SERVICE" "TRANSACTION-SERVICE" "LOAN-SERVICE" "NOTIFICATION-SERVICE" "GATEWAY-SERVICE")
    local all_registered=true

    # Wait a bit for services to register
    sleep 10

    for service in "${services[@]}"; do
        if curl -sf "http://localhost:8761/eureka/apps/$service" > /dev/null 2>&1; then
            print_success "$service is registered in Eureka"
        else
            print_warning "$service is not registered in Eureka (may still be starting)"
            all_registered=false
        fi
    done

    if [ "$all_registered" = true ]; then
        return 0
    else
        return 1
    fi
}

###############################################################################
# Build and Deployment
###############################################################################

build_services() {
    print_header "Building Services"

    print_info "Building Docker images (this may take several minutes on first run)..."

    if docker-compose build --no-cache; then
        print_success "All services built successfully"
    else
        print_error "Build failed"
        exit 1
    fi
}

start_infrastructure() {
    print_header "Starting Infrastructure Services"

    print_info "Starting PostgreSQL, MongoDB, Kafka, Zookeeper..."
    docker-compose up -d postgresql mongodb kafka zookeeper mail-dev zipkin keycloak

    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to initialize..."
    local attempt=1
    local max_attempts=30
    while [ $attempt -le $max_attempts ]; do
        if docker exec ms_pg_sql pg_isready -U postgres > /dev/null 2>&1; then
            print_success "PostgreSQL is ready"
            break
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    if [ $attempt -gt $max_attempts ]; then
        print_error "PostgreSQL failed to start"
        exit 1
    fi

    # Verify databases
    sleep 5
    if verify_databases; then
        print_success "All databases initialized"
    else
        print_warning "Some databases may not be initialized"
    fi
}

start_discovery_and_config() {
    print_header "Starting Discovery & Config Services"

    print_info "Starting Eureka Discovery Service..."
    docker-compose up -d discovery
    wait_for_service "Eureka Discovery" "http://localhost:8761"

    print_info "Starting Config Server..."
    docker-compose up -d config-server
    wait_for_service "Config Server" "http://localhost:8888/actuator/health"
}

start_gateway() {
    print_header "Starting API Gateway"

    docker-compose up -d gateway
    wait_for_service "API Gateway" "http://localhost:8222/actuator/health"
}

start_business_services() {
    print_header "Starting Business Services"

    print_info "Starting Auth, Account, Transaction, Loan, and Notification services..."
    docker-compose up -d auth-service account-service transaction-service loan-service notification-service

    sleep 5  # Give services a moment to start
}

###############################################################################
# Smoke Tests
###############################################################################

run_smoke_tests() {
    print_header "Running Smoke Tests"

    local tests_passed=0
    local tests_failed=0

    # Test Swagger Aggregator
    print_info "Testing Swagger Aggregator..."
    if curl -sf "http://localhost:8222/swagger-aggregator.html" > /dev/null; then
        print_success "Swagger Aggregator is accessible"
        ((tests_passed++))
    else
        print_error "Swagger Aggregator is not accessible"
        ((tests_failed++))
    fi

    # Test Auth Service Swagger
    print_info "Testing Auth Service API Documentation..."
    if curl -sf "http://localhost:8222/auth-service/swagger-ui/index.html" > /dev/null; then
        print_success "Auth Service Swagger UI is accessible"
        ((tests_passed++))
    else
        print_error "Auth Service Swagger UI is not accessible"
        ((tests_failed++))
    fi

    # Test Eureka Dashboard
    print_info "Testing Eureka Dashboard..."
    if curl -sf "http://localhost:8761" > /dev/null; then
        print_success "Eureka Dashboard is accessible"
        ((tests_passed++))
    else
        print_error "Eureka Dashboard is not accessible"
        ((tests_failed++))
    fi

    echo ""
    print_info "Smoke Tests: $tests_passed passed, $tests_failed failed"

    if [ $tests_failed -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

###############################################################################
# Main Deployment Flow
###############################################################################

deploy() {
    print_header "Online Banking Microservices - Automated Deployment"

    # Step 1: Check prerequisites
    check_prerequisites

    # Step 2: Build services (optional, controlled by flag)
    if [ "${BUILD_IMAGES:-true}" = "true" ]; then
        build_services
    else
        print_info "Skipping build (using existing images)"
    fi

    # Step 3: Start infrastructure
    start_infrastructure

    # Step 4: Start discovery and config
    start_discovery_and_config

    # Step 5: Start gateway
    start_gateway

    # Step 6: Start business services
    start_business_services

    # Step 7: Health checks
    if check_service_health; then
        print_success "All health checks passed"
    else
        print_error "Health checks failed"
        print_info "Check logs with: docker-compose logs [service-name]"
        exit 1
    fi

    # Step 8: Verify Eureka registrations
    check_eureka_registrations

    # Step 9: Run smoke tests
    if run_smoke_tests; then
        print_success "Smoke tests passed"
    else
        print_warning "Some smoke tests failed"
    fi

    # Success!
    print_header "Deployment Complete!"
    print_success "All services are running"
    echo ""
    print_info "Access Points:"
    echo "  - Swagger Aggregator: http://localhost:8222/swagger-aggregator.html"
    echo "  - Eureka Dashboard:   http://localhost:8761"
    echo "  - API Gateway:        http://localhost:8222"
    echo "  - Zipkin Tracing:     http://localhost:9411"
    echo "  - Maildev UI:         http://localhost:1080"
    echo ""
    print_info "To view logs: docker-compose logs -f [service-name]"
    print_info "To stop all:  ./cleanup.sh"
}

###############################################################################
# Script Execution
###############################################################################

# Parse command line arguments
case "${1:-}" in
    --skip-build)
        BUILD_IMAGES=false
        deploy
        ;;
    --health-check)
        check_service_health
        ;;
    *)
        deploy
        ;;
esac
