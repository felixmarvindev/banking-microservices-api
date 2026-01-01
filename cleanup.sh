#!/bin/bash

###############################################################################
# Online Banking Microservices - Cleanup Script
# This script stops and cleans up all services
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
# Cleanup Functions
###############################################################################

stop_services() {
    print_header "Stopping Services"

    if docker-compose ps -q > /dev/null 2>&1; then
        print_info "Stopping all services..."
        docker-compose stop
        print_success "All services stopped"
    else
        print_info "No services are running"
    fi
}

remove_containers() {
    print_header "Removing Containers"

    if docker-compose ps -a -q > /dev/null 2>&1; then
        print_info "Removing containers..."
        docker-compose down
        print_success "Containers removed"
    else
        print_info "No containers to remove"
    fi
}

remove_volumes() {
    print_header "Removing Volumes"

    print_warning "This will DELETE all data (databases, etc.)"
    read -p "Are you sure you want to remove volumes? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        print_info "Removing volumes..."
        docker-compose down -v
        print_success "Volumes removed"
    else
        print_info "Skipping volume removal"
    fi
}

remove_images() {
    print_header "Removing Images"

    print_warning "This will DELETE all built images"
    read -p "Are you sure you want to remove images? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        print_info "Removing images..."

        # Get all images from this compose project
        images=$(docker-compose config | grep 'image:' | awk '{print $2}' | grep -v 'postgres\|mongo\|kafka\|zookeeper\|keycloak\|zipkin\|maildev')

        for image in $images; do
            if docker rmi "$image" 2>/dev/null; then
                print_success "Removed image: $image"
            fi
        done

        # Also remove built images (ones without registry prefix)
        docker images | grep 'online-banking-microservices-api' | awk '{print $3}' | xargs -r docker rmi -f

        print_success "Images removed"
    else
        print_info "Skipping image removal"
    fi
}

prune_system() {
    print_header "System Cleanup"

    print_info "Removing unused Docker resources..."
    docker system prune -f
    print_success "System cleaned"
}

show_status() {
    print_header "Current Status"

    echo "Running Containers:"
    docker-compose ps

    echo -e "\nDocker System Info:"
    docker system df
}

###############################################################################
# Main Cleanup Flow
###############################################################################

cleanup() {
    print_header "Online Banking Microservices - Cleanup"

    case "${1:-}" in
        --stop)
            stop_services
            ;;
        --remove)
            stop_services
            remove_containers
            ;;
        --full)
            stop_services
            remove_containers
            remove_volumes
            remove_images
            prune_system
            ;;
        --prune)
            prune_system
            ;;
        --status)
            show_status
            ;;
        --help)
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --stop      Stop all running services (containers remain)"
            echo "  --remove    Stop and remove all containers"
            echo "  --full      Complete cleanup (stop, remove containers, volumes, images)"
            echo "  --prune     Remove unused Docker resources"
            echo "  --status    Show current status"
            echo "  --help      Show this help message"
            echo ""
            echo "Default (no option): Stop and remove containers only"
            ;;
        *)
            # Default: stop and remove containers
            stop_services
            remove_containers
            print_success "Cleanup complete!"
            print_info "Data volumes preserved. Use --full for complete cleanup."
            ;;
    esac
}

###############################################################################
# Script Execution
###############################################################################

cleanup "$@"
