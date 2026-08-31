#!/bin/bash

# Fixed Complete System Startup Script
# Starts all AzzurroTech services with correct build commands and ports

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo -e "${YELLOW}==============================================${NC}"
    echo -e "${CYAN}  AZURROTECH SERVICES - FIXED SYSTEM STARTUP${NC}"
    echo -e "${YELLOW}==============================================${NC}"
    echo ""
}

# Function to safely start a service
start_service_safely() {
    local name=$1
    local directory=$2
    local command=$3
    local port=$4

    echo ""
    print_message "$YELLOW" "🚀 Starting $name (port $port)..."

    # Create service-specific directory in logs
    mkdir -p logs

    # Start the service with absolute path logging
    cd "$directory"
    $command > "/home/matthew/Scrivania/rev/logs/${name,,}.log" 2>&1 &
    local pid=$!

    # Save PID for later cleanup
    echo "$name=$pid" > /home/matthew/Scrivania/rev/service_pids.txt

    print_message "$GREEN" "✅ $name started successfully (PID: $pid)"
    return 0
}

print_header

# Clean up previous runs
print_message "$YELLOW" "🧹 Cleaning up previous sessions..."
pkill -f "(atp\|pod\|song\|shepherd\|stenella)" 2>/dev/null || true
sleep 2

if [[ -f /home/matthew/Scrivania/rev/service_pids.txt ]]; then
    rm -f /home/matthew/Scrivania/rev/service_pids.txt
fi

# Start all AzzurroTech services with correct commands
print_message "$YELLOW" "=== AzzurroTech Services (Go-based) ==="

# Start ATP Integration Hub - uses port 8080
print_message "$YELLOW" "=== Starting ATP Integration Hub ==="
sleep 2
start_service_safely "atp" "/home/matthew/Scrivania/rev/azzurrotech/atp" "go run . --port 8080" 8080
sleep 3

# Start POD Database - uses port 8082 (not 8080 to avoid conflicts)
print_message "$YELLOW" "=== Starting POD Database ==="
if ! pgrep -f "pod" > /dev/null; then
    sleep 2
    start_service_safely "pod" "/home/matthew/Scrivania/rev/azzurrotech/pod" "go run . --port 8082" 8082
sleep 3
else
    print_message "$YELLOW" "⚠️ POD service already running, skipping..."
fi

# Start SONG Authentication - uses port 8083
print_message "$YELLOW" "=== Starting SONG Authentication ==="
if ! pgrep -f "song" > /dev/null; then
    sleep 2
    start_service_safely "song" "/home/matthew/Scrivania/rev/azzurrotech/song" "go run . --port 8083" 8083
sleep 3
else
    print_message "$YELLOW" "⚠️ SONG service already running, skipping..."
fi

# Start SHEPHERD Security & Billing - uses port 8084
print_message "$YELLOW" "=== Starting SHEPHERD Security & Billing ==="
if ! pgrep -f "shepherd" > /dev/null; then
    sleep 2
    start_service_safely "shepherd" "/home/matthew/Scrivania/rev/azzurrotech/shepherd" "go run . --port 8084" 8084
sleep 3
else
    print_message "$YELLOW" "⚠️ SHEPHERD service already running, skipping..."
fi

# Start STENELLA Data Aggregation - uses port 8081
print_message "$YELLOW" "=== Starting STENELLA Data Aggregation ==="
if ! pgrep -f "stenella" > /dev/null; then
    sleep 2
    start_service_safely "stenella" "/home/matthew/Scrivania/rev/azzurrotech/stenella" "go run . --port 8081" 8081
sleep 3
else
    print_message "$YELLOW" "⚠️ STENELLA service already running, skipping..."
fi

print_message "$GREEN" "✅ All services started successfully!"
print_message "$YELLOW" "=== Health Check ==="

# Wait for services to initialize
sleep 5

# Check service health
print_message "$YELLOW" "Checking atp (port 8080)..."
if curl -s "http://localhost:8080/health" > /dev/null 2>&1; then
    print_message "$GREEN" "✅ atp: HEALTHY"
else
    print_message "$RED" "❌ atp: UNHEALTHY"
fi

print_message "$YELLOW" "Checking pod (port 8082)..."
if curl -s "http://localhost:8082/health" > /dev/null 2>&1; then
    print_message "$GREEN" "✅ pod: HEALTHY"
else
    print_message "$RED" "❌ pod: UNHEALTHY"
fi

print_message "$YELLOW" "Checking song (port 8083)..."
if curl -s "http://localhost:8083/health" > /dev/null 2>&1; then
    print_message "$GREEN" "✅ song: HEALTHY"
else
    print_message "$RED" "❌ song: UNHEALTHY"
fi

print_message "$YELLOW" "Checking shepherd (port 8084)..."
if curl -s "http://localhost:8084/health" > /dev/null 2>&1; then
    print_message "$GREEN" "✅ shepherd: HEALTHY"
else
    print_message "$RED" "❌ shepherd: UNHEALTHY"
fi

print_message "$YELLOW" "Checking stenella (port 8081)..."
if curl -s "http://localhost:8081/health" > /dev/null 2>&1; then
    print_message "$GREEN" "✅ stenella: HEALTHY"
else
    print_message "$RED" "❌ stenella: UNHEALTHY"
fi

print_message "$GREEN" "=== Startup Complete ==="
print_message "$YELLOW" "Access services:"
print_message "$CYAN" "  atp:     http://localhost:8080"
print_message "$CYAN" "  pod:     http://localhost:8082"
print_message "$CYAN" "  song:    http://localhost:8083"
print_message "$CYAN" "  shepherd: http://localhost:8084"
print_message "$CYAN" "  stenella: http://localhost:8081"

print_message "$YELLOW" "Logs are in: /home/matthew/Scrivania/rev/logs/"