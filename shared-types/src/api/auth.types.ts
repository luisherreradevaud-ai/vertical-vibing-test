import { z } from 'zod';
import type { User, PublicUser } from '../entities/user';

/**
 * Register DTO
 *
 * Data required to register a new user
 */
export const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters').max(100),
  name: z.string().min(1, 'Name is required').max(100),
});

export type RegisterDTO = z.infer<typeof registerSchema>;

/**
 * Login DTO
 *
 * Data required to login
 */
export const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

export type LoginDTO = z.infer<typeof loginSchema>;

/**
 * Auth Response
 *
 * Returned after successful login/register
 */
export interface AuthResponse {
  status: 'success';
  data: {
    user: PublicUser;
    token: string;
  };
}

/**
 * Update Profile DTO
 *
 * Data that can be updated in user profile
 */
export const updateProfileSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
  avatarUrl: z.string().url().nullable().optional(),
});

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>;

/**
 * Change Password DTO
 */
export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: z.string().min(8, 'New password must be at least 8 characters').max(100),
});

export type ChangePasswordDTO = z.infer<typeof changePasswordSchema>;

/**
 * JWT Payload
 *
 * Data encoded in JWT token
 */
export interface JWTPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

/**
 * User Profile Response
 *
 * Returned when getting or updating user profile
 */
export interface UserProfileResponse {
  status: 'success';
  data: {
    user: PublicUser;
  };
}
