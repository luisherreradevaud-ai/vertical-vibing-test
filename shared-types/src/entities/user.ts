import { z } from 'zod';

/**
 * Auth Provider Types
 *
 * Supported authentication providers
 */
export const authProviderSchema = z.enum(['inhouse', 'cognito', 'clerk']);
export type AuthProvider = z.infer<typeof authProviderSchema>;

/**
 * User entity schema
 *
 * Represents a user in the system
 */
export const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  avatarUrl: z.string().url().nullable(),
  emailVerified: z.boolean(),
  authProvider: authProviderSchema.default('inhouse'),
  externalId: z.string().nullable(),
  externalMetadata: z.record(z.any()).nullable(),
  isSuperAdmin: z.boolean().default(false),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export type User = z.infer<typeof userSchema>;

/**
 * User without sensitive data (for public responses)
 */
export const publicUserSchema = userSchema.omit({
  emailVerified: true,
  externalMetadata: true,
});

export type PublicUser = z.infer<typeof publicUserSchema>;
