#!/bin/bash

# Plan infrastructure changes for an environment

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./infrastructure/scripts/infra-plan.sh <environment>"
  echo "Example: ./infrastructure/scripts/infra-plan.sh dev"
  echo ""
  echo "Available environments: dev, staging, production"
  exit 1
fi

ENV_DIR="infrastructure/terraform/environments/$ENVIRONMENT"

if [ ! -d "$ENV_DIR" ]; then
  echo "Error: Environment '$ENVIRONMENT' not found at $ENV_DIR"
  exit 1
fi

echo "🔍 Planning infrastructure changes for: $ENVIRONMENT"
echo ""

cd "$ENV_DIR"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✓ Validating Terraform configuration..."
terraform validate

# Plan changes
echo "📋 Planning changes..."
terraform plan

cd - > /dev/null

echo ""
echo "✓ Plan complete!"
echo ""
echo "To apply these changes, run:"
echo "  ./infrastructure/scripts/infra-deploy.sh $ENVIRONMENT"
