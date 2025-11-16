import { z } from 'zod';

/**
 * Subscription Status
 */
export enum SubscriptionStatus {
  ACTIVE = 'active',
  CANCELED = 'canceled',
  PAST_DUE = 'past_due',
  TRIALING = 'trialing',
  INCOMPLETE = 'incomplete',
}

/**
 * Plan Tier
 */
export enum PlanTier {
  FREE = 'free',
  STARTER = 'starter',
  PRO = 'pro',
  ENTERPRISE = 'enterprise',
}

/**
 * Subscription Schema
 */
export const subscriptionSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  planTier: z.nativeEnum(PlanTier),
  status: z.nativeEnum(SubscriptionStatus),
  currentPeriodStart: z.date(),
  currentPeriodEnd: z.date(),
  cancelAtPeriodEnd: z.boolean(),
  stripeCustomerId: z.string().nullable(),
  stripeSubscriptionId: z.string().nullable(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Subscription = z.infer<typeof subscriptionSchema>;

/**
 * New Subscription (for DB insertion)
 */
export type NewSubscription = Omit<Subscription, 'id' | 'createdAt' | 'updatedAt'> & {
  id?: string;
  createdAt?: Date;
  updatedAt?: Date;
};

/**
 * Plan Configuration
 */
export interface PlanConfig {
  tier: PlanTier;
  name: string;
  description: string;
  price: number; // in cents
  currency: string;
  interval: 'month' | 'year';
  features: string[];
  maxUsers?: number;
  maxProjects?: number;
  maxStorage?: number; // in GB
  priority: number; // for ordering
}
