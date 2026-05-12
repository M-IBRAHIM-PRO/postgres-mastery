-- ============================================================
-- Day 5 Seed (extended): users, organizations, memberships,
-- projects, invitations, tasks, activity_log.
--
-- Run:
--   psql -d teamsync -f hands-on/sql/seeds/day-05.sql
-- ============================================================

BEGIN;

-- TRUNCATE order: children first, then parents.
-- activity_log has no FK constraints; truncate it independently.
TRUNCATE TABLE
  projects.tasks,
  projects.projects,
  auth.invitations,
  auth.memberships,
  auth.organizations,
  auth.users
RESTART IDENTITY CASCADE;

TRUNCATE TABLE events.activity_log RESTART IDENTITY;

-- ------------------------------------------------------------
-- USERS (20)
-- Mix of active/inactive, varied timezones, varied themes
-- ------------------------------------------------------------
INSERT INTO auth.users (
  id, public_id, email, full_name, is_active, preferences, created_at
)
VALUES
  ( 1, '11111111-1111-1111-1111-111111111111', 'ibrahim@teamsync.dev', 'Muhammad Ibrahim', true,
    '{"theme":"dark","timezone":"Asia/Karachi"}',     '2025-01-05 09:00:00+00'),
  ( 2, '22222222-2222-2222-2222-222222222222', 'sarah@teamsync.dev',   'Sarah Khan',       true,
    '{"theme":"light","timezone":"Asia/Karachi"}',    '2025-01-12 10:30:00+00'),
  ( 3, '33333333-3333-3333-3333-333333333333', 'ali@teamsync.dev',     'Ali Raza',         true,
    '{"theme":"dark","timezone":"UTC"}',              '2025-02-01 08:15:00+00'),
  ( 4, '44444444-4444-4444-4444-444444444444', 'fatima@teamsync.dev',  'Fatima Noor',      false,
    '{"theme":"light","timezone":"Europe/Berlin"}',   '2025-02-14 14:00:00+00'),
  ( 5, '55555555-5555-5555-5555-555555555555', 'john@teamsync.dev',    'John Carter',      true,
    '{"theme":"dark","timezone":"America/New_York"}', '2025-02-20 16:45:00+00'),
  ( 6, '66666666-6666-6666-6666-666666666666', 'hina@teamsync.dev',    'Hina Malik',       true,
    '{"theme":"light","timezone":"Asia/Karachi"}',    '2025-03-02 11:20:00+00'),
  ( 7, '77777777-7777-7777-7777-777777777777', 'omar@teamsync.dev',    'Omar Siddiqui',    true,
    '{"theme":"dark","timezone":"Asia/Dubai"}',       '2025-03-10 09:50:00+00'),
  ( 8, '88888888-8888-8888-8888-888888888888', 'priya@teamsync.dev',   'Priya Sharma',     true,
    '{"theme":"light","timezone":"Asia/Kolkata"}',    '2025-03-18 13:05:00+00'),
  ( 9, '99999999-9999-9999-9999-999999999999', 'lucas@teamsync.dev',   'Lucas Meyer',      true,
    '{"theme":"dark","timezone":"Europe/Berlin"}',    '2025-03-25 08:00:00+00'),
  (10, 'aaaaaaa1-0000-0000-0000-000000000010', 'emma@teamsync.dev',    'Emma Wilson',      true,
    '{"theme":"light","timezone":"Europe/London"}',   '2025-04-02 15:30:00+00'),
  (11, 'aaaaaaa1-0000-0000-0000-000000000011', 'noah@teamsync.dev',    'Noah Schmidt',     true,
    '{"theme":"dark","timezone":"Europe/Berlin"}',    '2025-04-08 10:10:00+00'),
  (12, 'aaaaaaa1-0000-0000-0000-000000000012', 'aisha@teamsync.dev',   'Aisha Iqbal',      true,
    '{"theme":"light","timezone":"Asia/Karachi"}',    '2025-04-15 12:45:00+00'),
  (13, 'aaaaaaa1-0000-0000-0000-000000000013', 'daniel@teamsync.dev',  'Daniel Park',      true,
    '{"theme":"dark","timezone":"America/Los_Angeles"}', '2025-04-22 17:00:00+00'),
  (14, 'aaaaaaa1-0000-0000-0000-000000000014', 'mei@teamsync.dev',     'Mei Tanaka',       true,
    '{"theme":"light","timezone":"Asia/Tokyo"}',      '2025-05-01 07:30:00+00'),
  (15, 'aaaaaaa1-0000-0000-0000-000000000015', 'bilal@teamsync.dev',   'Bilal Ahmed',      false,
    '{"theme":"dark","timezone":"Asia/Karachi"}',     '2025-05-09 14:25:00+00'),
  (16, 'aaaaaaa1-0000-0000-0000-000000000016', 'sofia@teamsync.dev',   'Sofia Rossi',      true,
    '{"theme":"light","timezone":"Europe/Rome"}',     '2025-05-18 09:15:00+00'),
  (17, 'aaaaaaa1-0000-0000-0000-000000000017', 'kai@teamsync.dev',     'Kai Andersen',     true,
    '{"theme":"dark","timezone":"Europe/Oslo"}',      '2025-05-27 11:55:00+00'),
  (18, 'aaaaaaa1-0000-0000-0000-000000000018', 'zara@teamsync.dev',    'Zara Hussain',     true,
    '{"theme":"light","timezone":"Asia/Karachi"}',    '2025-06-03 13:40:00+00'),
  (19, 'aaaaaaa1-0000-0000-0000-000000000019', 'tom@teamsync.dev',     'Tom Becker',       false,
    '{"theme":"dark","timezone":"Europe/Berlin"}',    '2025-06-12 16:20:00+00'),
  (20, 'aaaaaaa1-0000-0000-0000-000000000020', 'maya@teamsync.dev',    'Maya Patel',       true,
    '{"theme":"light","timezone":"Asia/Kolkata"}',    '2025-06-20 08:50:00+00');

-- ------------------------------------------------------------
-- ORGANIZATIONS (7)
-- ------------------------------------------------------------
INSERT INTO auth.organizations (id, public_id, name, created_at)
VALUES
  (1, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'TeamSync Labs',     '2025-01-01 09:00:00+00'),
  (2, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Northstar Studio',  '2025-01-15 10:00:00+00'),
  (3, 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Orbit Labs',        '2025-02-10 11:30:00+00'),
  (4, 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'BlueShift Inc',     '2025-03-05 14:20:00+00'),
  (5, 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Pioneer Tech',      '2025-04-01 09:45:00+00'),
  (6, 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Quantum Works',     '2025-05-12 13:10:00+00'),
  (7, 'aaaabbbb-cccc-dddd-eeee-ffff00000007', 'Echo Collective',   '2025-06-01 08:30:00+00');

-- ------------------------------------------------------------
-- MEMBERSHIPS (32)
-- ------------------------------------------------------------
INSERT INTO auth.memberships (id, organization_id, user_id, role, created_at)
VALUES
  ( 1, 1,  1, 'owner',  '2025-01-05 09:30:00+00'),
  ( 2, 1,  2, 'admin',  '2025-01-13 10:00:00+00'),
  ( 3, 1,  3, 'member', '2025-02-02 09:00:00+00'),
  ( 4, 1,  6, 'member', '2025-03-03 12:00:00+00'),
  ( 5, 1, 12, 'member', '2025-04-16 14:00:00+00'),
  ( 6, 1, 18, 'member', '2025-06-04 09:00:00+00'),
  ( 7, 2,  2, 'owner',  '2025-01-16 11:00:00+00'),
  ( 8, 2,  4, 'member', '2025-02-15 09:00:00+00'),
  ( 9, 2,  5, 'admin',  '2025-02-21 17:00:00+00'),
  (10, 2,  9, 'member', '2025-03-26 10:00:00+00'),
  (11, 2, 11, 'member', '2025-04-09 11:00:00+00'),
  (12, 3,  1, 'owner',  '2025-02-10 12:00:00+00'),
  (13, 3,  7, 'admin',  '2025-03-11 10:00:00+00'),
  (14, 3,  8, 'member', '2025-03-19 13:30:00+00'),
  (15, 3, 14, 'member', '2025-05-02 08:00:00+00'),
  (16, 3, 20, 'member', '2025-06-21 09:30:00+00'),
  (17, 4,  5, 'owner',  '2025-03-05 15:00:00+00'),
  (18, 4, 10, 'admin',  '2025-04-03 16:00:00+00'),
  (19, 4, 13, 'member', '2025-04-23 09:00:00+00'),
  (20, 5,  3, 'owner',  '2025-04-01 10:00:00+00'),
  (21, 5, 16, 'admin',  '2025-05-19 10:00:00+00'),
  (22, 5, 17, 'member', '2025-05-28 12:00:00+00'),
  (23, 6,  9, 'owner',  '2025-05-12 14:00:00+00'),
  (24, 6, 19, 'member', '2025-06-13 17:00:00+00'),
  (25, 7,  6, 'owner',  '2025-06-01 09:00:00+00'),
  (26, 7, 12, 'member', '2025-06-02 11:00:00+00'),
  (27, 7, 18, 'member', '2025-06-05 14:00:00+00'),
  (28, 3,  2, 'member', '2025-03-15 10:00:00+00'),
  (29, 4,  1, 'member', '2025-04-05 09:00:00+00'),
  (30, 5, 12, 'member', '2025-05-20 11:00:00+00'),
  (31, 1,  7, 'member', '2025-04-12 13:00:00+00'),
  (32, 2,  8, 'member', '2025-04-22 15:00:00+00');

-- ------------------------------------------------------------
-- PROJECTS (30)
-- Echo Collective (org 7) intentionally has 0 projects
-- ------------------------------------------------------------
INSERT INTO projects.projects (
  id, public_id, organization_id, created_by, name, description, metadata, created_at
)
VALUES
  -- TeamSync Labs (org 1) - 8 projects
  ( 1, 'aaaa0000-0000-0000-0000-000000000001', 1,  1, 'Billing API',
    'Subscriptions and invoices.',
    '{"status":"active","priority":"high","budget":50000}',     '2025-01-10 10:00:00+00'),
  ( 2, 'aaaa0000-0000-0000-0000-000000000002', 1,  2, 'Analytics Dashboard',
    'Internal product metrics dashboard.',
    '{"status":"planning","priority":"medium","budget":25000}', '2025-01-25 11:30:00+00'),
  ( 3, 'aaaa0000-0000-0000-0000-000000000003', 1,  3, 'Auth Service',
    'Authentication and session management.',
    '{"status":"active","priority":"high","budget":35000}',     '2025-02-12 14:00:00+00'),
  ( 4, 'aaaa0000-0000-0000-0000-000000000004', 1,  1, 'Notifications Service',
    'Email and push notifications.',
    '{"status":"active","priority":"medium","budget":20000}',   '2025-03-05 09:30:00+00'),
  ( 5, 'aaaa0000-0000-0000-0000-000000000005', 1,  6, 'Onboarding Flow',
    'New user onboarding wizard.',
    '{"status":"review","priority":"medium","budget":15000}',   '2025-03-20 16:00:00+00'),
  ( 6, 'aaaa0000-0000-0000-0000-000000000006', 1,  2, 'Data Export Tool',
    'Export user data to CSV and JSON.',
    '{"status":"active","priority":"low","budget":10000}',      '2025-04-18 13:15:00+00'),
  ( 7, 'aaaa0000-0000-0000-0000-000000000007', 1, 12, 'Admin Console',
    'Internal admin tools.',
    '{"status":"planning","priority":"medium","budget":28000}', '2025-05-22 10:45:00+00'),
  ( 8, 'aaaa0000-0000-0000-0000-000000000008', 1,  1, 'Webhooks Platform',
    'Outbound webhook delivery system.',
    '{"status":"active","priority":"high","budget":40000}',     '2025-06-15 08:20:00+00'),

  -- Northstar Studio (org 2) - 6 projects
  ( 9, 'bbbb0000-0000-0000-0000-000000000009', 2,  2, 'Design System',
    'Reusable UI components.',
    '{"status":"active","priority":"medium","budget":18000}',   '2025-01-28 09:00:00+00'),
  (10, 'bbbb0000-0000-0000-0000-000000000010', 2,  4, 'Client Portal',
    'Workspace for clients.',
    '{"status":"review","priority":"high","budget":42000}',     '2025-02-22 14:30:00+00'),
  (11, 'bbbb0000-0000-0000-0000-000000000011', 2,  5, 'Asset Library',
    'Shared asset management.',
    '{"status":"active","priority":"medium","budget":22000}',   '2025-03-10 11:00:00+00'),
  (12, 'bbbb0000-0000-0000-0000-000000000012', 2,  9, 'Brand Site',
    'Marketing website refresh.',
    '{"status":"completed","priority":"high","budget":30000}',  '2025-04-15 10:00:00+00'),
  (13, 'bbbb0000-0000-0000-0000-000000000013', 2, 11, 'Newsletter Tool',
    'Internal newsletter automation.',
    '{"status":"active","priority":"low","budget":8000}',       '2025-05-05 15:30:00+00'),
  (14, 'bbbb0000-0000-0000-0000-000000000014', 2,  2, 'Portfolio Builder',
    'Drag-and-drop portfolio creator.',
    '{"status":"planning","priority":"medium","budget":26000}', '2025-06-18 09:45:00+00'),

  -- Orbit Labs (org 3) - 7 projects
  (15, 'cccc0000-0000-0000-0000-000000000015', 3,  1, 'Satellite Tracker',
    'Real-time satellite position tracking.',
    '{"status":"active","priority":"high","budget":65000}',     '2025-02-15 10:00:00+00'),
  (16, 'cccc0000-0000-0000-0000-000000000016', 3,  7, 'Telemetry Pipeline',
    'High-throughput telemetry ingestion.',
    '{"status":"active","priority":"high","budget":55000}',     '2025-03-15 13:00:00+00'),
  (17, 'cccc0000-0000-0000-0000-000000000017', 3,  8, 'Mission Planner',
    'Mission planning and scheduling.',
    '{"status":"planning","priority":"high","budget":48000}',   '2025-04-02 11:15:00+00'),
  (18, 'cccc0000-0000-0000-0000-000000000018', 3,  1, 'Ground Station UI',
    'Operator console for ground stations.',
    '{"status":"review","priority":"medium","budget":32000}',   '2025-04-25 14:30:00+00'),
  (19, 'cccc0000-0000-0000-0000-000000000019', 3, 14, 'Anomaly Detector',
    'ML-based anomaly detection.',
    '{"status":"active","priority":"high","budget":58000}',     '2025-05-08 10:30:00+00'),
  (20, 'cccc0000-0000-0000-0000-000000000020', 3,  2, 'Public API',
    'Public-facing satellite data API.',
    '{"status":"planning","priority":"medium","budget":38000}', '2025-05-30 12:00:00+00'),
  (21, 'cccc0000-0000-0000-0000-000000000021', 3, 20, 'Data Archive',
    'Long-term cold storage for telemetry.',
    '{"status":"active","priority":"low","budget":14000}',      '2025-06-25 09:00:00+00'),

  -- BlueShift Inc (org 4) - 4 projects
  (22, 'dddd0000-0000-0000-0000-000000000022', 4,  5, 'Inventory System',
    'Warehouse inventory management.',
    '{"status":"active","priority":"high","budget":45000}',     '2025-03-12 13:00:00+00'),
  (23, 'dddd0000-0000-0000-0000-000000000023', 4, 10, 'Shipping Module',
    'Multi-carrier shipping integration.',
    '{"status":"active","priority":"medium","budget":28000}',   '2025-04-10 10:30:00+00'),
  (24, 'dddd0000-0000-0000-0000-000000000024', 4, 13, 'Returns Portal',
    'Customer self-service returns.',
    '{"status":"review","priority":"medium","budget":18000}',   '2025-05-15 11:00:00+00'),
  (25, 'dddd0000-0000-0000-0000-000000000025', 4,  5, 'Tax Engine',
    'Tax calculation and reporting.',
    '{"status":"planning","priority":"high","budget":36000}',   '2025-06-22 14:00:00+00'),

  -- Pioneer Tech (org 5) - 3 projects
  (26, 'eeee0000-0000-0000-0000-000000000026', 5,  3, 'IoT Gateway',
    'Edge gateway for IoT devices.',
    '{"status":"active","priority":"high","budget":52000}',     '2025-04-08 09:00:00+00'),
  (27, 'eeee0000-0000-0000-0000-000000000027', 5, 16, 'Device Registry',
    'Device identity and provisioning.',
    '{"status":"active","priority":"medium","budget":24000}',   '2025-05-25 13:30:00+00'),
  (28, 'eeee0000-0000-0000-0000-000000000028', 5, 17, 'Firmware Updater',
    'OTA firmware update service.',
    '{"status":"planning","priority":"high","budget":31000}',   '2025-06-28 10:00:00+00'),

  -- Quantum Works (org 6) - 2 projects
  (29, 'ffff0000-0000-0000-0000-000000000029', 6,  9, 'QKD Simulator',
    'Quantum key distribution simulator.',
    '{"status":"planning","priority":"high","budget":40000}',   '2025-05-20 11:00:00+00'),
  (30, 'ffff0000-0000-0000-0000-000000000030', 6, 19, 'Lattice Solver',
    'Lattice-based crypto research tooling.',
    '{"status":"active","priority":"medium","budget":33000}',   '2025-06-14 15:00:00+00');

-- ------------------------------------------------------------
-- INVITATIONS (22)
-- Spread across orgs and all four statuses.
-- Tokens are unique by design (UNIQUE constraint).
-- pending  + future expires_at = still actionable
-- accepted + any expires_at    = converted to a membership
-- expired  + past expires_at   = timed out before acceptance
-- revoked  + any expires_at    = cancelled by org admin
-- ------------------------------------------------------------
INSERT INTO auth.invitations (
  id, organization_id, invited_by, email, token, status, expires_at, created_at
)
VALUES
  -- TeamSync Labs (org 1) — owner Ibrahim (1), admin Sarah (2)
  ( 1, 1,  1, 'recruit1@external.com',  'inv_tok_001', 'accepted', '2025-02-01 09:00:00+00', '2025-01-18 09:00:00+00'),
  ( 2, 1,  2, 'recruit2@external.com',  'inv_tok_002', 'accepted', '2025-03-15 09:00:00+00', '2025-02-28 09:00:00+00'),
  ( 3, 1,  1, 'declined1@external.com', 'inv_tok_003', 'expired',  '2025-04-10 09:00:00+00', '2025-03-25 09:00:00+00'),
  ( 4, 1,  2, 'pending1@external.com',  'inv_tok_004', 'pending',  '2026-07-15 09:00:00+00', '2025-06-25 09:00:00+00'),
  ( 5, 1,  1, 'revoked1@external.com',  'inv_tok_005', 'revoked',  '2025-05-20 09:00:00+00', '2025-05-05 09:00:00+00'),

  -- Northstar Studio (org 2) — owner Sarah (2), admin John (5)
  ( 6, 2,  2, 'designer1@external.com', 'inv_tok_006', 'accepted', '2025-02-25 09:00:00+00', '2025-02-10 09:00:00+00'),
  ( 7, 2,  5, 'designer2@external.com', 'inv_tok_007', 'accepted', '2025-03-30 09:00:00+00', '2025-03-15 09:00:00+00'),
  ( 8, 2,  2, 'studio_apply@external.com', 'inv_tok_008', 'pending',  '2026-07-20 09:00:00+00', '2025-06-30 09:00:00+00'),
  ( 9, 2,  5, 'studio_old@external.com',   'inv_tok_009', 'expired',  '2025-04-15 09:00:00+00', '2025-03-30 09:00:00+00'),

  -- Orbit Labs (org 3) — owner Ibrahim (1), admin Omar (7)
  (10, 3,  1, 'engineer1@external.com', 'inv_tok_010', 'accepted', '2025-03-25 09:00:00+00', '2025-03-10 09:00:00+00'),
  (11, 3,  7, 'engineer2@external.com', 'inv_tok_011', 'accepted', '2025-04-05 09:00:00+00', '2025-03-20 09:00:00+00'),
  (12, 3,  1, 'engineer3@external.com', 'inv_tok_012', 'pending',  '2026-07-25 09:00:00+00', '2025-07-01 09:00:00+00'),
  (13, 3,  7, 'engineer4@external.com', 'inv_tok_013', 'pending',  '2026-08-01 09:00:00+00', '2025-07-05 09:00:00+00'),
  (14, 3,  1, 'orbit_old@external.com', 'inv_tok_014', 'expired',  '2025-05-01 09:00:00+00', '2025-04-15 09:00:00+00'),

  -- BlueShift Inc (org 4) — owner John (5), admin Emma (10)
  (15, 4,  5, 'ops1@external.com',      'inv_tok_015', 'accepted', '2025-04-20 09:00:00+00', '2025-04-05 09:00:00+00'),
  (16, 4, 10, 'ops2@external.com',      'inv_tok_016', 'revoked',  '2025-05-25 09:00:00+00', '2025-05-10 09:00:00+00'),
  (17, 4,  5, 'ops3@external.com',      'inv_tok_017', 'pending',  '2026-07-10 09:00:00+00', '2025-06-20 09:00:00+00'),

  -- Pioneer Tech (org 5) — owner Ali (3), admin Sofia (16)
  (18, 5,  3, 'iot_dev1@external.com',  'inv_tok_018', 'accepted', '2025-05-22 09:00:00+00', '2025-05-07 09:00:00+00'),
  (19, 5, 16, 'iot_dev2@external.com',  'inv_tok_019', 'pending',  '2026-07-30 09:00:00+00', '2025-07-02 09:00:00+00'),

  -- Quantum Works (org 6) — owner Lucas (9)
  (20, 6,  9, 'physicist1@external.com','inv_tok_020', 'expired',  '2025-06-15 09:00:00+00', '2025-05-30 09:00:00+00'),
  (21, 6,  9, 'physicist2@external.com','inv_tok_021', 'pending',  '2026-08-05 09:00:00+00', '2025-07-10 09:00:00+00'),

  -- Echo Collective (org 7) — owner Hina (6)
  (22, 7,  6, 'collab1@external.com',   'inv_tok_022', 'pending',  '2026-07-18 09:00:00+00', '2025-06-28 09:00:00+00');

-- ------------------------------------------------------------
-- TASKS (60)
-- Spread across 12 projects (others intentionally have no tasks
-- so LEFT JOIN / COALESCE / "projects with no tasks" queries work).
-- All four statuses are represented. Some tasks are unassigned
-- (assignee_id IS NULL) — important for GROUPING() examples.
-- Assignees are always members of the project's organization.
-- ------------------------------------------------------------
INSERT INTO projects.tasks (
  id, project_id, title, status, assignee_id, due_date, created_at
)
VALUES
  -- Project 1: Billing API (org 1) — 8 tasks
  ( 1,  1, 'Design subscription schema',     'done',         1, '2025-01-20', '2025-01-11 09:00:00+00'),
  ( 2,  1, 'Implement invoice generator',    'done',         3, '2025-02-05', '2025-01-15 10:00:00+00'),
  ( 3,  1, 'Stripe integration',             'in_progress',  1, '2025-03-15', '2025-02-01 11:00:00+00'),
  ( 4,  1, 'Refund flow',                    'todo',         2, '2025-08-01', '2025-04-10 12:00:00+00'),
  ( 5,  1, 'Failed-payment retry logic',     'todo',         3, '2025-08-15', '2025-05-01 09:30:00+00'),
  ( 6,  1, 'Dunning emails',                 'todo',      NULL, '2025-09-01', '2025-05-20 10:00:00+00'),
  ( 7,  1, 'Tax calculation hooks',          'cancelled',    1, NULL,         '2025-03-12 13:00:00+00'),
  ( 8,  1, 'Audit log integration',          'in_progress',  6, '2025-08-20', '2025-06-01 14:00:00+00'),

  -- Project 2: Analytics Dashboard (org 1) — 5 tasks
  ( 9,  2, 'Pick charting library',          'done',         2, '2025-02-01', '2025-01-26 09:00:00+00'),
  (10,  2, 'Build retention chart',          'in_progress',  2, '2025-07-30', '2025-04-05 10:00:00+00'),
  (11,  2, 'Wire up funnel queries',         'todo',        12, '2025-08-10', '2025-05-15 11:00:00+00'),
  (12,  2, 'Cohort drilldown',               'todo',      NULL, '2025-09-15', '2025-06-01 09:00:00+00'),
  (13,  2, 'Old prototype cleanup',          'cancelled', NULL, NULL,         '2025-02-10 14:00:00+00'),

  -- Project 3: Auth Service (org 1) — 6 tasks
  (14,  3, 'JWT signing helper',             'done',         3, '2025-02-25', '2025-02-13 09:00:00+00'),
  (15,  3, 'Password reset flow',            'done',         3, '2025-03-15', '2025-02-20 10:00:00+00'),
  (16,  3, 'OAuth2 provider support',        'in_progress',  3, '2025-08-01', '2025-04-01 11:00:00+00'),
  (17,  3, 'MFA support',                    'todo',         2, '2025-09-10', '2025-05-15 12:00:00+00'),
  (18,  3, 'Session revocation',             'todo',         3, '2025-08-25', '2025-06-05 09:00:00+00'),
  (19,  3, 'Legacy v1 endpoint removal',     'cancelled',    2, NULL,         '2025-03-08 15:00:00+00'),

  -- Project 4: Notifications Service (org 1) — 3 tasks
  (20,  4, 'SMTP provider abstraction',      'done',         1, '2025-04-01', '2025-03-06 09:00:00+00'),
  (21,  4, 'Push notification SDK',          'in_progress',  6, '2025-07-25', '2025-04-15 10:00:00+00'),
  (22,  4, 'Per-user quiet hours',           'todo',      NULL, '2025-09-05', '2025-06-10 11:00:00+00'),

  -- Project 9: Design System (org 2) — 6 tasks
  (23,  9, 'Color tokens',                   'done',         4, '2025-02-10', '2025-01-29 09:00:00+00'),
  (24,  9, 'Typography scale',               'done',         9, '2025-02-25', '2025-02-05 10:00:00+00'),
  (25,  9, 'Button component',               'done',        11, '2025-03-15', '2025-02-20 11:00:00+00'),
  (26,  9, 'Form components',                'in_progress',  4, '2025-07-20', '2025-04-10 09:00:00+00'),
  (27,  9, 'Data table component',           'todo',         9, '2025-08-30', '2025-05-22 14:00:00+00'),
  (28,  9, 'Storybook setup',                'todo',      NULL, '2025-09-10', '2025-06-05 15:00:00+00'),

  -- Project 10: Client Portal (org 2) — 4 tasks
  (29, 10, 'Login screen',                   'done',         4, '2025-03-10', '2025-02-23 09:00:00+00'),
  (30, 10, 'Project list view',              'in_progress', 11, '2025-07-15', '2025-04-05 10:00:00+00'),
  (31, 10, 'File upload widget',             'todo',         5, '2025-08-05', '2025-05-10 11:00:00+00'),
  (32, 10, 'Client feedback inbox',          'todo',      NULL, '2025-09-20', '2025-06-15 12:00:00+00'),

  -- Project 15: Satellite Tracker (org 3) — 7 tasks
  (33, 15, 'TLE parser',                     'done',         1, '2025-03-01', '2025-02-16 09:00:00+00'),
  (34, 15, 'Orbit propagator',               'done',         7, '2025-04-01', '2025-03-01 10:00:00+00'),
  (35, 15, 'Pass prediction',                'in_progress', 14, '2025-07-20', '2025-04-10 11:00:00+00'),
  (36, 15, '3D globe view',                  'in_progress',  8, '2025-08-15', '2025-05-05 12:00:00+00'),
  (37, 15, 'Ground track overlay',           'todo',         1, '2025-09-01', '2025-06-01 13:00:00+00'),
  (38, 15, 'Mobile responsive layout',       'todo',      NULL, '2025-09-25', '2025-06-20 14:00:00+00'),
  (39, 15, 'Old Cesium experiment',          'cancelled', NULL, NULL,         '2025-03-15 15:00:00+00'),

  -- Project 16: Telemetry Pipeline (org 3) — 5 tasks
  (40, 16, 'Kafka topic design',             'done',         7, '2025-04-01', '2025-03-16 09:00:00+00'),
  (41, 16, 'Schema registry integration',    'done',         2, '2025-05-01', '2025-04-05 10:00:00+00'),
  (42, 16, 'Batch backfill tool',            'in_progress', 20, '2025-08-10', '2025-05-15 11:00:00+00'),
  (43, 16, 'Dead-letter queue',              'todo',      NULL, '2025-09-15', '2025-06-10 12:00:00+00'),
  (44, 16, 'Throughput benchmarks',          'todo',         7, '2025-08-30', '2025-06-25 13:00:00+00'),

  -- Project 22: Inventory System (org 4) — 5 tasks
  (45, 22, 'SKU model',                      'done',         5, '2025-03-25', '2025-03-13 09:00:00+00'),
  (46, 22, 'Stock movement log',             'done',        10, '2025-04-20', '2025-04-01 10:00:00+00'),
  (47, 22, 'Barcode scanner integration',    'in_progress', 13, '2025-08-05', '2025-05-10 11:00:00+00'),
  (48, 22, 'Low-stock alerts',               'todo',         5, '2025-09-10', '2025-06-05 12:00:00+00'),
  (49, 22, 'Multi-warehouse support',        'todo',      NULL, '2025-10-01', '2025-06-25 13:00:00+00'),

  -- Project 26: IoT Gateway (org 5) — 4 tasks
  (50, 26, 'MQTT broker setup',              'done',         3, '2025-04-25', '2025-04-09 09:00:00+00'),
  (51, 26, 'Device auth',                    'in_progress', 16, '2025-08-01', '2025-05-15 10:00:00+00'),
  (52, 26, 'Edge caching',                   'todo',        17, '2025-09-01', '2025-06-10 11:00:00+00'),
  (53, 26, 'Bandwidth monitor',              'todo',      NULL, '2025-09-20', '2025-06-25 12:00:00+00'),

  -- Project 29: QKD Simulator (org 6) — 3 tasks
  (54, 29, 'BB84 protocol skeleton',         'in_progress',  9, '2025-08-15', '2025-05-21 09:00:00+00'),
  (55, 29, 'Eavesdropper simulation',        'todo',         9, '2025-09-15', '2025-06-10 10:00:00+00'),
  (56, 29, 'Visualization dashboard',        'todo',      NULL, '2025-10-01', '2025-06-25 11:00:00+00'),

  -- Project 30: Lattice Solver (org 6) — 2 tasks
  (57, 30, 'Vector basis reduction',         'in_progress', 19, '2025-08-20', '2025-06-15 09:00:00+00'),
  (58, 30, 'CVP attack benchmark',           'todo',      NULL, '2025-09-30', '2025-06-28 10:00:00+00'),

  -- A couple of tasks deep in the past, fully done
  (59,  1, 'Initial API skeleton',           'done',         1, '2025-01-15', '2025-01-11 08:00:00+00'),
  (60,  9, 'Design audit',                   'done',         2, '2025-02-05', '2025-01-30 08:00:00+00');

-- ------------------------------------------------------------
-- ACTIVITY LOG (40)
-- All rows land in events.activity_log_default partition.
-- Mix of event_types, varied actors and orgs, JSONB payloads.
-- Great for window functions over time, GROUP BY event_type,
-- and time-bucketed reports (DATE_TRUNC).
-- ------------------------------------------------------------
INSERT INTO events.activity_log (
  occurred_at, actor_id, organization_id, event_type, payload
)
VALUES
  ('2025-01-05 09:05:00+00',  1, 1, 'user.signed_up',        '{"source":"website"}'),
  ('2025-01-05 09:30:00+00',  1, 1, 'organization.created',  '{"plan":"pro"}'),
  ('2025-01-10 10:05:00+00',  1, 1, 'project.created',       '{"project_id":1,"name":"Billing API"}'),
  ('2025-01-12 10:35:00+00',  2, 1, 'user.signed_up',        '{"source":"invite","token":"inv_tok_001"}'),
  ('2025-01-13 10:00:00+00',  1, 1, 'membership.added',      '{"user_id":2,"role":"admin"}'),
  ('2025-01-15 10:00:00+00',  1, 1, 'task.created',          '{"task_id":2,"project_id":1}'),
  ('2025-01-16 11:00:00+00',  2, 2, 'organization.created',  '{"plan":"team"}'),
  ('2025-01-25 11:35:00+00',  2, 1, 'project.created',       '{"project_id":2,"name":"Analytics Dashboard"}'),
  ('2025-02-01 09:00:00+00',  1, 1, 'invitation.accepted',   '{"invitation_id":1,"user_id":2}'),
  ('2025-02-05 14:00:00+00',  3, 1, 'task.completed',        '{"task_id":2}'),
  ('2025-02-10 12:00:00+00',  1, 3, 'organization.created',  '{"plan":"enterprise"}'),
  ('2025-02-15 10:05:00+00',  1, 3, 'project.created',       '{"project_id":15,"name":"Satellite Tracker"}'),
  ('2025-02-20 09:00:00+00',  3, 1, 'task.completed',        '{"task_id":14}'),
  ('2025-02-22 14:35:00+00',  4, 2, 'project.created',       '{"project_id":10,"name":"Client Portal"}'),
  ('2025-03-01 10:00:00+00',  7, 3, 'task.completed',        '{"task_id":34}'),
  ('2025-03-05 15:05:00+00',  5, 4, 'organization.created',  '{"plan":"team"}'),
  ('2025-03-10 10:05:00+00',  7, 3, 'invitation.sent',       '{"invitation_id":11,"email":"engineer2@external.com"}'),
  ('2025-03-15 13:05:00+00',  7, 3, 'project.created',       '{"project_id":16,"name":"Telemetry Pipeline"}'),
  ('2025-03-20 16:05:00+00',  6, 1, 'project.created',       '{"project_id":5,"name":"Onboarding Flow"}'),
  ('2025-03-25 09:05:00+00',  1, 1, 'invitation.sent',       '{"invitation_id":3,"email":"declined1@external.com"}'),
  ('2025-04-01 10:05:00+00',  3, 5, 'organization.created',  '{"plan":"team"}'),
  ('2025-04-05 10:00:00+00',  2, 2, 'task.completed',        '{"task_id":41}'),
  ('2025-04-08 09:05:00+00',  3, 5, 'project.created',       '{"project_id":26,"name":"IoT Gateway"}'),
  ('2025-04-10 09:00:00+00', 10, 4, 'invitation.expired',    '{"invitation_id":3}'),
  ('2025-04-15 10:05:00+00',  9, 2, 'project.created',       '{"project_id":12,"name":"Brand Site"}'),
  ('2025-04-25 14:35:00+00',  1, 3, 'project.created',       '{"project_id":18,"name":"Ground Station UI"}'),
  ('2025-05-05 09:00:00+00',  1, 1, 'invitation.revoked',    '{"invitation_id":5,"reason":"role_change"}'),
  ('2025-05-08 10:35:00+00', 14, 3, 'project.created',       '{"project_id":19,"name":"Anomaly Detector"}'),
  ('2025-05-12 14:05:00+00',  9, 6, 'organization.created',  '{"plan":"research"}'),
  ('2025-05-15 11:05:00+00', 13, 4, 'project.created',       '{"project_id":24,"name":"Returns Portal"}'),
  ('2025-05-20 11:05:00+00',  9, 6, 'project.created',       '{"project_id":29,"name":"QKD Simulator"}'),
  ('2025-05-22 10:50:00+00', 12, 1, 'project.created',       '{"project_id":7,"name":"Admin Console"}'),
  ('2025-06-01 09:05:00+00',  6, 7, 'organization.created',  '{"plan":"team"}'),
  ('2025-06-03 13:45:00+00', 18, 1, 'user.signed_up',        '{"source":"website"}'),
  ('2025-06-10 11:00:00+00',  3, 1, 'task.completed',        '{"task_id":15}'),
  ('2025-06-14 15:05:00+00', 19, 6, 'project.created',       '{"project_id":30,"name":"Lattice Solver"}'),
  ('2025-06-15 08:25:00+00',  1, 1, 'project.created',       '{"project_id":8,"name":"Webhooks Platform"}'),
  ('2025-06-18 09:50:00+00',  2, 2, 'project.created',       '{"project_id":14,"name":"Portfolio Builder"}'),
  ('2025-06-25 09:05:00+00', 20, 3, 'project.created',       '{"project_id":21,"name":"Data Archive"}'),
  ('2025-06-30 12:00:00+00',  2, 2, 'invitation.sent',       '{"invitation_id":8,"email":"studio_apply@external.com"}');

-- ------------------------------------------------------------
-- Reset sequences so future inserts get the next free id
-- ------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('auth.users',         'id'),
  COALESCE((SELECT MAX(id) FROM auth.users),         1), true);

SELECT setval(pg_get_serial_sequence('auth.organizations', 'id'),
  COALESCE((SELECT MAX(id) FROM auth.organizations), 1), true);

SELECT setval(pg_get_serial_sequence('auth.memberships',   'id'),
  COALESCE((SELECT MAX(id) FROM auth.memberships),   1), true);

SELECT setval(pg_get_serial_sequence('auth.invitations',   'id'),
  COALESCE((SELECT MAX(id) FROM auth.invitations),   1), true);

SELECT setval(pg_get_serial_sequence('projects.projects',  'id'),
  COALESCE((SELECT MAX(id) FROM projects.projects),  1), true);

SELECT setval(pg_get_serial_sequence('projects.tasks',     'id'),
  COALESCE((SELECT MAX(id) FROM projects.tasks),     1), true);

-- events.activity_log uses BIGSERIAL on `id` but it's part of a
-- composite PK on a partitioned table. The sequence still advances
-- normally for future inserts; nothing to reset here unless you want
-- a specific starting point.

COMMIT;

-- ------------------------------------------------------------
-- Sanity checks
-- ------------------------------------------------------------
-- SELECT COUNT(*) AS users         FROM auth.users;          -- 20
-- SELECT COUNT(*) AS organizations FROM auth.organizations;  --  7
-- SELECT COUNT(*) AS memberships   FROM auth.memberships;    -- 32
-- SELECT COUNT(*) AS invitations   FROM auth.invitations;    -- 22
-- SELECT COUNT(*) AS projects      FROM projects.projects;   -- 30
-- SELECT COUNT(*) AS tasks         FROM projects.tasks;      -- 60
-- SELECT COUNT(*) AS activity      FROM events.activity_log; -- 40