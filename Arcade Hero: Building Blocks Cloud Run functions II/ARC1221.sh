#!/bin/bash

# Colors for output formatting
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
BLUE="\033[34m"

echo -e "${GREEN}${BOLD}Starting Execution${RESET}"

# Step 1: Set environment variables
echo -e "${CYAN}${BOLD}Setting environment variables...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export REGION="us-west1"
export FUNCTION_NAME="cf-pubsub"
export TOPIC_NAME="cf-pubsub"

# Step 2: Create Pub/Sub topic if not exists
echo -e "${YELLOW}${BOLD}Ensuring Pub/Sub topic exists...${RESET}"
gcloud pubsub topics create $TOPIC_NAME --quiet || true

# Step 3: Create sample Go function
echo -e "${YELLOW}${BOLD}Creating sample Go function...${RESET}"
mkdir -p cloud-function
cat > cloud-function/main.go <<EOF
package main

import (
	"context"
	"encoding/json"
	"log"
)

type PubSubMessage struct {
	Data []byte \`json:"data"\`
}

func HelloPubSub(ctx context.Context, m PubSubMessage) error {
	log.Printf("Hello from Pub/Sub! Message: %s", string(m.Data))
	return nil
}
EOF

cat > cloud-function/go.mod <<EOF
module example.com/hello

go 1.20
EOF

# Step 4: Deploy Cloud Function (2nd Gen) with Pub/Sub trigger
echo -e "${BLUE}${BOLD}Deploying Cloud Function: ${FUNCTION_NAME}...${RESET}"
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=go120 \
  --region=$REGION \
  --source=cloud-function \
  --entry-point=HelloPubSub \
  --trigger-topic=$TOPIC_NAME \
  --max-instances=5 \
  --service-account="Cloud Run functions demo account" \
  --quiet

echo -e "${GREEN}${BOLD}Deployment complete!${RESET}"

# Congratulatory message
MESSAGES=(
  "${GREEN}Great! Cloud Function with Pub/Sub trigger deployed successfully!${RESET}"
  "${CYAN}Awesome job! Your Go-based Pub/Sub function is live!${RESET}"
  "${YELLOW}Well done! You've deployed using 2nd Gen Cloud Functions!${RESET}"
)
RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"

echo -e "\n"
