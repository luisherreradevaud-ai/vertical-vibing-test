terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution" {
  name        = "${var.resource_prefix}-email-lambda-execution"
  description = "IAM role for email Lambda function execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-email-lambda-execution"
      ManagedBy = "terraform"
    }
  )
}

# Lambda Basic Execution Policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC Execution Policy (if using VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count = var.enable_vpc_access ? 1 : 0

  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# SES Send Email Policy
resource "aws_iam_policy" "ses_send_email" {
  name        = "${var.resource_prefix}-ses-send-email"
  description = "Allow sending emails via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail"
        ]
        Resource = var.ses_identity_arns
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-ses-send-email"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_ses_send" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.ses_send_email.arn
}

# SQS Queue Access Policy
resource "aws_iam_policy" "sqs_access" {
  name        = "${var.resource_prefix}-sqs-email-queue-access"
  description = "Allow Lambda to read from email SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.queue_arns
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-sqs-email-queue-access"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

# KMS Decrypt Policy (for encrypted queues/secrets)
resource "aws_iam_policy" "kms_decrypt" {
  count = var.enable_kms_access ? 1 : 0

  name        = "${var.resource_prefix}-kms-decrypt"
  description = "Allow decrypting SQS messages and secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arns
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-kms-decrypt"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_kms_decrypt" {
  count = var.enable_kms_access ? 1 : 0

  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.kms_decrypt[0].arn
}

# Secrets Manager Access (for database credentials)
resource "aws_iam_policy" "secrets_manager" {
  count = var.enable_secrets_manager_access ? 1 : 0

  name        = "${var.resource_prefix}-secrets-manager-access"
  description = "Allow reading database credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_manager_arns
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-secrets-manager-access"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_manager" {
  count = var.enable_secrets_manager_access ? 1 : 0

  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.secrets_manager[0].arn
}

# Backend/API Role for SQS Send
resource "aws_iam_role" "backend_sqs_sender" {
  count = var.create_backend_role ? 1 : 0

  name        = "${var.resource_prefix}-backend-sqs-sender"
  description = "IAM role for backend to send messages to email queue"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-backend-sqs-sender"
      ManagedBy = "terraform"
    }
  )
}

# Backend SQS Send Policy
resource "aws_iam_policy" "backend_sqs_send" {
  count = var.create_backend_role ? 1 : 0

  name        = "${var.resource_prefix}-backend-sqs-send"
  description = "Allow backend to send messages to email queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.queue_arns
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name      = "${var.resource_prefix}-backend-sqs-send"
      ManagedBy = "terraform"
    }
  )
}

resource "aws_iam_role_policy_attachment" "backend_sqs_send" {
  count = var.create_backend_role ? 1 : 0

  role       = aws_iam_role.backend_sqs_sender[0].name
  policy_arn = aws_iam_policy.backend_sqs_send[0].arn
}
