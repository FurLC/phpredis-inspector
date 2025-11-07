#!/bin/bash

#############################################################################
# PhpRedis Inspector - PhpRedis Environment Management Tool
# 
# This tool detects, suggests, and can automatically fix PhpRedis issues
#############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
OUTPUT_FILE="phpredis-report.json"
AUTO_FIX=false
VERBOSE=false
PHP_BINARY="php"

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

PhpRedis Inspector - PhpRedis Environment Management Tool

OPTIONS:
    -h, --help          Show this help message
    -f, --fix           Automatically fix detected issues
    -v, --verbose       Enable verbose output
    -o, --output FILE   Specify output file (default: phpredis-report.json)
    -p, --php PATH      Specify PHP binary path (default: php)

EXAMPLES:
    $0                  # Run inspection only
    $0 -f               # Run inspection and auto-fix issues
    $0 -v -o report.json # Run with verbose output and custom output file

EOF
    exit 0
}

#############################################################################
# Detection Functions
#############################################################################

check_php_installed() {
    if ! command -v "$PHP_BINARY" &> /dev/null; then
        print_error "PHP is not installed or not found in PATH"
        return 1
    fi
    
    PHP_VERSION=$($PHP_BINARY -v | head -n 1)
    print_success "PHP is installed: $PHP_VERSION"
    return 0
}

check_phpredis_installed() {
    if $PHP_BINARY -m | grep -q "redis"; then
        REDIS_VERSION=$($PHP_BINARY -r "echo phpversion('redis');" 2>/dev/null || echo "unknown")
        print_success "PhpRedis extension is installed (version: $REDIS_VERSION)"
        return 0
    else
        print_warning "PhpRedis extension is NOT installed"
        return 1
    fi
}

check_redis_server() {
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &> /dev/null; then
            REDIS_SERVER_VERSION=$(redis-cli --version | awk '{print $2}')
            print_success "Redis server is running (version: $REDIS_SERVER_VERSION)"
            return 0
        else
            print_warning "Redis server is installed but not running"
            return 1
        fi
    else
        print_warning "Redis server is not installed"
        return 1
    fi
}

check_php_ini_config() {
    print_info "Checking PHP configuration..."
    
    # Check if redis extension is enabled in php.ini
    INI_FILE=$($PHP_BINARY --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)
    
    if [ -f "$INI_FILE" ]; then
        print_success "PHP configuration file found: $INI_FILE"
        
        if grep -q "extension=redis" "$INI_FILE" 2>/dev/null; then
            print_success "Redis extension is enabled in php.ini"
        else
            print_warning "Redis extension not found in php.ini"
        fi
    else
        print_warning "PHP configuration file not found"
    fi
}

check_redis_connection() {
    print_info "Testing Redis connection..."
    
    CONNECTION_TEST=$($PHP_BINARY -r "
    try {
        if (class_exists('Redis')) {
            \$redis = new Redis();
            \$redis->connect('127.0.0.1', 6379, 2);
            echo 'SUCCESS';
        } else {
            echo 'NO_CLASS';
        }
    } catch (Exception \$e) {
        echo 'FAILED';
    }
    " 2>/dev/null || echo "ERROR")
    
    if [ "$CONNECTION_TEST" = "SUCCESS" ]; then
        print_success "Successfully connected to Redis server"
        return 0
    elif [ "$CONNECTION_TEST" = "NO_CLASS" ]; then
        print_error "Redis class not available"
        return 1
    else
        print_warning "Failed to connect to Redis server"
        return 1
    fi
}

check_php_version_compatibility() {
    PHP_VERSION_NUM=$($PHP_BINARY -r "echo PHP_VERSION_ID;")
    
    if [ "$PHP_VERSION_NUM" -ge 70000 ]; then
        print_success "PHP version is compatible (7.0+)"
        return 0
    else
        print_warning "PHP version may be too old for latest PhpRedis"
        return 1
    fi
}

#############################################################################
# Report Generation
#############################################################################

generate_report() {
    local php_installed=$1
    local phpredis_installed=$2
    local redis_server=$3
    local redis_connection=$4
    local php_version_compatible=$5
    
    PHP_VERSION=$($PHP_BINARY -v | head -n 1 | cut -d' ' -f2)
    REDIS_EXT_VERSION=$($PHP_BINARY -r "echo phpversion('redis');" 2>/dev/null || echo "not installed")
    REDIS_SERVER_VERSION=$(redis-cli --version 2>/dev/null | awk '{print $2}' || echo "not installed")
    
    cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "php": {
    "installed": $php_installed,
    "version": "$PHP_VERSION",
    "compatible": $php_version_compatible,
    "binary": "$PHP_BINARY"
  },
  "phpredis": {
    "installed": $phpredis_installed,
    "version": "$REDIS_EXT_VERSION"
  },
  "redis_server": {
    "installed": $redis_server,
    "running": $redis_server,
    "version": "$REDIS_SERVER_VERSION"
  },
  "connection": {
    "successful": $redis_connection
  },
  "recommendations": [
EOF

    local needs_comma=false
    
    if [ "$phpredis_installed" = "false" ]; then
        echo -n "    \"Install PhpRedis extension using install-helper.sh\"" >> "$OUTPUT_FILE"
        needs_comma=true
    fi
    
    if [ "$redis_server" = "false" ]; then
        if [ "$needs_comma" = "true" ]; then
            echo "," >> "$OUTPUT_FILE"
        fi
        echo -n "    \"Install and start Redis server\"" >> "$OUTPUT_FILE"
        needs_comma=true
    fi
    
    if [ "$redis_connection" = "false" ] && [ "$phpredis_installed" = "true" ]; then
        if [ "$needs_comma" = "true" ]; then
            echo "," >> "$OUTPUT_FILE"
        fi
        echo -n "    \"Check Redis server connection settings\"" >> "$OUTPUT_FILE"
        needs_comma=true
    fi
    
    # Add final newline
    echo "" >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << EOF
  ],
  "status": "$(if [ "$phpredis_installed" = "true" ] && [ "$redis_connection" = "true" ]; then echo "healthy"; else echo "needs_attention"; fi)"
}
EOF

    print_success "Report generated: $OUTPUT_FILE"
}

#############################################################################
# Auto-fix Functions
#############################################################################

auto_fix_issues() {
    print_header "Auto-fix Mode"
    
    if [ ! -f "./install-helper.sh" ]; then
        print_error "install-helper.sh not found in current directory"
        return 1
    fi
    
    print_info "Calling install-helper.sh to fix detected issues..."
    bash ./install-helper.sh
}

#############################################################################
# Main Inspection Logic
#############################################################################

run_inspection() {
    print_header "PhpRedis Environment Inspection"
    
    # Run all checks
    php_installed=false
    phpredis_installed=false
    redis_server=false
    redis_connection=false
    php_version_compatible=false
    
    echo ""
    print_info "Step 1: Checking PHP installation..."
    if check_php_installed; then
        php_installed=true
    fi
    
    echo ""
    print_info "Step 2: Checking PHP version compatibility..."
    if check_php_version_compatibility; then
        php_version_compatible=true
    fi
    
    echo ""
    print_info "Step 3: Checking PhpRedis extension..."
    if check_phpredis_installed; then
        phpredis_installed=true
    fi
    
    echo ""
    print_info "Step 4: Checking Redis server..."
    if check_redis_server; then
        redis_server=true
    fi
    
    echo ""
    print_info "Step 5: Checking PHP configuration..."
    check_php_ini_config
    
    echo ""
    print_info "Step 6: Testing Redis connection..."
    if [ "$phpredis_installed" = "true" ]; then
        if check_redis_connection; then
            redis_connection=true
        fi
    else
        print_warning "Skipping connection test (PhpRedis not installed)"
    fi
    
    echo ""
    print_header "Inspection Summary"
    
    if [ "$phpredis_installed" = "true" ] && [ "$redis_connection" = "true" ]; then
        print_success "PhpRedis environment is healthy!"
    else
        print_warning "PhpRedis environment needs attention"
        
        if [ "$phpredis_installed" = "false" ]; then
            print_info "→ Install PhpRedis extension using: ./install-helper.sh"
        fi
        
        if [ "$redis_server" = "false" ]; then
            print_info "→ Install and start Redis server"
        fi
    fi
    
    echo ""
    generate_report "$php_installed" "$phpredis_installed" "$redis_server" "$redis_connection" "$php_version_compatible"
    
    # Auto-fix if requested
    if [ "$AUTO_FIX" = true ] && [ "$phpredis_installed" = "false" ]; then
        echo ""
        auto_fix_issues
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
            -f|--fix)
                AUTO_FIX=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -p|--php)
                PHP_BINARY="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    run_inspection
}

# Execute main function
main "$@"
