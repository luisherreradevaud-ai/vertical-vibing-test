import { z } from 'zod';

/**
 * IAM (Identity and Access Management) Core Types
 *
 * This module defines the entities for a comprehensive permission system
 * with support for Views, Modules, Features, User Levels, and fine-grained permissions
 */

// ==========================================
// Enums
// ==========================================

/**
 * Permission state for tri-state permissions
 */
export const PermissionState = {
  ALLOW: 'allow',
  DENY: 'deny',
  INHERIT: 'inherit',
} as const;

export type PermissionState = (typeof PermissionState)[keyof typeof PermissionState];

export const PermissionStateSchema = z.enum(['allow', 'deny', 'inherit']);

/**
 * Action scope for feature permissions
 */
export const ActionScope = {
  ANY: 'any', // Can perform action on any record
  OWN: 'own', // Can only perform action on own records
  TEAM: 'team', // Can perform action on team records
  COMPANY: 'company', // Can perform action on company records
} as const;

export type ActionScope = (typeof ActionScope)[keyof typeof ActionScope];

export const ActionScopeSchema = z.enum(['any', 'own', 'team', 'company']);

/**
 * Standard feature actions
 */
export const FeatureAction = {
  CREATE: 'Create',
  READ: 'Read',
  UPDATE: 'Update',
  DELETE: 'Delete',
  EXPORT: 'Export',
  APPROVE: 'Approve',
  PUBLISH: 'Publish',
} as const;

export type FeatureAction = (typeof FeatureAction)[keyof typeof FeatureAction];

// ==========================================
// Views
// ==========================================

/**
 * View - Represents a page/route in the application
 */
export const ViewSchema = z.object({
  id: z.string(),
  name: z.string(),
  url: z.string(), // Internal route path
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime().optional(),
});

export type View = z.infer<typeof ViewSchema>;

// ==========================================
// Modules
// ==========================================

/**
 * Module - A collection of views that can be assigned to companies
 */
export const ModuleSchema = z.object({
  id: z.string(),
  name: z.string(),
  code: z.string(), // Unique code (e.g., "risks", "compliance")
  description: z.string().optional(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime().optional(),
});

export type Module = z.infer<typeof ModuleSchema>;

/**
 * Module with its associated views
 */
export const ModuleWithViewsSchema = ModuleSchema.extend({
  views: z.array(ViewSchema),
});

export type ModuleWithViews = z.infer<typeof ModuleWithViewsSchema>;

// ==========================================
// Features
// ==========================================

/**
 * Feature - Represents an action or capability in the system
 */
export const FeatureSchema = z.object({
  id: z.string(),
  name: z.string(),
  key: z.string().optional(), // Stable key (e.g., "risks.edit")
  description: z.string().optional(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime().optional(),
});

export type Feature = z.infer<typeof FeatureSchema>;

/**
 * Feature with its associated views
 */
export const FeatureWithViewsSchema = FeatureSchema.extend({
  views: z.array(ViewSchema),
});

export type FeatureWithViews = z.infer<typeof FeatureWithViewsSchema>;

// ==========================================
// User Levels (Roles)
// ==========================================

/**
 * User Level - Tenant-scoped role with configurable permissions
 */
export const UserLevelSchema = z.object({
  id: z.string(),
  companyId: z.string(),
  name: z.string(),
  description: z.string().optional(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime().optional(),
});

export type UserLevel = z.infer<typeof UserLevelSchema>;

// ==========================================
// Permission Mappings
// ==========================================

/**
 * User Level to View permission
 */
export const UserLevelViewPermissionSchema = z.object({
  companyId: z.string(),
  userLevelId: z.string(),
  viewId: z.string(),
  state: PermissionStateSchema,
  modifiable: z.boolean().default(true),
});

export type UserLevelViewPermission = z.infer<typeof UserLevelViewPermissionSchema>;

/**
 * User Level to Feature permission (with action and scope)
 */
export const UserLevelFeaturePermissionSchema = z.object({
  companyId: z.string(),
  userLevelId: z.string(),
  featureId: z.string(),
  action: z.string(), // e.g., "Create", "Update", "Delete", etc.
  value: z.boolean(),
  scope: ActionScopeSchema.default('any'),
  modifiable: z.boolean().default(true),
});

export type UserLevelFeaturePermission = z.infer<typeof UserLevelFeaturePermissionSchema>;

/**
 * User to User Level assignment
 */
export const UserUserLevelSchema = z.object({
  userId: z.string(),
  userLevelId: z.string(),
});

export type UserUserLevel = z.infer<typeof UserUserLevelSchema>;

// ==========================================
// Menu Items
// ==========================================

/**
 * Menu Item - Top-level menu entry
 */
export const MenuItemSchema = z.object({
  id: z.string(),
  companyId: z.string().nullable(), // null = global/default menu
  label: z.string(),
  sequenceIndex: z.number().default(0),
  viewId: z.string().nullable(),
  featureId: z.string().nullable(),
  isEntrypoint: z.boolean().default(true),
  icon: z.string().optional(),
});

export type MenuItem = z.infer<typeof MenuItemSchema>;

/**
 * Sub-menu Item - Nested under a menu item
 */
export const SubMenuItemSchema = z.object({
  id: z.string(),
  companyId: z.string().nullable(),
  menuItemId: z.string(),
  label: z.string(),
  sequenceIndex: z.number().default(0),
  viewId: z.string().nullable(),
  featureId: z.string().nullable(),
});

export type SubMenuItem = z.infer<typeof SubMenuItemSchema>;

/**
 * Menu Item with sub-items
 */
export const MenuItemWithSubItemsSchema = MenuItemSchema.extend({
  subItems: z.array(SubMenuItemSchema).default([]),
});

export type MenuItemWithSubItems = z.infer<typeof MenuItemWithSubItemsSchema>;

// ==========================================
// Navigation Trail
// ==========================================

/**
 * Navigation Trail Entry - Breadcrumb history per session
 */
export const NavTrailEntrySchema = z.object({
  id: z.string(),
  userId: z.string(),
  companyId: z.string(),
  sessionId: z.string(), // Cookie per browser tab
  depth: z.number(), // 0..N
  viewId: z.string(),
  url: z.string(), // Path and safe query params
  createdAt: z.string().datetime(),
});

export type NavTrailEntry = z.infer<typeof NavTrailEntrySchema>;

// ==========================================
// Effective Permissions (Computed/Cached)
// ==========================================

/**
 * Effective View Permission - Computed permission for a user
 */
export const EffectiveViewPermissionSchema = z.object({
  userId: z.string(),
  companyId: z.string(),
  viewId: z.string(),
  allowed: z.boolean(),
  computedAt: z.string().datetime(),
});

export type EffectiveViewPermission = z.infer<typeof EffectiveViewPermissionSchema>;

/**
 * Effective Feature Permission - Computed permission for a user
 */
export const EffectiveFeaturePermissionSchema = z.object({
  userId: z.string(),
  companyId: z.string(),
  featureId: z.string(),
  action: z.string(),
  value: z.boolean(),
  scope: ActionScopeSchema,
  computedAt: z.string().datetime(),
});

export type EffectiveFeaturePermission = z.infer<typeof EffectiveFeaturePermissionSchema>;

// ==========================================
// Relation Mappings
// ==========================================

/**
 * Feature to View mapping
 */
export const Feature2ViewSchema = z.object({
  featureId: z.string(),
  viewId: z.string(),
});

export type Feature2View = z.infer<typeof Feature2ViewSchema>;

/**
 * Module to View mapping
 */
export const Module2ViewSchema = z.object({
  moduleId: z.string(),
  viewId: z.string(),
});

export type Module2View = z.infer<typeof Module2ViewSchema>;

/**
 * Company to Module mapping
 */
export const Company2ModuleSchema = z.object({
  companyId: z.string(),
  moduleId: z.string(),
});

export type Company2Module = z.infer<typeof Company2ModuleSchema>;

/**
 * Module to Feature mapping (optional - for hiding features of modules not purchased)
 */
export const Module2FeatureSchema = z.object({
  moduleId: z.string(),
  featureId: z.string(),
});

export type Module2Feature = z.infer<typeof Module2FeatureSchema>;
