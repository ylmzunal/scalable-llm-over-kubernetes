#!/bin/bash

# Comprehensive Scaling Monitoring Script
# Monitors HPA, pods, and resource usage during load test

NAMESPACE="llm-tinyllama-cluster"
LOG_DIR="scaling_monitor_logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create log directory
mkdir -p "$LOG_DIR"

# Output files
HPA_LOG="$LOG_DIR/hpa_monitor_$TIMESTAMP.log"
PODS_LOG="$LOG_DIR/pods_monitor_$TIMESTAMP.log" 
METRICS_LOG="$LOG_DIR/metrics_$TIMESTAMP.log"
SUMMARY_LOG="$LOG_DIR/summary_$TIMESTAMP.log"

echo "🎯 Starting Comprehensive Scaling Monitor"
echo "Namespace: $NAMESPACE"
echo "Logs will be saved to: $LOG_DIR"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to log with timestamp
log_with_timestamp() {
    echo "$(date '+%H:%M:%S') - $1"
}

# Function to monitor HPA
monitor_hpa() {
    while true; do
        {
            echo "=== HPA STATUS $(date '+%H:%M:%S') ==="
            kubectl get hpa -n "$NAMESPACE" --no-headers || echo "HPA not found"
            echo ""
        } >> "$HPA_LOG"
        sleep 10
    done
}

# Function to monitor pods
monitor_pods() {
    while true; do
        {
            echo "=== PODS STATUS $(date '+%H:%M:%S') ==="
            kubectl get pods -n "$NAMESPACE" -l app=llm-chatbot-backend-tinyllama --no-headers
            echo ""
        } >> "$PODS_LOG"
        sleep 15
    done
}

# Function to collect detailed metrics
collect_metrics() {
    while true; do
        {
            echo "=== DETAILED METRICS $(date '+%H:%M:%S') ==="
            
            # Pod count
            POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app=llm-chatbot-backend-tinyllama --no-headers | grep "Running" | wc -l)
            echo "Running Pods: $POD_COUNT"
            
            # HPA metrics
            HPA_OUTPUT=$(kubectl get hpa -n "$NAMESPACE" --no-headers 2>/dev/null)
            if [[ -n "$HPA_OUTPUT" ]]; then
                echo "HPA: $HPA_OUTPUT"
                
                # Extract CPU and memory percentages
                CPU_PERCENT=$(echo "$HPA_OUTPUT" | grep -o 'cpu: [0-9]*%' | grep -o '[0-9]*' || echo "0")
                MEMORY_PERCENT=$(echo "$HPA_OUTPUT" | grep -o 'memory: [0-9]*%' | grep -o '[0-9]*' || echo "0")
                
                echo "CPU Usage: ${CPU_PERCENT}%"
                echo "Memory Usage: ${MEMORY_PERCENT}%"
            else
                echo "HPA: Not found"
            fi
            
            # Top pods (if metrics server is available)
            echo "--- Resource Usage ---"
            kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "Metrics not available"
            
            echo "--- HPA Description ---"
            kubectl describe hpa -n "$NAMESPACE" 2>/dev/null | grep -A 10 "Events:" || echo "No HPA events"
            
            echo "================================"
            echo ""
        } >> "$METRICS_LOG"
        sleep 20
    done
}

# Function to provide real-time summary
show_summary() {
    while true; do
        clear
        echo "🔥 REAL-TIME SCALING MONITOR"
        echo "============================"
        echo "Time: $(date)"
        echo ""
        
        # Current pod count
        POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app=llm-chatbot-backend-tinyllama --no-headers | grep "Running" | wc -l)
        echo "📊 Current Running Pods: $POD_COUNT"
        
        # HPA status
        echo "🎯 HPA Status:"
        kubectl get hpa -n "$NAMESPACE" 2>/dev/null || echo "  HPA not found"
        
        echo ""
        echo "📈 Recent Pod Events:"
        kubectl get events -n "$NAMESPACE" --sort-by='.firstTimestamp' | grep -E "(pod|hpa)" | tail -5
        
        echo ""
        echo "💡 Log files being written to: $LOG_DIR"
        echo "   Press Ctrl+C to stop monitoring"
        
        sleep 30
    done
}

# Trap Ctrl+C to clean up
cleanup() {
    echo ""
    log_with_timestamp "Stopping monitoring..."
    
    # Kill background processes
    jobs -p | xargs kill 2>/dev/null
    
    # Generate final summary
    {
        echo "=== FINAL SUMMARY $(date) ==="
        echo "Total monitoring duration: Started at $TIMESTAMP"
        echo ""
        echo "Final pod count:"
        kubectl get pods -n "$NAMESPACE" -l app=llm-chatbot-backend-tinyllama --no-headers
        echo ""
        echo "Final HPA status:"
        kubectl get hpa -n "$NAMESPACE" 2>/dev/null || echo "HPA not found"
        echo ""
        echo "Recent scaling events:"
        kubectl get events -n "$NAMESPACE" --sort-by='.firstTimestamp' | grep -E "(pod|hpa)" | tail -10
    } >> "$SUMMARY_LOG"
    
    echo "✅ Monitoring complete. Logs saved to $LOG_DIR"
    exit 0
}

trap cleanup SIGINT

# Start monitoring functions in background
monitor_hpa &
monitor_pods &
collect_metrics &

# Show real-time summary in foreground
show_summary 