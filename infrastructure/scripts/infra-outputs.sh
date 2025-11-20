#!/bin/bash

# View infrastructure outputs for an environment

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./infrastructure/scripts/infra-outputs.sh <environment>"
  echo "Example: ./infrastructure/scripts/infra-outputs.sh dev"
  echo ""
  echo "Available environments: dev, staging, production"
  exit 1
fi

ENV_DIR="infrastructure/terraform/environments/$ENVIRONMENT"

if [ ! -d "$ENV_DIR" ]; then
  echo "Error: Environment '$ENVIRONMENT' not found at $ENV_DIR"
  exit 1
fi

echo "📋 Infrastructure outputs for: $ENVIRONMENT"
echo ""

cd "$ENV_DIR"

if [ ! -f "terraform.tfstate" ]; then
  echo "No infrastructure deployed yet for $ENVIRONMENT"
  echo "Run: ./infrastructure/scripts/infra-deploy.sh $ENVIRONMENT"
  exit 1
fi

terraform output

cd - > /dev/null
