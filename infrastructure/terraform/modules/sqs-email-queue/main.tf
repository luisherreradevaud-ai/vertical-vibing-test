terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "dlq" {
  name = "${var.queue_name}-dlq"

  message_retention_seconds = var.dlq_message_retention_seconds
  kms_master_key_id         = var.enable_encryption ? (var.kms_key_id != null ? var.kms_key_id : "alias/aws/sqs") : null

  tags = merge(
    var.tags,
    {
      Name      = "${var.queue_name}-dlq"
      ManagedBy = "terraform"
      Purpose   = "Dead Letter Queue"
    }
  )
}

# Main Email Queue
resource "aws_sqs_queue" "main" {
  name = var.queue_name

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Enable encryption
  kms_master_key_id                 = var.enable_encryption ? (var.kms_key_id != null ? var.kms_key_id : "alias/aws/sqs") : null
  kms_data_key_reuse_period_seconds = var.enable_encryption ? 300 : null

  # Configure DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  # Enable content-based deduplication for FIFO queues
  content_based_deduplication = var.fifo_queue ? true : null
  fifo_queue                  = var.fifo_queue

  tags = merge(
    var.tags,
    {
      Name      = var.queue_name
      ManagedBy = "terraform"
      Purpose   = "Email Processing Queue"
    }
  )
}

# Queue Policy (allows SES to send messages if configured)
resource "aws_sqs_queue_policy" "main" {
  count = var.allow_ses_send ? 1 : 0

  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# CloudWatch Alarms for Queue Monitoring
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.queue_name}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = var.dlq_alarm_threshold
  alarm_description   = "Alert when DLQ has messages"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = var.alarm_sns_topic_arns
}

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.queue_name}-message-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.message_age_threshold
  alarm_description   = "Alert when messages are too old"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  alarm_actions = var.alarm_sns_topic_arns
}

# Data sources
data "aws_caller_identity" "current" {}
