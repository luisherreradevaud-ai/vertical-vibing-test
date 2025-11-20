#!/bin/bash

# Destroy infrastructure for an environment
# USE WITH EXTREME CAUTION

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./infrastructure/scripts/infra-destroy.sh <environment>"
  echo "Example: ./infrastructure/scripts/infra-destroy.sh dev"
  exit 1
fi

# Block production destruction via script
if [ "$ENVIRONMENT" = "production" ]; then
  echo "❌ ERROR: Cannot destroy production infrastructure via script"
  echo ""
  echo "For production infrastructure destruction:"
  echo "  1. Use Terraform Cloud/Enterprise UI"
  echo "  2. Or manually navigate to infrastructure/terraform/environments/production/"
  echo "  3. Obtain approval from team lead"
  echo "  4. Run terraform destroy manually"
  exit 1
fi

ENV_DIR="infrastructure/terraform/environments/$ENVIRONMENT"

if [ ! -d "$ENV_DIR" ]; then
  echo "Error: Environment '$ENVIRONMENT' not found at $ENV_DIR"
  exit 1
fi

echo "⚠️  WARNING: This will DESTROY all infrastructure in $ENVIRONMENT"
echo ""
echo "This includes:"
echo "  - S3 buckets and all files"
echo "  - Lambda functions"
echo "  - CloudFront distributions"
echo "  - ALL resources defined in Terraform"
echo ""
read -p "Are you sure? (type 'DESTROY $ENVIRONMENT' to confirm): " CONFIRM

if [ "$CONFIRM" != "DESTROY $ENVIRONMENT" ]; then
  echo "Destruction cancelled."
  exit 0
fi

echo ""
echo "🗑️  Destroying infrastructure in: $ENVIRONMENT"
echo ""

cd "$ENV_DIR"

terraform destroy

cd - > /dev/null

echo ""
echo "✓ Infrastructure destroyed"
