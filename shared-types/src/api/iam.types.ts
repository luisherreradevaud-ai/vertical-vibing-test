import { z } from 'zod';
import {
  ViewSchema,
  ModuleSchema,
  FeatureSchema,
  UserLevelSchema,
  MenuItemSchema,
  SubMenuItemSchema,
  PermissionStateSchema,
  ActionScopeSchema,
} from '../entities/iam';

/**
 * IAM API Request/Response Types
 */

// ==========================================
// View Management (Superadmin)
// ==========================================

export const CreateViewDTOSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1),
  url: z.string().min(1),
});

export type CreateViewDTO = z.infer<typeof CreateViewDTOSchema>;

export const UpdateViewDTOSchema = z.object({
  name: z.string().min(1).optional(),
  url: z.string().min(1).optional(),
});

export type UpdateViewDTO = z.infer<typeof UpdateViewDTOSchema>;

// ==========================================
// Module Management (Superadmin)
// ==========================================

export const CreateModuleDTOSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1),
  code: z.string().min(1),
  description: z.string().optional(),
});

export type CreateModuleDTO = z.infer<typeof CreateModuleDTOSchema>;

export const UpdateModuleDTOSchema = z.object({
  name: z.string().min(1).optional(),
  code: z.string().min(1).optional(),
  description: z.string().optional(),
});

export type UpdateModuleDTO = z.infer<typeof UpdateModuleDTOSchema>;

// ==========================================
// Feature Management (Superadmin)
// ==========================================

export const CreateFeatureDTOSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1),
  key: z.string().optional(),
  description: z.string().optional(),
});

export type CreateFeatureDTO = z.infer<typeof CreateFeatureDTOSchema>;

export const UpdateFeatureDTOSchema = z.object({
  name: z.string().min(1).optional(),
  key: z.string().optional(),
  description: z.string().optional(),
});

export type UpdateFeatureDTO = z.infer<typeof UpdateFeatureDTOSchema>;

// ==========================================
// Module-View Mapping (Superadmin)
// ==========================================

export const ReplaceModuleViewsDTOSchema = z.object({
  viewIds: z.array(z.string()),
});

export type ReplaceModuleViewsDTO = z.infer<typeof ReplaceModuleViewsDTOSchema>;

// ==========================================
// Company-Module Assignment (Superadmin)
// ==========================================

export const ReplaceCompanyModulesDTOSchema = z.object({
  moduleIds: z.array(z.string()),
});

export type ReplaceCompanyModulesDTO = z.infer<typeof ReplaceCompanyModulesDTOSchema>;

// ==========================================
// Menu Management (Superadmin - optional)
// ==========================================

export const CreateMenuItemDTOSchema = z.object({
  id: z.string().optional(),
  companyId: z.string().nullable().optional(),
  label: z.string().min(1),
  sequenceIndex: z.number().optional(),
  viewId: z.string().nullable().optional(),
  featureId: z.string().nullable().optional(),
  isEntrypoint: z.boolean().optional(),
  icon: z.string().optional(),
});

export type CreateMenuItemDTO = z.infer<typeof CreateMenuItemDTOSchema>;

export const UpdateMenuItemDTOSchema = z.object({
  label: z.string().min(1).optional(),
  sequenceIndex: z.number().optional(),
  viewId: z.string().nullable().optional(),
  featureId: z.string().nullable().optional(),
  isEntrypoint: z.boolean().optional(),
  icon: z.string().optional(),
});

export type UpdateMenuItemDTO = z.infer<typeof UpdateMenuItemDTOSchema>;

export const CreateSubMenuItemDTOSchema = z.object({
  id: z.string().optional(),
  companyId: z.string().nullable().optional(),
  menuItemId: z.string(),
  label: z.string().min(1),
  sequenceIndex: z.number().optional(),
  viewId: z.string().nullable().optional(),
  featureId: z.string().nullable().optional(),
});

export type CreateSubMenuItemDTO = z.infer<typeof CreateSubMenuItemDTOSchema>;

export const UpdateSubMenuItemDTOSchema = z.object({
  label: z.string().min(1).optional(),
  sequenceIndex: z.number().optional(),
  viewId: z.string().nullable().optional(),
  featureId: z.string().nullable().optional(),
});

export type UpdateSubMenuItemDTO = z.infer<typeof UpdateSubMenuItemDTOSchema>;

// ==========================================
// User Level Management (Client Admin)
// ==========================================

export const CreateUserLevelDTOSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(1),
  description: z.string().optional(),
});

export type CreateUserLevelDTO = z.infer<typeof CreateUserLevelDTOSchema>;

export const UpdateUserLevelDTOSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
});

export type UpdateUserLevelDTO = z.infer<typeof UpdateUserLevelDTOSchema>;

// ==========================================
// User Level - Features Matrix (Client Admin)
// ==========================================

export const UserLevelFeaturePermissionInputSchema = z.object({
  featureId: z.string(),
  action: z.string(), // e.g., "Create", "Update", "Delete"
  value: z.boolean(),
  scope: ActionScopeSchema.optional(),
  modifiable: z.boolean().optional(),
});

export type UserLevelFeaturePermissionInput = z.infer<typeof UserLevelFeaturePermissionInputSchema>;

export const ReplaceUserLevelFeaturesDTOSchema = z.object({
  features: z.array(UserLevelFeaturePermissionInputSchema),
});

export type ReplaceUserLevelFeaturesDTO = z.infer<typeof ReplaceUserLevelFeaturesDTOSchema>;

export const UpdateUserLevelFeatureDTOSchema = z.object({
  action: z.string().optional(),
  value: z.boolean().optional(),
  scope: ActionScopeSchema.optional(),
  modifiable: z.boolean().optional(),
});

export type UpdateUserLevelFeatureDTO = z.infer<typeof UpdateUserLevelFeatureDTOSchema>;

// ==========================================
// User Level - Views Matrix (Client Admin)
// ==========================================

export const UserLevelViewPermissionInputSchema = z.object({
  viewId: z.string(),
  state: PermissionStateSchema,
  modifiable: z.boolean().optional(),
});

export type UserLevelViewPermissionInput = z.infer<typeof UserLevelViewPermissionInputSchema>;

export const ReplaceUserLevelViewsDTOSchema = z.object({
  views: z.array(UserLevelViewPermissionInputSchema),
});

export type ReplaceUserLevelViewsDTO = z.infer<typeof ReplaceUserLevelViewsDTOSchema>;

export const UpdateUserLevelViewDTOSchema = z.object({
  state: PermissionStateSchema.optional(),
  modifiable: z.boolean().optional(),
});

export type UpdateUserLevelViewDTO = z.infer<typeof UpdateUserLevelViewDTOSchema>;

// ==========================================
// User - User Levels Assignment (Client Admin)
// ==========================================

export const ReplaceUserLevelsDTOSchema = z.object({
  userLevelIds: z.array(z.string()),
});

export type ReplaceUserLevelsDTO = z.infer<typeof ReplaceUserLevelsDTOSchema>;

// ==========================================
// Navigation API
// ==========================================

export const NavigationRequestSchema = z.object({
  companyId: z.string().optional(), // Derived from auth in most cases
});

export type NavigationRequest = z.infer<typeof NavigationRequestSchema>;

/**
 * Navigation response - filtered menu based on user permissions
 */
export const NavigationMenuItemSchema = z.object({
  id: z.string(),
  label: z.string(),
  icon: z.string().optional(),
  url: z.string().nullable(),
  isEntrypoint: z.boolean(),
  subItems: z
    .array(
      z.object({
        id: z.string(),
        label: z.string(),
        url: z.string().nullable(),
      })
    )
    .default([]),
});

export type NavigationMenuItem = z.infer<typeof NavigationMenuItemSchema>;

export const NavigationResponseSchema = z.object({
  menu: z.array(NavigationMenuItemSchema),
  entrypoint: z.string().nullable(), // First allowed entrypoint URL
});

export type NavigationResponse = z.infer<typeof NavigationResponseSchema>;

// ==========================================
// Current User Permissions API
// ==========================================

export const CurrentPermissionsResponseSchema = z.object({
  views: z.record(z.boolean()), // viewId -> allowed
  features: z.record(
    z.record(
      z.object({
        allowed: z.boolean(),
        scope: ActionScopeSchema,
      })
    )
  ), // featureId -> action -> { allowed, scope }
});

export type CurrentPermissionsResponse = z.infer<typeof CurrentPermissionsResponseSchema>;

// ==========================================
// Navigation Trail API
// ==========================================

export const TrackNavigationDTOSchema = z.object({
  viewId: z.string(),
  url: z.string(),
  sessionId: z.string(),
});

export type TrackNavigationDTO = z.infer<typeof TrackNavigationDTOSchema>;

export const NavTrailResponseSchema = z.object({
  trail: z.array(
    z.object({
      depth: z.number(),
      label: z.string(),
      url: z.string(),
    })
  ),
  recents: z.array(
    z.object({
      label: z.string(),
      url: z.string(),
      visitedAt: z.string().datetime(),
    })
  ),
});

export type NavTrailResponse = z.infer<typeof NavTrailResponseSchema>;
