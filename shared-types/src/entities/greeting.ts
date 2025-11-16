import { z } from 'zod';

/**
 * Greeting entity schema
 *
 * Used by both backend (API response) and frontend (display)
 */
export const greetingSchema = z.object({
  id: z.string().uuid(),
  message: z.string().min(1).max(500),
  language: z.string().min(2).max(10),
  createdAt: z.string().datetime(),
});

export type Greeting = z.infer<typeof greetingSchema>;
