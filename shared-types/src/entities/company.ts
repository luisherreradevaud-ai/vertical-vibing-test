import { z } from 'zod';

/**
 * Company Role
 * Defines user roles within a company
 */
export enum CompanyRole {
  OWNER = 'owner',     // Full control, can delete company
  ADMIN = 'admin',     // Can manage members and settings
  MEMBER = 'member',   // Regular member with basic access
}

/**
 * Company Status
 */
export enum CompanyStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  DELETED = 'deleted',
}

/**
 * Company Schema
 */
export const CompanySchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(255),
  slug: z.string().min(1).max(255).regex(/^[a-z0-9-]+$/),
  status: z.nativeEnum(CompanyStatus),
  createdAt: z.date(),
  updatedAt: z.date(),
});

/**
 * Company Type
 */
export type Company = z.infer<typeof CompanySchema>;

/**
 * Company Member Schema
 */
export const CompanyMemberSchema = z.object({
  id: z.string().uuid(),
  companyId: z.string().uuid(),
  userId: z.string().uuid(),
  role: z.nativeEnum(CompanyRole),
  joinedAt: z.date(),
});

/**
 * Company Member Type
 */
export type CompanyMember = z.infer<typeof CompanyMemberSchema>;

/**
 * Public Company (safe for client)
 */
export type PublicCompany = Omit<Company, 'status'>;

/**
 * Company with Members
 */
export interface CompanyWithMembers extends Company {
  members: Array<CompanyMember & {
    user: {
      id: string;
      email: string;
      name: string | null;
    };
  }>;
}
