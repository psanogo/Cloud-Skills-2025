#!/bin/bash

set -e

# Enable required services
gcloud services enable \
    container.googleapis.com \
    clouddeploy.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com

# Create GKE clusters
gcloud container clusters create test --node-locations=$ZONE --num-nodes=1 --async
gcloud container clusters create staging --node-locations=$ZONE --num-nodes=1 --async
gcloud container clusters create prod --node-locations=$ZONE --num-nodes=1 --async

# Create Artifact Registry repository
gcloud artifacts repositories create web-app \
    --description="Image registry for tutorial web app" \
    --repository-format=docker \
    --location=$REGION

# Clone tutorial repo and check out specific commit
cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

# Prepare Skaffold config
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
cat web/skaffold.yaml

# Build with Skaffold
cd web
skaffold build --interactive=false \
    --default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
    --file-output artifacts.json
cd ..

# List Docker images
gcloud artifacts docker images list \
    $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
    --include-tags \
    --format yaml

# Set deploy region and apply pipeline config
gcloud config set deploy/region $REGION
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml

# Describe delivery pipeline
gcloud beta deploy delivery-pipelines describe web-app

# Set up Kubernetes contexts
CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

# Create namespace in each cluster
for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

# Apply deploy targets
for CONTEXT in ${CONTEXTS[@]}
do
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

# List deploy targets
gcloud beta deploy targets list

# Create release
gcloud beta deploy releases create web-app-001 \
    --delivery-pipeline web-app \
    --build-artifacts web/artifacts.json \
    --source web/

# List rollout
gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release web-app-001

# Validate on test
kubectx test
kubectl get all -n web-app

# Promote to staging
gcloud beta deploy releases promote \
    --delivery-pipeline web-app \
    --release web-app-001

# Validate on staging
gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release web-app-001

# Promote to prod
gcloud beta deploy releases promote \
    --delivery-pipeline web-app \
    --release web-app-001

# Approve prod rollout
gcloud beta deploy rollouts approve web-app-001-to-prod-0001 \
    --delivery-pipeline web-app \
    --release web-app-001

# Final rollout validation
gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release web-app-001

kubectx prod
kubectl get all -n web-app
