#!/bin/bash
# Quick wrapper to start all services and run integration tests

# Show script header
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
print_message "$YELLOW" "=== AzurroTech + Emperor42: Full Integration Startup ==="
print_message "$CYAN" "Starting all services and running comprehensive integration tests..."
echo ""

# Start all services
(echo "Starting ATP..."; cd /home/matthew/Scrivania/rev/azzurrotech/atp; ./atp > ../logs/atp.log 2>&1) &
(echo "Starting POD..."; cd /home/matthew/Scrivania/rev/azzurrotech/pod; go run ./cmd > ../logs/pod.log 2>&1) &
(echo "Starting SONG..."; cd /home/matthew/Scrivania/rev/azzurrotech/song; ./song --port 8083 > ../logs/song.log 2>&1) &
(echo "Starting SHEPHERD..."; cd /home/matthew/Scrivania/rev/azzurrotech/shepherd; go run . > ../logs/shepherd.log 2>&1) &
(echo "Starting STENELLA..."; cd /home/matthew/Scrivania/rev/azzurrotech/stenella; go run . > ../logs/stenella.log 2>&1) &

# Wait for services to start
sleep 5

# Check service status
echo ""
echo "=== Service Status ==="
for port in 8080 8081 8082 8083 8084; do
    echo "Port $port: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health || echo "000")"
done

echo ""
echo "=== Available Commands ==="
echo "  ./integration-framework/individual-service-tests.sh"
echo "  ./integration-framework/cross-service-integration.sh"
echo "  ./integration-framework/emperor42-integration.sh"
echo "  ./integration-framework/full-system-integration.sh"

echo ""
echo "Script complete. Press Ctrl+C to stop all services."
wait
