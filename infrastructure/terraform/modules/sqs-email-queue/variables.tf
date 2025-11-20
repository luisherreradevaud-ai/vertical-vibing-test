variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "fifo_queue" {
  description = "Whether this is a FIFO queue"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue (should be 6x Lambda timeout)"
  type        = number
  default     = 300 # 5 minutes
}

variable "message_retention_seconds" {
  description = "The number of seconds to retain messages"
  type        = number
  default     = 1209600 # 14 days
}

variable "max_message_size" {
  description = "The maximum message size in bytes"
  type        = number
  default     = 262144 # 256 KB
}

variable "delay_seconds" {
  description = "The time in seconds for which messages are delayed"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "The time in seconds for which a ReceiveMessage call will wait (long polling)"
  type        = number
  default     = 20
}

variable "max_receive_count" {
  description = "The maximum number of times a message can be received before being sent to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "Message retention for the Dead Letter Queue"
  type        = number
  default     = 1209600 # 14 days
}

variable "enable_encryption" {
  description = "Enable server-side encryption for the queue"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for SQS encryption. If not specified, uses AWS managed key"
  type        = string
  default     = null
}

variable "allow_ses_send" {
  description = "Whether to allow SES to send messages to this queue"
  type        = bool
  default     = false
}

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for queue monitoring"
  type        = bool
  default     = true
}

variable "dlq_alarm_threshold" {
  description = "Number of messages in DLQ before triggering alarm"
  type        = number
  default     = 1
}

variable "message_age_threshold" {
  description = "Maximum age of oldest message in seconds before alarm"
  type        = number
  default     = 3600 # 1 hour
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
