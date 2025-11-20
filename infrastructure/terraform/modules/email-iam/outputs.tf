output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

output "backend_sqs_sender_role_arn" {
  description = "ARN of the backend SQS sender role (if created)"
  value       = var.create_backend_role ? aws_iam_role.backend_sqs_sender[0].arn : null
}

output "backend_sqs_sender_role_name" {
  description = "Name of the backend SQS sender role (if created)"
  value       = var.create_backend_role ? aws_iam_role.backend_sqs_sender[0].name : null
}
