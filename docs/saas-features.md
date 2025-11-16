

Admin side

Superadmin users (vendorsify) create, update and delete Views.
Superadmin users (vendorsify) create, update and delete Modules.
Superadmin users (vendorsify) create, update and delete relations Module/Views
Superadmin users (vendorsify) create, update and delete relations Modules to Companies.
Superadmin users (vendorsify) create, update and delete Features.



Client side

Admin users (client) create, update and delete User Levels.
Admin users (client) create, update and delete relations User Levels to Features.
Admin users (client) create, update and delete relations User Levels to Views.
Admin users (client) create, update and delete relations User to User Levels.








Use case 1: create a Module called Risks and assign only this Module to a Company that only bought that service. Render only Risks tab on menus.

Use case 2: create a User Level called Visitor that can access to every View but have restricted features: no creation, no deletion, only editing.



-- =========================================
-- Tipos ENUM
-- =========================================
CREATE TYPE permission_state AS ENUM ('allow','deny','inherit');
CREATE TYPE action_scope     AS ENUM ('any','own','team','company');

-- =========================================
-- Multi-tenant core
-- =========================================

CREATE TABLE companies (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  first_name    TEXT,
  last_name     TEXT,
  company_id    TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  state         TEXT DEFAULT 'active',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================
-- Product
-- =========================================

CREATE TABLE modules (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  code       TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE views (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  url        TEXT NOT NULL UNIQUE,       -- ruta interna
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE features (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,              -- INDEX lógico
  key        TEXT UNIQUE,                -- opcional: clave estable (p.ej. "risks.edit")
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Explicit relation Feature <-> View (N:M)
CREATE TABLE features2_views (
  feature_id TEXT NOT NULL REFERENCES features(id) ON DELETE CASCADE,
  view_id    TEXT NOT NULL REFERENCES views(id)    ON DELETE CASCADE,
  PRIMARY KEY (feature_id, view_id)
);

-- Modules -> Views (N:M)
CREATE TABLE modules2_views (
  module_id TEXT NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  view_id   TEXT NOT NULL REFERENCES views(id)   ON DELETE CASCADE,
  PRIMARY KEY (module_id, view_id)
);

-- Companies -> Modules (N:M)
CREATE TABLE companies2_modules (
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  module_id  TEXT NOT NULL REFERENCES modules(id)   ON DELETE CASCADE,
  PRIMARY KEY (company_id, module_id)
);

-- (Opcional) Módulos -> Features (N:M) para ocultar acciones de módulos no comprados
CREATE TABLE modules2_features (
  module_id  TEXT NOT NULL REFERENCES modules(id)  ON DELETE CASCADE,
  feature_id TEXT NOT NULL REFERENCES features(id) ON DELETE CASCADE,
  PRIMARY KEY (module_id, feature_id)
);




-- =========================================
-- Menú (by tenant) + entrypoint
-- =========================================
CREATE TABLE menu_items (
  id             TEXT PRIMARY KEY,
  company_id     TEXT REFERENCES companies(id) ON DELETE CASCADE, -- null = global
  label          TEXT NOT NULL,
  sequence_index INT  NOT NULL DEFAULT 0,
  view_id        TEXT REFERENCES views(id) ON DELETE SET NULL,
  feature_id     TEXT REFERENCES features(id) ON DELETE SET NULL,
  is_entrypoint  BOOLEAN NOT NULL DEFAULT TRUE,
  icon           TEXT,                                            -- opcional
  UNIQUE (company_id, label)
);

CREATE INDEX menu_items_company_seq_idx ON menu_items(company_id, sequence_index);

CREATE TABLE sub_menu_items (
  id             TEXT PRIMARY KEY,
  company_id     TEXT REFERENCES companies(id) ON DELETE CASCADE, -- null = global
  menu_item_id   TEXT NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
  label          TEXT NOT NULL,
  sequence_index INT  NOT NULL DEFAULT 0,
  view_id        TEXT REFERENCES views(id) ON DELETE SET NULL,
  feature_id     TEXT REFERENCES features(id) ON DELETE SET NULL,
  UNIQUE (menu_item_id, label)
);

CREATE INDEX sub_menu_items_parent_seq_idx ON sub_menu_items(menu_item_id, sequence_index);

-- =========================================
-- RBAC por cliente
-- =========================================
CREATE TABLE user_levels (
  id          TEXT PRIMARY KEY,
  company_id  TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, name)
);

-- Usuarios <-> Niveles (N:M)
CREATE TABLE users2_user_levels (
  user_id       TEXT NOT NULL REFERENCES users(id)       ON DELETE CASCADE,
  user_level_id TEXT NOT NULL REFERENCES user_levels(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, user_level_id)
);

-- Niveles <-> Vistas (tri-estado)
CREATE TABLE user_levels2_views (
  company_id    TEXT NOT NULL REFERENCES companies(id)  ON DELETE CASCADE,
  user_level_id TEXT NOT NULL REFERENCES user_levels(id) ON DELETE CASCADE,
  view_id       TEXT NOT NULL REFERENCES views(id)       ON DELETE CASCADE,
  state         permission_state NOT NULL DEFAULT 'inherit', -- allow/deny/inherit
  modifiable    BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (company_id, user_level_id, view_id)
);

CREATE INDEX ulv_view_idx ON user_levels2_views(view_id);

-- Niveles <-> Features (acciones extensibles + scope)
CREATE TABLE user_levels2_features (
  company_id    TEXT NOT NULL REFERENCES companies(id)  ON DELETE CASCADE,
  user_level_id TEXT NOT NULL REFERENCES user_levels(id) ON DELETE CASCADE,
  feature_id    TEXT NOT NULL REFERENCES features(id)     ON DELETE CASCADE,
  action        TEXT NOT NULL,                             -- p.ej. 'Create','Update','Delete','Export','Approve',...
  value         BOOLEAN NOT NULL DEFAULT FALSE,
  scope         action_scope NOT NULL DEFAULT 'any',
  modifiable    BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (company_id, user_level_id, feature_id, action)
);

CREATE INDEX ulf_feature_idx ON user_levels2_features(feature_id);

-- =========================================
-- Pila de navegación (por sesión/pestaña)
-- =========================================
CREATE TABLE nav_trail (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,                         -- cookie por pestaña
  depth      INT  NOT NULL,                         -- 0..N
  view_id    TEXT NOT NULL REFERENCES views(id)     ON DELETE CASCADE,
  url        TEXT NOT NULL,                         -- guarda solo path y query no sensible
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, company_id, session_id, depth)
);

CREATE INDEX nav_trail_session_idx ON nav_trail(user_id, session_id);
CREATE INDEX nav_trail_view_idx    ON nav_trail(view_id);

-- =========================================
-- (Opcional) Permisos efectivos cacheados
-- =========================================
CREATE TABLE effective_view_perms (
  user_id    TEXT NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  company_id TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  view_id    TEXT NOT NULL REFERENCES views(id)     ON DELETE CASCADE,
  allowed    BOOLEAN NOT NULL,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, company_id, view_id)
);

CREATE TABLE effective_feature_perms (
  user_id     TEXT NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  company_id  TEXT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  feature_id  TEXT NOT NULL REFERENCES features(id)  ON DELETE CASCADE,
  action      TEXT NOT NULL,
  value       BOOLEAN NOT NULL,
  scope       action_scope NOT NULL DEFAULT 'any',
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, company_id, feature_id, action)
);

-- =========================================
-- Reglas de integridad sugeridas (triggers opcionales)
-- =========================================
-- 1) Alinear company_id entre user_levels2_* y su user_level (mismo tenant).
--    Puedes implementar triggers que validen que user_levels2_views.company_id = (SELECT company_id FROM user_levels WHERE id=user_level_id)
-- 2) Limitar longitud de nav_trail por sesión (p.ej., 30 niveles) mediante trigger.






















Superadmin (vendorsify) views
Views Manager – create/update/delete entries in views.
Modules Manager – create/update/delete entries in Modules.
Module ↔ View Mapping – manage relations between Modules and Views.
Company ↔ Module Assignment – manage which Modules each Company has.
Features Manager – create/update/delete entries in features.
Menu Items Manager – manage menuItems tied to featureId.
Sub-menu Items Manager – manage subMenuItems tied to menuItemId/featureId.
Client Admin (per company) views
User Levels Manager – create/update/delete userLevels.
User Level ↔ Features Matrix – toggle Create/Update/Delete per featureId (userLevels2Features).
User Level ↔ Views Matrix – toggle access per viewId (userLevels2Views)
User ↔ User Levels Assignment – assign users to one or more userLevels.




1) Views Manager
GET /sa/views — list (paginate/filter).
POST /sa/views — create { id?, name, url }.
GET /sa/views/:viewId — read.
PATCH /sa/views/:viewId — update { name?, url? }.
DELETE /sa/views/:viewId — delete.
2) Modules Manager
GET /sa/modules
POST /sa/modules — create { id?, name, code }.
GET /sa/modules/:moduleId
PATCH /sa/modules/:moduleId
DELETE /sa/modules/:moduleId




3) Module ↔ View Mapping
GET /sa/modules/:moduleId/views — views in module.
PUT /sa/modules/:moduleId/views — replace set { viewIds: string[] }.
POST /sa/modules/:moduleId/views/:viewId — add one.
DELETE /sa/modules/:moduleId/views/:viewId — remove one.


4) Company ↔ Module Assignment
GET /sa/companies/:companyId/modules
PUT /sa/companies/:companyId/modules — replace set { moduleIds: string[] }.
POST /sa/companies/:companyId/modules/:moduleId
DELETE /sa/companies/:companyId/modules/:moduleId


5) Features Manager
GET /sa/features
POST /sa/features — { id?, name, url }
GET /sa/features/:featureId
PATCH /sa/features/:featureId
DELETE /sa/features/:featureId


6) Menu Items Manager (optional)
GET /sa/menu-items
POST /sa/menu-items — { id?, featureId, sequenceIndex, label }
GET /sa/menu-items/:menuItemId
PATCH /sa/menu-items/:menuItemId
DELETE /sa/menu-items/:menuItemId





7) Sub-menu Items Manager (optional)
GET /sa/sub-menu-items
POST /sa/sub-menu-items — { id?, menuItemId, featureId, sequenceIndex, label }
GET /sa/sub-menu-items/:subMenuItemId
PATCH /sa/sub-menu-items/:subMenuItemId
DELETE /sa/sub-menu-items/:subMenuItemId



Client Admin (per company)
All these should be tenant-scoped (derive companyId from auth or path).
8) User Levels Manager
GET /client/user-levels
POST /client/user-levels — { id?, name, description }
GET /client/user-levels/:userLevelId
PATCH /client/user-levels/:userLevelId
DELETE /client/user-levels/:userLevelId


9) User Level ↔ Features Matrix (userLevels2Features)
GET /client/user-levels/:userLevelId/features — list matrix.
PUT /client/user-levels/:userLevelId/features — replace array:
 [{ "featureId":"...", "type":"Create|Update|Delete", "value":true, "modifiable":true }]
PATCH /client/user-levels/:userLevelId/features/:featureId — partial update (optionally with type in body).




10) User Level ↔ Views Matrix (userLevels2Views)
GET /client/user-levels/:userLevelId/views
PUT /client/user-levels/:userLevelId/views — replace array:
 [{ "viewId":"...", "value":true, "modifiable":true }]
PATCH /client/user-levels/:userLevelId/views/:viewId — { value?, modifiable? }


11) User ↔ User Levels Assignment
GET /client/users/:userId/user-levels
PUT /client/users/:userId/user-levels — { userLevelIds: string[] }
POST /client/users/:userId/user-levels/:userLevelId
DELETE /client/users/:userId/user-levels/:userLevelId








Implementation plan (whole solution)
Phase 0 — Readiness & flags
Create a feature flag: iam_v2_enabled (tenant-scoped).


Decide default policy: “deny by default unless explicitly allowed”.


Phase 1 — Data model & migrations
Add/verify tables: user_levels, users2_user_levels, user_levels2_views(state: allow/deny/inherit), user_levels2_features(action, value, scope), features2_views, modules2_views, companies2_modules, menu_items, sub_menu_items, nav_trail, audit_log (optional), user_favorites (optional).


Indexes/constraints (FKs, UNIQUE composites) per earlier schema.


Backfill scripts for existing data (map legacy roles → user_levels; assign users).


Phase 2 — Seed & admin bootstrapping
Seed baseline Features, Views, Modules (+ mappings).


Seed default User Levels per tenant (e.g., Admin, Member, Visitor).


Seed menu per tenant (or global default).


Phase 3 — Core permission engine
Build permission resolution (effective allow for views; feature action+scope merge across multiple levels; deny > allow > inherit).


Build authorize() middleware for API routes (view access, feature action).


Add module gating (company owns module?).


Phase 4 — APIs (CRUD & matrices)
Superadmin: Views, Modules, Features, Mappings (modules↔views, features↔views), Company↔Modules.


Client admin: User Levels CRUD; Level↔Views matrix; Level↔Features matrix; Users↔Levels.


Read APIs: /api/navigation (tenant/menu/permission-filtered), /api/iam/permissions/current.


Navigation trail: /api/navtrail/track, /api/navtrail (trail/top/recents).


Phase 5 — Frontend integration
Replace hardcoded sidebar with /api/navigation.


Add global Permissions store/hook; Gate/GateButton components; route guards.


Client Admin UI:
 User Levels Manager, Level↔Views matrix, Level↔Features matrix, User↔Levels assignment.


Navigation UX: Breadcrumbs + “Continue where I left off” + Recents; Back button via nav_trail.


Phase 6 — Security, caching, performance
Enforce auth + tenant everywhere.


ETag/short TTL for /api/navigation; cache effective perms (optional).


Audit log writes for IAM edits and sensitive actions (exports, trials).


Phase 7 — Testing
Unit tests: resolver, middleware, SQL scopes.


Integration: endpoint auth paths (200/403).


E2E happy paths for 2–3 roles across 2 tenants.


Phase 8 — Rollout
Dark-launch behind iam_v2_enabled for internal tenant.


Expand to a pilot tenant; monitor logs; fix.


Enable broadly; remove old guards.


