output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.this.arn
}

output "domain_identity_verification_token" {
  description = "Verification token for the domain (for manual DNS setup)"
  value       = aws_ses_domain_identity.this.verification_token
}

output "dkim_tokens" {
  description = "DKIM tokens for the domain (for manual DNS setup)"
  value       = aws_ses_domain_dkim.this.dkim_tokens
}

output "mail_from_domain" {
  description = "The configured MAIL FROM domain"
  value       = var.mail_from_domain
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = var.create_configuration_set ? aws_ses_configuration_set.this[0].name : null
}

output "configuration_set_arn" {
  description = "ARN of the SES configuration set"
  value       = var.create_configuration_set ? aws_ses_configuration_set.this[0].arn : null
}

output "dns_records" {
  description = "DNS records to create manually (if not using Route53)"
  value = {
    verification = {
      name  = "_amazonses.${var.domain}"
      type  = "TXT"
      value = aws_ses_domain_identity.this.verification_token
    }
    dkim = [
      for token in aws_ses_domain_dkim.this.dkim_tokens : {
        name  = "${token}._domainkey.${var.domain}"
        type  = "CNAME"
        value = "${token}.dkim.amazonses.com"
      }
    ]
    mail_from_mx = var.mail_from_domain != null ? {
      name  = var.mail_from_domain
      type  = "MX"
      value = "10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"
    } : null
    mail_from_txt = var.mail_from_domain != null ? {
      name  = var.mail_from_domain
      type  = "TXT"
      value = "v=spf1 include:amazonses.com -all"
    } : null
  }
}
