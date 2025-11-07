#!/bin/bash

#############################################################################
# PhpRedis Install Helper - Auto-installer for PhpRedis Extension
# 
# This script automatically installs missing PhpRedis extensions
#############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
PHP_BINARY="php"
INSTALL_METHOD=""

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

PhpRedis Install Helper - Auto-installer for PhpRedis Extension

OPTIONS:
    -h, --help          Show this help message
    -p, --php PATH      Specify PHP binary path (default: php)
    -m, --method TYPE   Force installation method (pecl|source|package)

EXAMPLES:
    $0                  # Auto-detect and install
    $0 -m pecl          # Force PECL installation
    $0 -m package       # Force package manager installation

EOF
    exit 0
}

#############################################################################
# Detection Functions
#############################################################################

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS=$(uname -s)
    fi
    
    print_info "Detected OS: $OS"
}

detect_php_version() {
    if ! command -v "$PHP_BINARY" &> /dev/null; then
        print_error "PHP is not installed"
        exit 1
    fi
    
    PHP_VERSION=$($PHP_BINARY -v | head -n 1 | awk '{print $2}')
    PHP_VERSION_SHORT=$($PHP_BINARY -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
    print_info "Detected PHP version: $PHP_VERSION"
}

check_phpredis_installed() {
    if $PHP_BINARY -m | grep -q "redis"; then
        print_success "PhpRedis is already installed"
        return 0
    else
        return 1
    fi
}

#############################################################################
# Installation Methods
#############################################################################

install_via_pecl() {
    print_header "Installing PhpRedis via PECL"
    
    if ! command -v pecl &> /dev/null; then
        print_warning "PECL is not installed, attempting to install..."
        
        case $OS in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y php-pear php${PHP_VERSION_SHORT}-dev
                ;;
            centos|rhel|fedora)
                sudo yum install -y php-pear php-devel
                ;;
            arch)
                sudo pacman -S --noconfirm php-pear
                ;;
            *)
                print_error "Cannot install PECL automatically on this OS"
                return 1
                ;;
        esac
    fi
    
    print_info "Installing PhpRedis extension..."
    sudo pecl install redis
    
    # Enable extension in php.ini
    enable_extension
    
    print_success "PhpRedis installed successfully via PECL"
}

install_via_package() {
    print_header "Installing PhpRedis via Package Manager"
    
    case $OS in
        ubuntu|debian)
            print_info "Installing via apt..."
            sudo apt-get update
            sudo apt-get install -y php${PHP_VERSION_SHORT}-redis || sudo apt-get install -y php-redis
            ;;
        centos|rhel)
            print_info "Installing via yum..."
            sudo yum install -y php-redis
            ;;
        fedora)
            print_info "Installing via dnf..."
            sudo dnf install -y php-redis
            ;;
        arch)
            print_info "Installing via pacman..."
            sudo pacman -S --noconfirm php-redis
            ;;
        alpine)
            print_info "Installing via apk..."
            sudo apk add php${PHP_VERSION_SHORT:0:1}-redis || sudo apk add php-redis
            ;;
        darwin)
            print_info "Installing via brew..."
            brew install php-redis
            ;;
        *)
            print_error "Package installation not supported on this OS"
            return 1
            ;;
    esac
    
    print_success "PhpRedis installed successfully via package manager"
}

install_via_source() {
    print_header "Installing PhpRedis from Source"
    
    # Check for required build tools
    if ! command -v git &> /dev/null; then
        print_error "git is required but not installed"
        return 1
    fi
    
    if ! command -v phpize &> /dev/null; then
        print_error "phpize is required but not installed"
        print_info "Install php-dev package for your system"
        return 1
    fi
    
    # Clone repository
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    print_info "Cloning PhpRedis repository..."
    git clone https://github.com/phpredis/phpredis.git
    cd phpredis
    
    print_info "Building extension..."
    phpize
    ./configure
    make
    sudo make install
    
    # Enable extension
    enable_extension
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    print_success "PhpRedis installed successfully from source"
}

enable_extension() {
    print_info "Enabling PhpRedis extension..."
    
    # Find PHP configuration directory
    PHP_INI_DIR=$($PHP_BINARY --ini | grep "Scan for additional .ini files" | cut -d: -f2 | xargs)
    
    if [ -z "$PHP_INI_DIR" ] || [ "$PHP_INI_DIR" = "(none)" ]; then
        # Fallback to main php.ini
        PHP_INI=$($PHP_BINARY --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)
        
        if [ -f "$PHP_INI" ]; then
            if ! grep -q "extension=redis" "$PHP_INI"; then
                echo "extension=redis.so" | sudo tee -a "$PHP_INI" > /dev/null
                print_success "Added redis extension to $PHP_INI"
            fi
        fi
    else
        # Create separate ini file
        REDIS_INI="$PHP_INI_DIR/20-redis.ini"
        if [ ! -f "$REDIS_INI" ]; then
            echo "extension=redis.so" | sudo tee "$REDIS_INI" > /dev/null
            print_success "Created $REDIS_INI"
        fi
    fi
}

#############################################################################
# Installation Logic
#############################################################################

perform_installation() {
    detect_os
    detect_php_version
    
    # Check if already installed
    if check_phpredis_installed; then
        exit 0
    fi
    
    print_warning "PhpRedis is not installed. Beginning installation..."
    
    # Determine installation method
    if [ -n "$INSTALL_METHOD" ]; then
        case $INSTALL_METHOD in
            pecl)
                install_via_pecl
                ;;
            package)
                install_via_package
                ;;
            source)
                install_via_source
                ;;
            *)
                print_error "Unknown installation method: $INSTALL_METHOD"
                exit 1
                ;;
        esac
    else
        # Auto-detect best method
        print_info "Auto-detecting best installation method..."
        
        # Try package manager first (easiest)
        if install_via_package 2>/dev/null; then
            :
        elif command -v pecl &> /dev/null && install_via_pecl 2>/dev/null; then
            :
        else
            print_warning "Standard methods failed, trying source installation..."
            install_via_source
        fi
    fi
    
    # Verify installation
    echo ""
    print_header "Verification"
    
    if check_phpredis_installed; then
        print_success "Installation successful!"
        REDIS_VERSION=$($PHP_BINARY -r "echo phpversion('redis');")
        print_info "PhpRedis version: $REDIS_VERSION"
    else
        print_error "Installation failed - PhpRedis extension not found"
        print_info "You may need to restart PHP-FPM or your web server"
        exit 1
    fi
}

#############################################################################
# Main Entry Point
#############################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -p|--php)
                PHP_BINARY="$2"
                shift 2
                ;;
            -m|--method)
                INSTALL_METHOD="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Check for root/sudo access
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        print_warning "This script may require sudo access for installation"
        print_info "You may be prompted for your password"
    fi
    
    perform_installation
}

# Execute main function
main "$@"
