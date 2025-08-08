#!/bin/bash

#!/bin/bash

# Terraform Infrastructure Diagram Generator  
# Production-grade automation for blast-radius diagram generation across multiple AWS environments
#
# Features:
# - Automated prerequisite validation and dependency management
# - Multi-environment diagram generation with error handling
# - Interactive server deployment for development workflows
# - Cross-platform compatibility and CI/CD integration
#
# Usage:
#   ./generate-diagrams.sh generate                    # Generate all environment diagrams
#   ./generate-diagrams.sh serve us-west-1/dev 8080   # Start interactive server
#   ./generate-diagrams.sh help                       # Display usage information

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Check if blast-radius is installed
    if ! command -v blast-radius &> /dev/null; then
        print_error "blast-radius is not installed"
        print_status "Install with: pip install blastradius"
        exit 1
    fi
    
    # Check if graphviz is installed
    if ! command -v dot &> /dev/null; then
        print_error "Graphviz is not installed"
        print_status "Install graphviz before proceeding"
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to generate diagram for a specific environment
generate_diagram() {
    local env_path="$1"
    local env_name="$2"
    
    print_status "Generating diagram for $env_name..."
    
    # Navigate to environment directory
    cd "$PROJECT_ROOT/$env_path"
    
    # Check if terraform files exist
    if [ ! -f "main.tf" ]; then
        print_warning "No main.tf found in $env_path, skipping..."
        return 0
    fi
    
    # Initialize terraform if needed
    if [ ! -d ".terraform" ]; then
        print_status "Initializing Terraform for $env_name..."
        terraform init
    fi
    
    # Generate terraform plan
    print_status "Creating Terraform plan for $env_name..."
    terraform plan -out=tfplan > /dev/null 2>&1
    
    # Generate SVG diagram
    local output_file="$PROJECT_ROOT/diagrams/${env_name}.svg"
    print_status "Generating SVG diagram: $output_file"
    
    if blast-radius --svg > "$output_file" 2>/dev/null; then
        print_success "Generated diagram: diagrams/${env_name}.svg"
    else
        print_error "Failed to generate diagram for $env_name"
        return 1
    fi
    
    # Clean up plan file
    rm -f tfplan
    
    # Return to project root
    cd "$PROJECT_ROOT"
}

# Function to generate diagrams for all environments
generate_all_diagrams() {
    print_status "Generating diagrams for all environments..."
    
    # Define environments
    declare -A environments=(
        ["us-west-1/dev"]="dev-us-west-1"
        ["us-west-1/staging"]="staging-us-west-1"
        ["us-west-1/prod"]="prod-us-west-1"
        ["us-west-2/dev"]="dev-us-west-2"
    )
    
    # Generate diagrams for each environment
    for env_path in "${!environments[@]}"; do
        if [ -d "$PROJECT_ROOT/$env_path" ]; then
            generate_diagram "$env_path" "${environments[$env_path]}"
        else
            print_warning "Environment directory not found: $env_path"
        fi
    done
}

# Function to start interactive server for specific environment
start_server() {
    local env_path="$1"
    local port="${2:-5000}"
    
    print_status "Starting blast-radius server for $env_path..."
    
    cd "$PROJECT_ROOT/$env_path"
    
    # Check if terraform files exist
    if [ ! -f "main.tf" ]; then
        print_error "No main.tf found in $env_path"
        exit 1
    fi
    
    # Initialize terraform if needed
    if [ ! -d ".terraform" ]; then
        print_status "Initializing Terraform..."
        terraform init
    fi
    
    # Generate terraform plan
    print_status "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    print_success "Starting server on http://localhost:$port"
    print_status "Press Ctrl+C to stop the server"
    
    # Start blast-radius server
    blast-radius --serve --port "$port"
}

# Function to show help
show_help() {
    cat << EOF
Terraform Diagram Generation Script

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    generate [ENV]     Generate SVG diagrams
    serve [ENV] [PORT] Start interactive server for environment
    help              Show this help message

EXAMPLES:
    $0 generate                    # Generate diagrams for all environments
    $0 generate us-west-1/dev      # Generate diagram for specific environment
    $0 serve us-west-1/dev         # Start server for dev environment
    $0 serve us-west-1/prod 5001   # Start server on custom port

ENVIRONMENTS:
    us-west-1/dev      Development environment (us-west-1)
    us-west-1/staging  Staging environment (us-west-1)
    us-west-1/prod     Production environment (us-west-1)
    us-west-2/dev      Development environment (us-west-2)

EOF
}

# Main execution
main() {
    case "${1:-generate}" in
        "generate")
            check_prerequisites
            if [ -n "$2" ]; then
                # Generate specific environment
                env_name=$(basename "$2")
                region=$(dirname "$2" | sed 's/us-//')
                generate_diagram "$2" "${env_name}-${region}"
            else
                # Generate all environments
                generate_all_diagrams
            fi
            ;;
        "serve")
            check_prerequisites
            if [ -n "$2" ]; then
                start_server "$2" "${3:-5000}"
            else
                print_error "Environment path required for serve command"
                print_status "Example: $0 serve us-west-1/dev"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
