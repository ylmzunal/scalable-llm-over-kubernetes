#!/bin/bash

# Manual Load Testing Script - Safe for Ollama
# Sends requests sequentially to avoid overloading the AI model

echo "🧪 Manual Load Testing - Safe Mode"
echo "=================================="

BASE_URL="http://localhost:8000"
CONVERSATION_ID="manual-test-$(date +%s)"

# Test messages
MESSAGES=(
    "Hello, how are you?"
    "What is Kubernetes?"
    "How does auto-scaling work?"
    "Tell me about containers"
    "What is Docker?"
)

# Function to test health
test_health() {
    echo "🔍 Testing health endpoint..."
    response=$(curl -s "$BASE_URL/health" | jq -r '.status')
    if [ "$response" = "healthy" ]; then
        echo "✅ Backend is healthy"
    else
        echo "❌ Backend is not healthy"
        exit 1
    fi
}

# Function to send chat message
send_message() {
    local message="$1"
    local msg_num="$2"
    
    echo ""
    echo "📤 Message $msg_num: $message"
    echo "⏱️  Sending request..."
    
    start_time=$(date +%s)
    response=$(curl -s -X POST "$BASE_URL/chat" \
        -H "Content-Type: application/json" \
        -d "{\"message\": \"$message\", \"conversation_id\": \"$CONVERSATION_ID\"}")
    end_time=$(date +%s)
    
    duration=$((end_time - start_time))
    
    if [ $? -eq 0 ]; then
        echo "✅ Response received in ${duration}s"
        echo "🤖 AI Response: $(echo "$response" | jq -r '.response' | head -1)"
        echo "---"
    else
        echo "❌ Request failed"
        return 1
    fi
}

# Function for sequential testing
sequential_test() {
    echo ""
    echo "🔄 Starting Sequential Test (Safe Mode)"
    echo "This sends one request at a time with delays"
    echo ""
    
    for i in "${!MESSAGES[@]}"; do
        send_message "${MESSAGES[$i]}" "$((i+1))"
        echo "⏳ Waiting 3 seconds before next request..."
        sleep 3
    done
}

# Function for light load test
light_load_test() {
    echo ""
    echo "🔄 Starting Light Load Test"
    echo "This sends requests with short delays"
    echo ""
    
    for round in {1..3}; do
        echo "📋 Round $round/3"
        for i in "${!MESSAGES[@]}"; do
            send_message "${MESSAGES[$i]}" "$((i+1))"
            sleep 2
        done
        echo "⏳ Round complete, waiting 5 seconds..."
        sleep 5
    done
}

# Function to monitor scaling
monitor_scaling() {
    echo ""
    echo "🔍 Monitoring Kubernetes Scaling"
    echo "Pod count and HPA status:"
    
    kubectl get pods -l app=llm-chatbot --no-headers | wc -l | awk '{print "Current pods: " $1}'
    kubectl get hpa llm-chatbot-hpa --no-headers 2>/dev/null | awk '{print "HPA targets: " $4}' || echo "HPA not found"
}

# Main menu
show_menu() {
    echo ""
    echo "Choose a test type:"
    echo "1) Health Check Only"
    echo "2) Single Message Test"
    echo "3) Sequential Test (5 messages, safe)"
    echo "4) Light Load Test (3 rounds)"
    echo "5) Monitor Scaling Status"
    echo "6) Exit"
    echo ""
    read -p "Enter choice (1-6): " choice
}

# Main loop
main() {
    test_health
    
    while true; do
        show_menu
        
        case $choice in
            1)
                test_health
                ;;
            2)
                read -p "Enter your message: " custom_message
                send_message "$custom_message" "1"
                ;;
            3)
                sequential_test
                ;;
            4)
                light_load_test
                ;;
            5)
                monitor_scaling
                ;;
            6)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid choice"
                ;;
        esac
    done
}

# Run main function
main 