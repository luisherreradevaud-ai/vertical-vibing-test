# SES Outputs
output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = module.ses_domain.domain_identity_arn
}

output "ses_domain_verification_token" {
  description = "Domain verification token (for manual DNS setup)"
  value       = module.ses_domain.domain_identity_verification_token
}

output "ses_dkim_tokens" {
  description = "DKIM tokens (for manual DNS setup)"
  value       = module.ses_domain.dkim_tokens
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = module.ses_domain.configuration_set_name
}

output "ses_dns_records" {
  description = "DNS records to create manually (if not using Route53)"
  value       = module.ses_domain.dns_records
}

# SQS Outputs
output "email_queue_url" {
  description = "URL of the email processing queue"
  value       = module.email_queue.queue_id
}

output "email_queue_arn" {
  description = "ARN of the email processing queue"
  value       = module.email_queue.queue_arn
}

output "email_dlq_url" {
  description = "URL of the email dead letter queue"
  value       = module.email_queue.dlq_id
}

output "email_dlq_arn" {
  description = "ARN of the email dead letter queue"
  value       = module.email_queue.dlq_arn
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the email processor Lambda function"
  value       = module.email_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the email processor Lambda function"
  value       = module.email_lambda.function_arn
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch Log Group"
  value       = module.email_lambda.log_group_name
}

# IAM Outputs
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.email_iam.lambda_execution_role_arn
}

output "backend_sqs_sender_role_arn" {
  description = "ARN of the backend SQS sender role (if created)"
  value       = module.email_iam.backend_sqs_sender_role_arn
}

# Summary Output
output "deployment_summary" {
  description = "Summary of email infrastructure deployment"
  value = {
    environment           = var.environment
    domain                = var.domain
    queue_url             = module.email_queue.queue_id
    lambda_function       = module.email_lambda.function_name
    configuration_set     = module.ses_domain.configuration_set_name
    requires_dns_setup    = !var.create_route53_records
  }
}
