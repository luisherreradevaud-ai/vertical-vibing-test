terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Lambda Function
resource "aws_lambda_function" "email_processor" {
  function_name = var.function_name
  description   = "Processes email queue messages and sends emails via SES"

  # Deployment package
  filename         = var.deployment_package_path
  source_code_hash = var.source_code_hash
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  # IAM Role
  role = var.execution_role_arn

  # Environment variables
  environment {
    variables = merge(
      {
        NODE_ENV                  = var.environment
        DATABASE_URL              = var.database_url
        SES_REGION                = var.ses_region
        SES_FROM_EMAIL            = var.ses_from_email
        SES_CONFIGURATION_SET     = var.ses_configuration_set
        EMAIL_QUEUE_URL           = var.queue_url
        LOG_LEVEL                 = var.log_level
      },
      var.additional_environment_variables
    )
  }

  # VPC Configuration (if needed for database access)
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead letter queue for Lambda failures
  dynamic "dead_letter_config" {
    for_each = var.lambda_dlq_arn != null ? [1] : []

    content {
      target_arn = var.lambda_dlq_arn
    }
  }

  # Reserved concurrent executions
  reserved_concurrent_executions = var.reserved_concurrent_executions

  tags = merge(
    var.tags,
    {
      Name      = var.function_name
      ManagedBy = "terraform"
      Purpose   = "Email Queue Processing"
    }
  )
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name      = "${var.function_name}-logs"
      ManagedBy = "terraform"
    }
  )
}

# SQS Event Source Mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  count = var.enable_sqs_trigger ? 1 : 0

  event_source_arn                   = var.queue_arn
  function_name                      = aws_lambda_function.email_processor.arn
  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds

  # Failure handling
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.maximum_concurrency
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_alarm_threshold
  alarm_description   = "Alert when Lambda function errors exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.email_processor.function_name
  }

  alarm_actions = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Lambda function is throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.email_processor.function_name
  }

  alarm_actions = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.timeout * 1000 * 0.8 # Alert at 80% of timeout
  alarm_description   = "Alert when Lambda function duration is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.email_processor.function_name
  }

  alarm_actions = var.alarm_sns_topic_arns
}
