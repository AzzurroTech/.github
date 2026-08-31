#!/bin/bash

# Quick Start Script for AzurroTech + Emperor42 Integration Testing

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

mkdir -p logs

pkill -f "(atp-executable|pod|song|shepherd|stenella)" 2>/dev/null

print_message "$GREEN" "🚀 Starting ATP Integration Hub (port 8080)..."
cd /home/matthew/Scrivania/rev/azzurrotech/atp
go run . --port 8080 > ../logs/atp.log 2>&1 &
ATP_PID=$!
print_message "$GREEN" "✅ ATP Integration Hub started (PID: $ATP_PID)"
sleep 3

print_message "$GREEN" "🚀 Starting POD Database (port 8082)..."
cd /home/matthew/Scrivania/rev/azzurrotech/pod
go run . --port 8082 > ../logs/pod.log 2>&1 &
POD_PID=$!
print_message "$GREEN" "✅ POD Database started (PID: $POD_PID)"
sleep 3

print_message "$GREEN" "🚀 Starting SONG Authentication (port 8083)..."
cd /home/matthew/Scrivania/rev/azzurrotech/song
go run . --port 8083 > ../logs/song.log 2>&1 &
SONG_PID=$!
print_message "$GREEN" "✅ SONG Authentication started (PID: $SONG_PID)"
sleep 3

print_message "$GREEN" "🚀 Starting SHEPHERD Security & Billing (port 8084)..."
cd /home/matthew/Scrivania/rev/azzurrotech/shepherd
go run . --port 8084 > ../logs/shepherd.log 2>&1 &
SHEPHERD_PID=$!
print_message "$GREEN" "✅ SHEPHERD Security & Billing started (PID: $SHEPHERD_PID)"
sleep 3

print_message "$GREEN" "🚀 Starting STENELLA Data Aggregation (port 8081)..."
cd /home/matthew/Scrivania/rev/azzurrotech/stenella
go run . --port 8081 > ../logs/stenella.log 2>&1 &
STENELLA_PID=$!
print_message "$GREEN" "✅ STENELLA Data Aggregation started (PID: $STENELLA_PID)"
sleep 3

print_message "$YELLOW" "=== System Status Check ==="
services=("ATP" "POD" "SONG" "SHEPHERD" "STENELLA")
ports=(8080 8082 8083 8084 8081)
PIDS=("$ATP_PID" "$POD_PID" "$SONG_PID" "$SHEPHERD_PID" "$STENELLA_PID")

for i in "${!ports[@]}"; do
    PORT=${ports[$i]}
    SERVICE=${services[$i]}
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health" 2>/dev/null || echo "000")
    if [[ $HTTP_CODE == "200" ]]; then
        print_message "$GREEN" "$SERVICE (port $PORT): ✅ HEALTHY (HTTP $HTTP_CODE)"
    else
        print_message "$RED" "$SERVICE (port $PORT): ❌ FAILED (HTTP $HTTP_CODE)"
    fi
done

print_message "$GREEN" "{SUCCESS: All services started}"
echo ""
print_message "$YELLOW" "Integration testing in progress...")
print_message "$BLUE" "Execute integration framework:"
print_message "$CYAN" "  ./integration-framework/individual-service-tests.sh"
print_message "$CYAN" "  ./integration-framework/cross-service-integration.sh"
print_message "$CYAN" "  ./integration-framework/full-system-integration.sh"
echo ""
print_message "$YELLOW" "Press Ctrl+C to stop all services...")
wait
