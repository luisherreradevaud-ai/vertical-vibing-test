# General Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production"
  }
}

# SES Configuration
variable "domain" {
  description = "The domain to configure for SES"
  type        = string
}

variable "mail_from_domain" {
  description = "The custom MAIL FROM domain (e.g., mail.example.com)"
  type        = string
  default     = null
}

variable "default_from_email" {
  description = "Default FROM email address for sending emails"
  type        = string
}

variable "create_route53_records" {
  description = "Whether to automatically create Route53 DNS records"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (required if create_route53_records is true)"
  type        = string
  default     = null
}

variable "bounce_complaint_sns_topic_arn" {
  description = "SNS topic ARN for bounce and complaint notifications"
  type        = string
  default     = null
}

# Lambda Configuration
variable "lambda_deployment_package_path" {
  description = "Path to the Lambda deployment package (ZIP file)"
  type        = string
}

variable "lambda_source_code_hash" {
  description = "Base64-encoded hash of the Lambda deployment package"
  type        = string
  default     = null
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "dist/lambda/email-queue-processor.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "enable_lambda_vpc_access" {
  description = "Whether Lambda needs VPC access (for database in VPC)"
  type        = bool
  default     = false
}

variable "lambda_vpc_config" {
  description = "VPC configuration for Lambda (required if enable_lambda_vpc_access is true)"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "lambda_dlq_arn" {
  description = "ARN of SQS queue for Lambda's dead letter queue"
  type        = string
  default     = null
}

variable "additional_lambda_env_vars" {
  description = "Additional environment variables for Lambda"
  type        = map(string)
  default     = {}
}

# Database Configuration
variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

# Encryption Configuration
variable "kms_key_id" {
  description = "KMS key ID for SQS encryption (uses AWS managed key if not specified)"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for IAM policies (required if kms_key_id is specified)"
  type        = string
  default     = null
}

# Secrets Manager Configuration
variable "enable_secrets_manager_access" {
  description = "Whether to enable Secrets Manager access for Lambda"
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager secret ARNs"
  type        = list(string)
  default     = []
}

# Backend Role Configuration
variable "create_backend_role" {
  description = "Whether to create IAM role for backend to send SQS messages"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 14
}

variable "log_level" {
  description = "Log level for Lambda function (debug, info, warn, error)"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be debug, info, warn, or error"
  }
}

# Tags
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
