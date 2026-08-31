#!/bin/bash

# Integrated AzzurroTech and Emperor42 Stack Startup Script
# This script starts all components together with proper process management

# Configuration
BLUE="\033[0;34m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Project directories
ATP_DIR="/home/matthew/Scrivania/rev/azzurrotech/atp"
STENELLA_DIR="/home/matthew/Scrivania/rev/azzurrotech/stenella"
POD_DIR="/home/matthew/Scrivania/rev/azzurrotech/pod"
SONG_DIR="/home/matthew/Scrivania/rev/azzurrotech/song"
SHEPHERD_DIR="/home/matthew/Scrivania/rev/azzurrotech/shepherd"
WEBSITE_DIR="/home/matthew/Scrivania/rev/azzurro.tech"

# Process IDs array
PROCESSES=()

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to start a component
start_component() {
    local name=$1
    local directory=$2
    local command=$3
    local port=$4

    print_message "$YELLOW" "Starting ${name} on port ${port}..."

    cd "$directory"

    # Start the component in background
    if eval "$command &"; then
        local pid=$!
        PROCESSES+=("$pid")
        print_message "$GREEN" "✓ ${name} started successfully (PID: $pid)"
        print_message "$BLUE" "  Endpoint: http://localhost:${port}"
    else
        print_message "$RED" "✗ Failed to start ${name}"
        return 1
    fi

    cd - > /dev/null
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -i :"$port" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to display system status
print_system_status() {
    echo ""
    print_message "$YELLOW" "=== AZZURROTECH & EMPEROR42 INTEGRATED STACK STATUS ==="
    echo ""

    # Check each component
    components=(
        "atp|8080|${ATP_DIR}|go run . --port 8080"
        "stenella|8081|${STENELLA_DIR}|go run . --port 8081"
        "pod|8082|${POD_DIR}|go run . --port 8082"
        "song|8083|${SONG_DIR}|go run . --port 8083"
        "shepherd|8084|${SHEPHERD_DIR}|go run . --port 8084"
    )

    local running_count=0
    local total_count=${#components[@]}

    for component in "${components[@]}"; do
        IFS='|' read -r name port directory cmd <<< "$component"

        if check_port "$port"; then
            print_message "$GREEN" "✓ ${name}: RUNNING (http://localhost:${port})"
            ((running_count++))
        else
            print_message "$RED" "✗ ${name}: STOPPED"
        fi
    done

    echo ""
    print_message "$YELLOW" "Summary: ${running_count}/${total_count} components running"

    if [ "$running_count" -eq "$total_count" ]; then
        print_message "$GREEN" "🎉 All components are running!"
    else
        print_message "$YELLOW" "⚠️  Some components are not running"
    fi
}

# Function to display integration endpoints
print_integration_endpoints() {
    echo ""
    print_message "$YELLOW" "=== INTEGRATION ENDPOINTS ==="
    echo ""

    # Show atp integration hub endpoints
    print_message "$BLUE" "ATP Integration Hub (port 8080):"
    echo "  - Main: http://localhost:8080/"
    echo "  - Health: http://localhost:8080/health"
    echo "  - Services: http://localhost:8080/api/services"
    echo "  - Config: http://localhost:8080/api/config"
    echo ""

    # Show individual service endpoints
    print_message "$BLUE" "Individual Services:"
    echo "  - Stenella Data Platform: http://localhost:8081/"
    echo "    - Health: http://localhost:8081/health"
    echo "    - Data: http://localhost:8081/api/data"
    echo ""
    echo "  - Pod Database: http://localhost:8082/"
    echo "    - Health: http://localhost:8082/health"
    echo "    - Forms: http://localhost:8082/api/forms"
    echo ""
    echo "  - Song Authentication: http://localhost:8083/"
    echo "    - Health: http://localhost:8083/health"
    echo "    - Auth: http://localhost:8083/api/auth/generate"
    echo ""
    echo "  - Shepherd Security: http://localhost:8084/"
    echo "    - Health: http://localhost:8084/health"
    echo "    - Firewall: http://localhost:8084/api/firewall/rules"
    echo "    - Billing: http://localhost:8084/api/billing"
    echo ""

    # Show website endpoint
    print_message "$BLUE" "Website:"
    echo "  - Azzurro.tech: http://localhost:8080/ (or open browser)"
    echo ""
}

# Function to stop all processes
stop_all_processes() {
    echo ""
    print_message "$YELLOW" "Stopping all components..."

    # Kill processes in reverse order
    for (( i=${#PROCESSES[@]}-1 ; i>=0 ; i-- )); do
        local pid=${PROCESSES[i]}
        if kill -0 "$pid" > /dev/null 2>&1; then
            print_message "$BLUE" "Stopping process ${pid}..."
            kill "$pid" 2>/dev/null
            sleep 2
        fi
    done

    # Clear the processes array
    PROCESSES=()

    print_message "$GREEN" "✅ All components stopped"
}

# Function to show help
print_help() {
    echo ""
    print_message "$YELLOW" "=== INTEGRATED STACK CONTROL ==="
    echo ""
    print_message "$BLUE" "Commands:"
    echo "  ./start_integrated_stack.sh start    Start all components"
    echo "  ./start_integrated_stack.sh stop     Stop all components"
    echo "  ./start_integrated_stack.sh status   Show system status"
    echo "  ./start_integrated_stack.sh endpoints Show integration endpoints"
    echo "  ./start_integrated_stack.sh help     Show this help"
    echo ""
}

# Main script logic
case "${1:-}" in
    start)
        echo ""
        print_message "$GREEN" "🚀 Starting AzzurroTech and Emperor42 Integrated Stack"
        echo ""

        # Check if ports are available
        ports_to_check=(8080 8081 8082 8083 8084)
        for port in "${ports_to_check[@]}"; do
            if check_port "$port"; then
                print_message "$RED" "❌ Port ${port} is already in use."
                echo "   Please stop any running components first."
                exit 1
            fi
        done

        # Start components in order
        start_component "atp" "$ATP_DIR" "go run . --port 8080" 8080
        sleep 2
        start_component "stenella" "$STENELLA_DIR" "go run . --port 8081" 8081
        sleep 2
        start_component "pod" "$POD_DIR" "go run . --port 8082" 8082
        sleep 2
        start_component "song" "$SONG_DIR" "go run . --port 8083" 8083
        sleep 2
        start_component "shepherd" "$SHEPHERD_DIR" "go run . --port 8084" 8084

        echo ""
        print_message "$GREEN" "🎉 All components started successfully!"
        echo ""
        print_message "$BLUE" "Next steps:"
        echo "  1. Check system status: ./start_integrated_stack.sh status"
        echo "  2. View integration endpoints: ./start_integrated_stack.sh endpoints"
        echo "  3. Open browser to: http://localhost:8080"
        echo "  4. To stop all components: ./start_integrated_stack.sh stop"
        echo ""
        print_message "$YELLOW" "💡 Tip: You can open http://localhost:8080 in your browser to test the integrated system."
        ;;

    stop)
        stop_all_processes
        ;;

    status)
        print_system_status
        ;;

    endpoints)
        print_integration_endpoints
        ;;

    help|*
        print_help
        ;;
esac

# If no arguments provided, show help
if [ $# -eq 0 ]; then
    print_help
fi