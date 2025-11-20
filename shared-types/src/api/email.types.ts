import { z } from 'zod';
import {
  emailTemplateVariableSchema,
  emailTemplateSchema,
  emailTemplateVersionSchema,
  systemConfigSchema,
  emailLogSchema,
  emailBounceSchema,
  configValidationRulesSchema,
} from '../entities/email';

// =====================================================
// EMAIL SENDING API
// =====================================================

/**
 * Send Email DTO
 * Used to send a single email using a template
 */
export const sendEmailDTOSchema = z.object({
  templateName: z.string().min(1).max(100),
  toAddress: z.string().email().max(255),
  ccAddresses: z.array(z.string().email()).optional(),
  bccAddresses: z.array(z.string().email()).optional(),
  templateData: z.record(z.any()),
  metadata: z.record(z.any()).optional(),
  priority: z.enum(['low', 'normal', 'high']).default('normal'),
  scheduledFor: z.date().optional(),
});

export type SendEmailDTO = z.infer<typeof sendEmailDTOSchema>;

/**
 * Send Email Response
 * Response after queuing an email for sending
 */
export const sendEmailResponseSchema = z.object({
  success: z.boolean(),
  emailLogId: z.string().uuid(),
  status: z.enum(['queued', 'sent', 'failed']),
  message: z.string(),
  queuedAt: z.date().optional(),
  sentAt: z.date().optional(),
  errorMessage: z.string().optional(),
});

export type SendEmailResponse = z.infer<typeof sendEmailResponseSchema>;

/**
 * Bulk Send Email DTO
 * Used to send emails to multiple recipients
 */
export const bulkSendEmailDTOSchema = z.object({
  templateName: z.string().min(1).max(100),
  recipients: z
    .array(
      z.object({
        toAddress: z.string().email().max(255),
        templateData: z.record(z.any()),
      }),
    )
    .min(1)
    .max(1000),
  metadata: z.record(z.any()).optional(),
  priority: z.enum(['low', 'normal', 'high']).default('normal'),
});

export type BulkSendEmailDTO = z.infer<typeof bulkSendEmailDTOSchema>;

/**
 * Bulk Send Email Response
 */
export const bulkSendEmailResponseSchema = z.object({
  success: z.boolean(),
  totalQueued: z.number().int().min(0),
  totalFailed: z.number().int().min(0),
  emailLogIds: z.array(z.string().uuid()),
  errors: z.array(z.string()).optional(),
});

export type BulkSendEmailResponse = z.infer<typeof bulkSendEmailResponseSchema>;

// =====================================================
// EMAIL TEMPLATE MANAGEMENT API
// =====================================================

/**
 * Create Email Template DTO
 */
export const createEmailTemplateDTOSchema = z.object({
  name: z.string().min(1).max(100).regex(/^[a-z0-9-]+$/, 'Must be lowercase alphanumeric with hyphens'),
  displayName: z.string().min(1).max(255),
  description: z.string().optional(),
  category: z.enum(['auth', 'billing', 'notifications', 'iam', 'general']).optional(),
  contentType: z.enum(['react-email', 'html', 'visual-builder']).default('react-email'),
  content: z.string().min(1),
  variables: z.array(emailTemplateVariableSchema),
  subjectTemplate: z.string().min(1).max(500),
  parentTemplateId: z.string().uuid().optional(),
});

export type CreateEmailTemplateDTO = z.infer<typeof createEmailTemplateDTOSchema>;

/**
 * Update Email Template DTO
 */
export const updateEmailTemplateDTOSchema = z.object({
  displayName: z.string().min(1).max(255).optional(),
  description: z.string().optional(),
  category: z.enum(['auth', 'billing', 'notifications', 'iam', 'general']).optional(),
  contentType: z.enum(['react-email', 'html', 'visual-builder']).optional(),
  content: z.string().min(1).optional(),
  variables: z.array(emailTemplateVariableSchema).optional(),
  subjectTemplate: z.string().min(1).max(500).optional(),
  changeDescription: z.string().optional(),
});

export type UpdateEmailTemplateDTO = z.infer<typeof updateEmailTemplateDTOSchema>;

/**
 * Publish Email Template DTO
 */
export const publishEmailTemplateDTOSchema = z.object({
  templateId: z.string().uuid(),
});

export type PublishEmailTemplateDTO = z.infer<typeof publishEmailTemplateDTOSchema>;

/**
 * Archive Email Template DTO
 */
export const archiveEmailTemplateDTOSchema = z.object({
  templateId: z.string().uuid(),
});

export type ArchiveEmailTemplateDTO = z.infer<typeof archiveEmailTemplateDTOSchema>;

/**
 * Clone Email Template DTO
 */
export const cloneEmailTemplateDTOSchema = z.object({
  templateId: z.string().uuid(),
  newName: z.string().min(1).max(100).regex(/^[a-z0-9-]+$/, 'Must be lowercase alphanumeric with hyphens'),
  newDisplayName: z.string().min(1).max(255),
});

export type CloneEmailTemplateDTO = z.infer<typeof cloneEmailTemplateDTOSchema>;

/**
 * Rollback Template DTO
 */
export const rollbackTemplateDTOSchema = z.object({
  templateId: z.string().uuid(),
  targetVersion: z.number().int().positive(),
  changeDescription: z.string().optional(),
});

export type RollbackTemplateDTO = z.infer<typeof rollbackTemplateDTOSchema>;

/**
 * Email Template Response
 */
export const emailTemplateResponseSchema = emailTemplateSchema.extend({
  versionCount: z.number().int().min(0).optional(),
  lastPublishedVersion: z.number().int().positive().optional(),
  canEdit: z.boolean().optional(),
  canDelete: z.boolean().optional(),
  canPublish: z.boolean().optional(),
});

export type EmailTemplateResponse = z.infer<typeof emailTemplateResponseSchema>;

/**
 * List Email Templates Query
 */
export const listEmailTemplatesQuerySchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().min(1).max(100).default(20),
  status: z.enum(['draft', 'published', 'archived']).optional(),
  category: z.enum(['auth', 'billing', 'notifications', 'iam', 'general']).optional(),
  isSystemTemplate: z.boolean().optional(),
  search: z.string().max(255).optional(),
  sortBy: z.enum(['name', 'displayName', 'createdAt', 'updatedAt', 'publishedAt']).default('updatedAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export type ListEmailTemplatesQuery = z.infer<typeof listEmailTemplatesQuerySchema>;

/**
 * List Email Templates Response
 */
export const listEmailTemplatesResponseSchema = z.object({
  templates: z.array(emailTemplateResponseSchema),
  pagination: z.object({
    page: z.number().int().positive(),
    limit: z.number().int().positive(),
    total: z.number().int().min(0),
    totalPages: z.number().int().min(0),
  }),
});

export type ListEmailTemplatesResponse = z.infer<typeof listEmailTemplatesResponseSchema>;

/**
 * Get Template Versions Response
 */
export const getTemplateVersionsResponseSchema = z.object({
  templateId: z.string().uuid(),
  currentVersion: z.number().int().positive(),
  versions: z.array(emailTemplateVersionSchema),
});

export type GetTemplateVersionsResponse = z.infer<typeof getTemplateVersionsResponseSchema>;

/**
 * Preview Template DTO
 */
export const previewTemplateDTOSchema = z.object({
  templateName: z.string().min(1).max(100).optional(),
  templateId: z.string().uuid().optional(),
  content: z.string().min(1).optional(),
  templateData: z.record(z.any()),
  subjectTemplate: z.string().optional(),
}).refine(
  (data) => data.templateName || data.templateId || data.content,
  'Must provide either templateName, templateId, or content',
);

export type PreviewTemplateDTO = z.infer<typeof previewTemplateDTOSchema>;

/**
 * Preview Template Response
 */
export const previewTemplateResponseSchema = z.object({
  subject: z.string(),
  html: z.string(),
  text: z.string().optional(),
});

export type PreviewTemplateResponse = z.infer<typeof previewTemplateResponseSchema>;

// =====================================================
// EMAIL LOG API
// =====================================================

/**
 * List Email Logs Query
 */
export const listEmailLogsQuerySchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().min(1).max(100).default(20),
  status: z.enum(['queued', 'sending', 'sent', 'failed', 'bounced', 'complained']).optional(),
  templateName: z.string().max(100).optional(),
  toAddress: z.string().email().optional(),
  startDate: z.date().optional(),
  endDate: z.date().optional(),
  sortBy: z.enum(['createdAt', 'sentAt', 'queuedAt', 'status']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export type ListEmailLogsQuery = z.infer<typeof listEmailLogsQuerySchema>;

/**
 * List Email Logs Response
 */
export const listEmailLogsResponseSchema = z.object({
  logs: z.array(emailLogSchema),
  pagination: z.object({
    page: z.number().int().positive(),
    limit: z.number().int().positive(),
    total: z.number().int().min(0),
    totalPages: z.number().int().min(0),
  }),
  stats: z
    .object({
      totalSent: z.number().int().min(0),
      totalFailed: z.number().int().min(0),
      totalQueued: z.number().int().min(0),
      totalBounced: z.number().int().min(0),
    })
    .optional(),
});

export type ListEmailLogsResponse = z.infer<typeof listEmailLogsResponseSchema>;

/**
 * Retry Failed Email DTO
 */
export const retryFailedEmailDTOSchema = z.object({
  emailLogId: z.string().uuid(),
  force: z.boolean().default(false),
});

export type RetryFailedEmailDTO = z.infer<typeof retryFailedEmailDTOSchema>;

// =====================================================
// SYSTEM CONFIGURATION API
// =====================================================

/**
 * Create System Config DTO
 */
export const createSystemConfigDTOSchema = z.object({
  key: z.string().min(1).max(100).regex(/^[A-Z_]+$/, 'Must be uppercase with underscores'),
  value: z.string(),
  valueType: z.enum(['string', 'number', 'boolean', 'json']).default('string'),
  category: z.enum(['email', 'billing', 'general', 'feature-flags', 'integrations']).optional(),
  description: z.string().optional(),
  isSensitive: z.boolean().default(false),
  allowEnvOverride: z.boolean().default(true),
  envVarName: z.string().max(100).optional(),
  validationRules: configValidationRulesSchema.optional(),
});

export type CreateSystemConfigDTO = z.infer<typeof createSystemConfigDTOSchema>;

/**
 * Update System Config DTO
 */
export const updateSystemConfigDTOSchema = z.object({
  value: z.string().optional(),
  valueType: z.enum(['string', 'number', 'boolean', 'json']).optional(),
  category: z.enum(['email', 'billing', 'general', 'feature-flags', 'integrations']).optional(),
  description: z.string().optional(),
  isSensitive: z.boolean().optional(),
  allowEnvOverride: z.boolean().optional(),
  validationRules: configValidationRulesSchema.optional(),
});

export type UpdateSystemConfigDTO = z.infer<typeof updateSystemConfigDTOSchema>;

/**
 * System Config Response
 */
export const systemConfigResponseSchema = systemConfigSchema.extend({
  effectiveValue: z.string().optional(),
  source: z.enum(['database', 'environment', 'default']).optional(),
  canEdit: z.boolean().optional(),
});

export type SystemConfigResponse = z.infer<typeof systemConfigResponseSchema>;

/**
 * List System Configs Query
 */
export const listSystemConfigsQuerySchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().min(1).max(100).default(50),
  category: z.enum(['email', 'billing', 'general', 'feature-flags', 'integrations']).optional(),
  search: z.string().max(255).optional(),
  showSensitive: z.boolean().default(false),
});

export type ListSystemConfigsQuery = z.infer<typeof listSystemConfigsQuerySchema>;

/**
 * List System Configs Response
 */
export const listSystemConfigsResponseSchema = z.object({
  configs: z.array(systemConfigResponseSchema),
  pagination: z.object({
    page: z.number().int().positive(),
    limit: z.number().int().positive(),
    total: z.number().int().min(0),
    totalPages: z.number().int().min(0),
  }),
});

export type ListSystemConfigsResponse = z.infer<typeof listSystemConfigsResponseSchema>;

// =====================================================
// EMAIL BOUNCE API
// =====================================================

/**
 * List Email Bounces Query
 */
export const listEmailBouncesQuerySchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().min(1).max(100).default(20),
  bounceType: z.enum(['hard', 'soft', 'complaint']).optional(),
  search: z.string().email().optional(),
  startDate: z.date().optional(),
  endDate: z.date().optional(),
});

export type ListEmailBouncesQuery = z.infer<typeof listEmailBouncesQuerySchema>;

/**
 * List Email Bounces Response
 */
export const listEmailBouncesResponseSchema = z.object({
  bounces: z.array(emailBounceSchema),
  pagination: z.object({
    page: z.number().int().positive(),
    limit: z.number().int().positive(),
    total: z.number().int().min(0),
    totalPages: z.number().int().min(0),
  }),
});

export type ListEmailBouncesResponse = z.infer<typeof listEmailBouncesResponseSchema>;

/**
 * Remove Email Bounce DTO
 */
export const removeEmailBounceDTOSchema = z.object({
  emailAddress: z.string().email().max(255),
  reason: z.string().optional(),
});

export type RemoveEmailBounceDTO = z.infer<typeof removeEmailBounceDTOSchema>;

// =====================================================
// EMAIL STATISTICS API
// =====================================================

/**
 * Email Statistics Query
 */
export const emailStatisticsQuerySchema = z.object({
  startDate: z.date(),
  endDate: z.date(),
  groupBy: z.enum(['day', 'week', 'month']).default('day'),
  templateName: z.string().max(100).optional(),
});

export type EmailStatisticsQuery = z.infer<typeof emailStatisticsQuerySchema>;

/**
 * Email Statistics Response
 */
export const emailStatisticsResponseSchema = z.object({
  period: z.object({
    startDate: z.date(),
    endDate: z.date(),
  }),
  totals: z.object({
    sent: z.number().int().min(0),
    failed: z.number().int().min(0),
    bounced: z.number().int().min(0),
    queued: z.number().int().min(0),
    successRate: z.number().min(0).max(100),
  }),
  byTemplate: z
    .array(
      z.object({
        templateName: z.string(),
        sent: z.number().int().min(0),
        failed: z.number().int().min(0),
        bounced: z.number().int().min(0),
      }),
    )
    .optional(),
  timeSeries: z
    .array(
      z.object({
        date: z.date(),
        sent: z.number().int().min(0),
        failed: z.number().int().min(0),
        bounced: z.number().int().min(0),
      }),
    )
    .optional(),
});

export type EmailStatisticsResponse = z.infer<typeof emailStatisticsResponseSchema>;
