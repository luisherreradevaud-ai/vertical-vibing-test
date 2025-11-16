import { z } from 'zod';

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
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export type User = z.infer<typeof userSchema>;

/**
 * User without sensitive data (for public responses)
 */
export const publicUserSchema = userSchema.omit({
  emailVerified: true,
});

export type PublicUser = z.infer<typeof publicUserSchema>;
