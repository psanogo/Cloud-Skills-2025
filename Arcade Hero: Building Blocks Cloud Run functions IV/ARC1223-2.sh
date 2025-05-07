#!/bin/bash

# Define colors
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"

echo -e "${GREEN}${BOLD}Starting Cloud Run Function Deployment (cf-pubsub)...${RESET}"

# Step 1: Set Variables
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
FUNCTION_NAME="cf-pubsub"
RUNTIME="nodejs20"
SERVICE_ACCOUNT_NAME="Cloud Run functions demo account"
TOPIC_NAME="cf-pubsub"
MAX_INSTANCES=5

# Step 2: Get service account email
SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:${SERVICE_ACCOUNT_NAME}" \
  --format="value(email)")

if [[ -z "$SERVICE_ACCOUNT_EMAIL" ]]; then
  echo -e "${RED}${BOLD}Error: Service account with display name '${SERVICE_ACCOUNT_NAME}' not found.${RESET}"
  exit 1
fi

# Step 3: Create function source code
echo -e "${CYAN}Creating Node.js function code...${RESET}"
mkdir -p pubsub-function
cat > pubsub-function/index.js <<EOF
exports.helloPubSub = (event, context) => {
  const message = Buffer.from(event.data, 'base64').toString();
  console.log(\`Received message: \${message}\`);
};
EOF

cat > pubsub-function/package.json <<EOF
{
  "name": "cf-pubsub",
  "version": "1.0.0",
  "main": "index.js"
}
EOF

# Step 4: Deploy the Cloud Function (2nd Gen) with Pub/Sub trigger
echo -e "${YELLOW}${BOLD}Deploying function '${FUNCTION_NAME}' in region '${REGION}'...${RESET}"

gcloud functions deploy "$FUNCTION_NAME" \
  --gen2 \
  --runtime="$RUNTIME" \
  --region="$REGION" \
  --source=pubsub-function \
  --entry-point=helloPubSub \
  --trigger-topic="$TOPIC_NAME" \
  --max-instances="$MAX_INSTANCES" \
  --service-account="$SERVICE_ACCOUNT_EMAIL"

# Success message
echo -e "${GREEN}${BOLD}✅ Function '${FUNCTION_NAME}' deployed successfully!${RESET}"
