import { z } from 'zod';
import type { Subscription, PlanConfig } from '../entities/subscription';
import { PlanTier } from '../entities/subscription';

/**
 * Create Subscription DTO
 */
export const createSubscriptionSchema = z.object({
  planTier: z.nativeEnum(PlanTier),
  paymentMethodId: z.string().optional(), // Stripe payment method ID
});

export type CreateSubscriptionDTO = z.infer<typeof createSubscriptionSchema>;

/**
 * Update Subscription DTO
 */
export const updateSubscriptionSchema = z.object({
  planTier: z.nativeEnum(PlanTier).optional(),
  cancelAtPeriodEnd: z.boolean().optional(),
});

export type UpdateSubscriptionDTO = z.infer<typeof updateSubscriptionSchema>;

/**
 * Subscription Response
 */
export interface SubscriptionResponse {
  status: 'success';
  data: {
    subscription: Subscription;
  };
}

/**
 * Plans List Response
 */
export interface PlansResponse {
  status: 'success';
  data: {
    plans: PlanConfig[];
  };
}

/**
 * Checkout Session Response
 */
export interface CheckoutSessionResponse {
  status: 'success';
  data: {
    sessionId: string;
    url: string;
  };
}
