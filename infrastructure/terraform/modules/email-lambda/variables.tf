variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "deployment_package_path" {
  description = "Path to the deployment package (ZIP file)"
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded hash of the deployment package"
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "dist/lambda/email-queue-processor.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "ses_region" {
  description = "AWS region for SES"
  type        = string
}

variable "ses_from_email" {
  description = "Default FROM email address"
  type        = string
}

variable "ses_configuration_set" {
  description = "SES configuration set name"
  type        = string
  default     = null
}

variable "queue_url" {
  description = "SQS queue URL for email processing"
  type        = string
}

variable "queue_arn" {
  description = "SQS queue ARN for event source mapping"
  type        = string
}

variable "log_level" {
  description = "Log level (debug, info, warn, error)"
  type        = string
  default     = "info"
}

variable "additional_environment_variables" {
  description = "Additional environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for Lambda (required for database access in VPC)"
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

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for the Lambda function. -1 for unreserved"
  type        = number
  default     = -1
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 14
}

variable "enable_sqs_trigger" {
  description = "Whether to enable SQS event source mapping"
  type        = bool
  default     = true
}

variable "batch_size" {
  description = "Maximum number of messages to retrieve per batch"
  type        = number
  default     = 10
}

variable "maximum_batching_window_in_seconds" {
  description = "Maximum amount of time to gather records before invoking the function"
  type        = number
  default     = 5
}

variable "maximum_concurrency" {
  description = "Maximum concurrent Lambda invocations"
  type        = number
  default     = 10
}

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms"
  type        = bool
  default     = true
}

variable "error_alarm_threshold" {
  description = "Number of errors before triggering alarm"
  type        = number
  default     = 5
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
