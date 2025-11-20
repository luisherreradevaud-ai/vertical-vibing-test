terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SES Domain Configuration
module "ses_domain" {
  source = "../../modules/ses-domain"

  domain                     = var.domain
  mail_from_domain           = var.mail_from_domain
  create_route53_records     = var.create_route53_records
  route53_zone_id            = var.route53_zone_id
  create_configuration_set   = true
  configuration_set_name     = "${var.environment}-email-system"
  bounce_complaint_topic_arn = var.bounce_complaint_sns_topic_arn
  enable_cloudwatch_events   = true

  tags = local.common_tags
}

# Email Queue (SQS)
module "email_queue" {
  source = "../../modules/sqs-email-queue"

  queue_name                     = "${var.environment}-email-queue"
  fifo_queue                     = false
  visibility_timeout_seconds     = 360 # 6 minutes (6x Lambda timeout)
  message_retention_seconds      = 1209600 # 14 days
  max_receive_count              = 3
  enable_encryption              = true
  kms_key_id                     = var.kms_key_id
  create_cloudwatch_alarms       = true
  dlq_alarm_threshold            = 1
  message_age_threshold          = 3600 # 1 hour
  alarm_sns_topic_arns           = var.alarm_sns_topic_arns

  tags = local.common_tags
}

# IAM Roles
module "email_iam" {
  source = "../../modules/email-iam"

  resource_prefix = "${var.project_name}-${var.environment}"

  ses_identity_arns              = [module.ses_domain.domain_identity_arn]
  queue_arns                     = [module.email_queue.queue_arn, module.email_queue.dlq_arn]
  enable_vpc_access              = var.enable_lambda_vpc_access
  enable_kms_access              = var.kms_key_id != null
  kms_key_arns                   = var.kms_key_id != null ? [var.kms_key_arn] : []
  enable_secrets_manager_access  = var.enable_secrets_manager_access
  secrets_manager_arns           = var.secrets_manager_arns
  create_backend_role            = var.create_backend_role

  tags = local.common_tags
}

# Lambda Function for Queue Processing
module "email_lambda" {
  source = "../../modules/email-lambda"

  function_name            = "${var.environment}-email-processor"
  deployment_package_path  = var.lambda_deployment_package_path
  source_code_hash         = var.lambda_source_code_hash
  handler                  = var.lambda_handler
  runtime                  = var.lambda_runtime
  timeout                  = 60
  memory_size              = 512
  execution_role_arn       = module.email_iam.lambda_execution_role_arn
  environment              = var.environment
  database_url             = var.database_url
  ses_region               = data.aws_region.current.name
  ses_from_email           = var.default_from_email
  ses_configuration_set    = module.ses_domain.configuration_set_name
  queue_url                = module.email_queue.queue_id
  queue_arn                = module.email_queue.queue_arn
  log_level                = var.log_level
  vpc_config               = var.lambda_vpc_config
  lambda_dlq_arn           = var.lambda_dlq_arn
  log_retention_days       = var.log_retention_days
  enable_sqs_trigger       = true
  batch_size               = 10
  maximum_batching_window_in_seconds = 5
  maximum_concurrency      = 10
  create_cloudwatch_alarms = true
  error_alarm_threshold    = 5
  alarm_sns_topic_arns     = var.alarm_sns_topic_arns

  additional_environment_variables = var.additional_lambda_env_vars

  tags = local.common_tags

  depends_on = [module.email_iam]
}

# Data sources
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Local variables
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Feature     = "email"
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  )
}
