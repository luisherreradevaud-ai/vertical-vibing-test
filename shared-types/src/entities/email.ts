import { z } from 'zod';

/**
 * Email Template Variable Schema
 * Defines dynamic variables that can be used in email templates
 */
export const emailTemplateVariableSchema = z.object({
  name: z.string().min(1).max(100),
  type: z.enum(['string', 'number', 'boolean', 'date', 'url']),
  required: z.boolean(),
  description: z.string().optional(),
  defaultValue: z.any().optional(),
  validation: z
    .object({
      pattern: z.string().optional(),
      min: z.number().optional(),
      max: z.number().optional(),
      options: z.array(z.string()).optional(),
    })
    .optional(),
});

export type EmailTemplateVariable = z.infer<typeof emailTemplateVariableSchema>;

/**
 * Configuration Validation Rules Schema
 * Defines validation rules for system configuration values
 */
export const configValidationRulesSchema = z.object({
  pattern: z.string().optional(),
  min: z.number().optional(),
  max: z.number().optional(),
  required: z.boolean().optional(),
  options: z.array(z.string()).optional(),
});

export type ConfigValidationRules = z.infer<typeof configValidationRulesSchema>;

/**
 * Email Template Entity Schema
 * Represents an email template (system or custom)
 */
export const emailTemplateSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  displayName: z.string().min(1).max(255),
  description: z.string().nullable(),
  category: z.enum(['auth', 'billing', 'notifications', 'iam', 'general']).nullable(),
  version: z.number().int().positive(),
  status: z.enum(['draft', 'published', 'archived']),
  contentType: z.enum(['react-email', 'html', 'visual-builder']),
  content: z.string().min(1),
  variables: z.array(emailTemplateVariableSchema),
  subjectTemplate: z.string().min(1).max(500),
  isSystemTemplate: z.boolean(),
  parentTemplateId: z.string().uuid().nullable(),
  createdBy: z.string().uuid().nullable(),
  createdAt: z.date(),
  updatedBy: z.string().uuid().nullable(),
  updatedAt: z.date(),
  publishedBy: z.string().uuid().nullable(),
  publishedAt: z.date().nullable(),
});

export type EmailTemplate = z.infer<typeof emailTemplateSchema>;

/**
 * Email Template Version Entity Schema
 * Represents a historical version of an email template
 */
export const emailTemplateVersionSchema = z.object({
  id: z.string().uuid(),
  templateId: z.string().uuid(),
  version: z.number().int().positive(),
  content: z.string().min(1),
  variables: z.array(emailTemplateVariableSchema),
  subjectTemplate: z.string().min(1).max(500),
  changeDescription: z.string().nullable(),
  createdBy: z.string().uuid().nullable(),
  createdAt: z.date(),
});

export type EmailTemplateVersion = z.infer<typeof emailTemplateVersionSchema>;

/**
 * System Configuration Entity Schema
 * Represents a system configuration key-value pair
 */
export const systemConfigSchema = z.object({
  id: z.string().uuid(),
  key: z.string().min(1).max(100),
  value: z.string(),
  valueType: z.enum(['string', 'number', 'boolean', 'json']),
  category: z.enum(['email', 'billing', 'general', 'feature-flags', 'integrations']).nullable(),
  description: z.string().nullable(),
  isSensitive: z.boolean(),
  allowEnvOverride: z.boolean(),
  envVarName: z.string().max(100).nullable(),
  validationRules: configValidationRulesSchema.nullable(),
  updatedBy: z.string().uuid().nullable(),
  updatedAt: z.date(),
});

export type SystemConfig = z.infer<typeof systemConfigSchema>;

/**
 * Email Log Entity Schema
 * Represents a record of a sent or attempted email
 */
export const emailLogSchema = z.object({
  id: z.string().uuid(),
  templateName: z.string().max(100).nullable(),
  templateVersion: z.number().int().positive().nullable(),
  toAddress: z.string().email().max(255),
  ccAddresses: z.array(z.string().email()).nullable(),
  bccAddresses: z.array(z.string().email()).nullable(),
  subject: z.string().min(1).max(500),
  htmlContent: z.string().nullable(),
  status: z.enum(['queued', 'sending', 'sent', 'failed', 'bounced', 'complained']),
  messageId: z.string().max(255).nullable(),
  sesResponse: z.record(z.any()).nullable(),
  errorMessage: z.string().nullable(),
  retryCount: z.number().int().min(0),
  maxRetries: z.number().int().min(0),
  nextRetryAt: z.date().nullable(),
  templateData: z.record(z.any()).nullable(),
  metadata: z.record(z.any()).nullable(),
  queuedAt: z.date().nullable(),
  sentAt: z.date().nullable(),
  failedAt: z.date().nullable(),
  bouncedAt: z.date().nullable(),
  createdAt: z.date(),
});

export type EmailLog = z.infer<typeof emailLogSchema>;

/**
 * Email Bounce Entity Schema
 * Represents an email address that has bounced or complained
 */
export const emailBounceSchema = z.object({
  id: z.string().uuid(),
  emailAddress: z.string().email().max(255),
  bounceType: z.enum(['hard', 'soft', 'complaint']).nullable(),
  bounceReason: z.string().nullable(),
  bouncedAt: z.date(),
  sesNotification: z.record(z.any()).nullable(),
});

export type EmailBounce = z.infer<typeof emailBounceSchema>;

/**
 * Email Queue Message Schema
 * Represents a message in the SQS email queue
 */
export const emailQueueMessageSchema = z.object({
  templateName: z.string().min(1).max(100),
  toAddress: z.string().email().max(255),
  ccAddresses: z.array(z.string().email()).optional(),
  bccAddresses: z.array(z.string().email()).optional(),
  templateData: z.record(z.any()),
  metadata: z.record(z.any()).optional(),
  priority: z.enum(['low', 'normal', 'high']).default('normal'),
  scheduledFor: z.date().optional(),
});

export type EmailQueueMessage = z.infer<typeof emailQueueMessageSchema>;
