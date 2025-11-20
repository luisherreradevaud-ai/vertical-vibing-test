terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SES Domain Identity
resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

# SES Domain DKIM Tokens
resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

# SES Domain Mail From
resource "aws_ses_domain_mail_from" "this" {
  count = var.mail_from_domain != null ? 1 : 0

  domain           = aws_ses_domain_identity.this.domain
  mail_from_domain = var.mail_from_domain
}

# Route53 Domain Verification Record (optional)
resource "aws_route53_record" "ses_verification" {
  count = var.create_route53_records && var.route53_zone_id != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
}

# Route53 DKIM Records (optional)
resource "aws_route53_record" "dkim" {
  count = var.create_route53_records && var.route53_zone_id != null ? 3 : 0

  zone_id = var.route53_zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# Route53 Mail From MX Record (optional)
resource "aws_route53_record" "mail_from_mx" {
  count = var.create_route53_records && var.route53_zone_id != null && var.mail_from_domain != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

# Route53 Mail From TXT Record for SPF (optional)
resource "aws_route53_record" "mail_from_txt" {
  count = var.create_route53_records && var.route53_zone_id != null && var.mail_from_domain != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com -all"]
}

# Configuration Set
resource "aws_ses_configuration_set" "this" {
  count = var.create_configuration_set ? 1 : 0

  name = var.configuration_set_name

  delivery_options {
    tls_policy = "Require"
  }

  reputation_metrics_enabled = true
}

# Event Destination for Bounces and Complaints (SNS)
resource "aws_ses_event_destination" "bounces_complaints" {
  count = var.create_configuration_set && var.bounce_complaint_topic_arn != null ? 1 : 0

  name                   = "${var.configuration_set_name}-bounces-complaints"
  configuration_set_name = aws_ses_configuration_set.this[0].name
  enabled                = true
  matching_types         = ["bounce", "complaint"]

  sns_destination {
    topic_arn = var.bounce_complaint_topic_arn
  }
}

# Event Destination for Delivery and Send Events (CloudWatch)
resource "aws_ses_event_destination" "delivery_send" {
  count = var.create_configuration_set && var.enable_cloudwatch_events ? 1 : 0

  name                   = "${var.configuration_set_name}-delivery-send"
  configuration_set_name = aws_ses_configuration_set.this[0].name
  enabled                = true
  matching_types         = ["send", "delivery", "reject"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}

# Data source for current region
data "aws_region" "current" {}
