#!/bin/bash

# Deploy infrastructure changes for an environment

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./infrastructure/scripts/infra-deploy.sh <environment>"
  echo "Example: ./infrastructure/scripts/infra-deploy.sh dev"
  echo ""
  echo "Available environments: dev, staging, production"
  exit 1
fi

# Safety check for production
if [ "$ENVIRONMENT" = "production" ]; then
  echo "⚠️  WARNING: You are about to deploy to PRODUCTION"
  echo ""
  read -p "Are you absolutely sure? (type 'DEPLOY PRODUCTION' to confirm): " CONFIRM

  if [ "$CONFIRM" != "DEPLOY PRODUCTION" ]; then
    echo "Deployment cancelled."
    exit 0
  fi
fi

ENV_DIR="infrastructure/terraform/environments/$ENVIRONMENT"

if [ ! -d "$ENV_DIR" ]; then
  echo "Error: Environment '$ENVIRONMENT' not found at $ENV_DIR"
  exit 1
fi

echo "🚀 Deploying infrastructure to: $ENVIRONMENT"
echo ""

cd "$ENV_DIR"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✓ Validating Terraform configuration..."
terraform validate

# Apply changes
echo "🔧 Applying changes..."
terraform apply

# Export outputs
echo "📤 Exporting infrastructure outputs..."
terraform output -json > outputs.json

cd - > /dev/null

echo ""
echo "✓ Infrastructure deployed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Copy infrastructure outputs to backend .env:"
echo "     File: $ENV_DIR/outputs.json"
echo ""
echo "  2. Update backend environment variables:"
echo "     cd repos/backend"
echo "     # Update .env with values from outputs.json"
echo ""
echo "  3. Restart backend server:"
echo "     npm run dev"
