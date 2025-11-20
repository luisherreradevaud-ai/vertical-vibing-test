import type { AuthProvider } from '../entities/user';

/**
 * Auth Provider Types
 *
 * Types for authentication provider abstraction
 */

/**
 * Result from auth provider login/register operations
 */
export interface AuthProviderResult {
  userId: string; // Internal user ID (from our DB)
  email: string;
  name: string;
  externalId?: string; // Provider's user ID (null for in-house)
  metadata?: Record<string, any>; // Provider-specific data
}

/**
 * Token validation result from provider
 */
export interface TokenValidationResult {
  valid: boolean;
  userId?: string; // Internal user ID
  email?: string;
  externalId?: string;
  error?: string;
}

/**
 * Login credentials for in-house provider
 */
export interface LoginCredentials {
  email: string;
  password: string;
}

/**
 * Registration data for providers
 */
export interface RegisterData {
  email: string;
  password: string;
  name: string;
}

/**
 * Password reset result
 */
export interface PasswordResetResult {
  success: boolean;
  message: string;
}

/**
 * Email verification result
 */
export interface EmailVerificationResult {
  success: boolean;
  userId: string;
}

/**
 * Provider-specific error
 */
export class AuthProviderError extends Error {
  constructor(
    message: string,
    public provider: AuthProvider,
    public originalError?: Error
  ) {
    super(message);
    this.name = 'AuthProviderError';
  }
}
