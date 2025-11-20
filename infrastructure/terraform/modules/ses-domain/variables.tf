variable "domain" {
  description = "The domain to configure for SES"
  type        = string
}

variable "mail_from_domain" {
  description = "The custom MAIL FROM domain (e.g., mail.example.com). Set to null to use amazonses.com"
  type        = string
  default     = null
}

variable "create_route53_records" {
  description = "Whether to create Route53 DNS records for verification and DKIM"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "The Route53 hosted zone ID for creating DNS records. Required if create_route53_records is true"
  type        = string
  default     = null
}

variable "create_configuration_set" {
  description = "Whether to create an SES configuration set"
  type        = bool
  default     = true
}

variable "configuration_set_name" {
  description = "Name for the SES configuration set"
  type        = string
  default     = "email-system"
}

variable "bounce_complaint_topic_arn" {
  description = "SNS topic ARN for bounce and complaint notifications. Set to null to disable"
  type        = string
  default     = null
}

variable "enable_cloudwatch_events" {
  description = "Whether to enable CloudWatch event destination for send/delivery/reject events"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
