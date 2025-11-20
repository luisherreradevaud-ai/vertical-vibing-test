variable "resource_prefix" {
  description = "Prefix for resource names (e.g., myapp-prod)"
  type        = string
}

variable "ses_identity_arns" {
  description = "List of SES identity ARNs (domains/emails) allowed to send from"
  type        = list(string)
}

variable "queue_arns" {
  description = "List of SQS queue ARNs for email processing"
  type        = list(string)
}

variable "enable_vpc_access" {
  description = "Whether Lambda needs VPC access (for database in VPC)"
  type        = bool
  default     = false
}

variable "enable_kms_access" {
  description = "Whether to enable KMS decryption access"
  type        = bool
  default     = false
}

variable "kms_key_arns" {
  description = "List of KMS key ARNs for decryption"
  type        = list(string)
  default     = []
}

variable "enable_secrets_manager_access" {
  description = "Whether to enable Secrets Manager access"
  type        = bool
  default     = false
}

variable "secrets_manager_arns" {
  description = "List of Secrets Manager secret ARNs"
  type        = list(string)
  default     = []
}

variable "create_backend_role" {
  description = "Whether to create IAM role for backend to send SQS messages"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
