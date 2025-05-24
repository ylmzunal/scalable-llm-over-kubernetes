#!/bin/sh

# Docker entrypoint script for React frontend
# This script injects environment variables at runtime

set -e

# Define the configuration template
CONFIG_TEMPLATE='window._env_ = {
  REACT_APP_API_URL: "{{API_URL}}",
  REACT_APP_WS_URL: "{{WS_URL}}",
  REACT_APP_ENVIRONMENT: "{{ENVIRONMENT}}"
};'

# Get environment variables with defaults
API_URL=${REACT_APP_API_URL:-"/api"}
WS_URL=${REACT_APP_WS_URL:-""}
ENVIRONMENT=${REACT_APP_ENVIRONMENT:-"production"}

# Auto-detect WebSocket URL if not provided
if [ -z "$WS_URL" ]; then
    WS_URL="ws://${HTTP_HOST:-localhost}/ws"
fi

echo "🚀 Configuring frontend with:"
echo "  API_URL: $API_URL"
echo "  WS_URL: $WS_URL"
echo "  ENVIRONMENT: $ENVIRONMENT"

# Replace placeholders in the configuration template
CONFIG_JS=$(echo "$CONFIG_TEMPLATE" | \
    sed "s|{{API_URL}}|$API_URL|g" | \
    sed "s|{{WS_URL}}|$WS_URL|g" | \
    sed "s|{{ENVIRONMENT}}|$ENVIRONMENT|g")

# Write the configuration to a JavaScript file
echo "$CONFIG_JS" > /usr/share/nginx/html/config.js

# Create a simple health check page
cat > /usr/share/nginx/html/health << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Health Check</title></head>
<body>
<h1>Frontend Health: OK</h1>
<p>Environment: $ENVIRONMENT</p>
<p>API URL: $API_URL</p>
<p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Replace variables in health check
sed -i "s|\$ENVIRONMENT|$ENVIRONMENT|g" /usr/share/nginx/html/health
sed -i "s|\$API_URL|$API_URL|g" /usr/share/nginx/html/health
sed -i "s|\$(date)|$(date)|g" /usr/share/nginx/html/health

echo "✅ Frontend configuration complete"

# Execute the command passed to the script
exec "$@" 