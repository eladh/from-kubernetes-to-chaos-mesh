#!/bin/bash

########################
# Banner functions
########################

function print_header() {
  echo "======================================================================"
  echo "  $1"
  echo "======================================================================"
}

function print_step() {
  echo ""
  echo "----------------------------------------------------------------------"
  echo "  $1"
  echo "----------------------------------------------------------------------"
}

# Load API key and endpoint from .env file
if [ -f ../.env ]; then
  source ../.env
else
  echo "Error: .env file not found. Please create one with AZURE_API_KEY and AZURE_ENDPOINT"
  exit 1
fi

# Check if required environment variables are available
if [ -z "$AZURE_API_KEY" ]; then
  echo "Error: AZURE_API_KEY not set in .env file"
  exit 1
fi

if [ -z "$AZURE_ENDPOINT" ]; then
  echo "Error: AZURE_ENDPOINT not set in .env file"
  exit 1
fi

# Capture Pixie data in variables instead of writing to file
print_step "Collecting service_stats data..."
SERVICE_STATS=$(px run px/service_stats -- -start_time="-30s")

print_step "Collecting service_edge_stats data..."
SERVICE_EDGE_STATS=$(px run px/service_edge_stats)

print_step "Collecting http_data..."
HTTP_DATA=$(px run px/http_data -- -start_time="-30s" | head -20)

print_step "Collecting net_flow_graph data..."
NET_FLOW_GRAPH=$(px run px/net_flow_graph -- -namespace="microservices-demo")

# Combine all data
ALL_DATA=$(cat <<EOF
SERVICE STATS:
$SERVICE_STATS

SERVICE EDGE STATS:
$SERVICE_EDGE_STATS

HTTP DATA:
$HTTP_DATA

NET FLOW GRAPH:
$NET_FLOW_GRAPH
EOF
)

print_step "Sending data to AI for analysis..."

# Prepare the content properly escaped
ESCAPED_DATA=$(echo "$ALL_DATA" | perl -pe 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g;')

# Create JSON payload
JSON_PAYLOAD='{
    "messages": [
        {
            "role": "system",
            "content": "You are an expert observability system analyst. Your task is to diagnose performance issues in microservices architectures using telemetry data."
        },
        {
            "role": "user",
            "content": "Analyze why a 250ms artificial delay in microservices-demo/frontend results in much higher UI latency. Be short and prcicese how we got the total delay ?.\n\n'"$ESCAPED_DATA"'"
        }
    ],
    "max_completion_tokens": 1000,
    "temperature": 0.8,
    "top_p": 1,
    "frequency_penalty": 0,
    "presence_penalty": 0,
    "model": "gpt-4.1"
}'

print_step "AI Analysis Results"

# Make the API call and format the output nicely
RESPONSE=$(curl -s -X POST "$AZURE_ENDPOINT/openai/deployments/gpt-4.1/chat/completions?api-version=2025-01-01-preview" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AZURE_API_KEY" \
    -d "$JSON_PAYLOAD")

# Extract and print just the content part using jq if it's available
if command -v jq &> /dev/null; then
    echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || echo "$RESPONSE"
else
    # Simple extraction using grep and sed if jq is not available
    echo "$RESPONSE" | grep -o '"content":"[^"]*"' | sed 's/"content":"//g' | sed 's/"$//g' | sed 's/\\n/\n/g' || echo "$RESPONSE"
fi