BEGIN;

TRUNCATE TABLE
  projects.projects,
  auth.memberships,
  auth.organizations,
  auth.users
RESTART IDENTITY CASCADE;

INSERT INTO auth.users (
  id,
  public_id,
  email,
  full_name,
  is_active,
  preferences
)
VALUES
  (
    1,
    '11111111-1111-1111-1111-111111111111',
    'ibrahim@teamsync.dev',
    'Muhammad Ibrahim',
    true,
    '{"theme": "dark", "timezone": "Asia/Karachi"}'
  ),
  (
    2,
    '22222222-2222-2222-2222-222222222222',
    'sarah@teamsync.dev',
    'Sarah Khan',
    true,
    '{"theme": "light", "timezone": "Asia/Karachi"}'
  ),
  (
    3,
    '33333333-3333-3333-3333-333333333333',
    'ali@teamsync.dev',
    'Ali Raza',
    true,
    '{"theme": "dark", "timezone": "UTC"}'
  ),
  (
    4,
    '44444444-4444-4444-4444-444444444444',
    'fatima@teamsync.dev',
    'Fatima Noor',
    false,
    '{"theme": "light", "timezone": "Europe/Berlin"}'
  ),
  (
    5,
    '55555555-5555-5555-5555-555555555555',
    'john@teamsync.dev',
    'John Carter',
    true,
    '{"theme": "dark", "timezone": "America/New_York"}'
  );

INSERT INTO auth.organizations (
  id,
  public_id,
  name
)
VALUES
  (
    1,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'TeamSync Labs'
  ),
  (
    2,
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'Northstar Studio'
  );

INSERT INTO auth.memberships (
  id,
  organization_id,
  user_id,
  role
)
VALUES
  (1, 1, 1, 'owner'),
  (2, 1, 2, 'member'),
  (3, 1, 3, 'member'),
  (4, 2, 2, 'owner'),
  (5, 2, 4, 'member'),
  (6, 2, 5, 'member');

INSERT INTO projects.projects (
  id,
  public_id,
  organization_id,
  created_by,
  name,
  description,
  metadata
)
VALUES
  (
    1,
    'aaaa1111-1111-1111-1111-111111111111',
    1,
    1,
    'Billing API',
    'Backend service for subscriptions and invoices.',
    '{"status": "active", "priority": "high"}'
  ),
  (
    2,
    'aaaa2222-2222-2222-2222-222222222222',
    1,
    2,
    'Analytics Dashboard',
    'Internal dashboard for product metrics.',
    '{"status": "planning", "priority": "medium"}'
  ),
  (
    3,
    'aaaa3333-3333-3333-3333-333333333333',
    1,
    3,
    'Auth Service',
    'Authentication and session management module.',
    '{"status": "active", "priority": "high"}'
  ),
  (
    4,
    'bbbb1111-1111-1111-1111-111111111111',
    2,
    2,
    'Design System',
    'Reusable components and UI foundations.',
    '{"status": "active", "priority": "medium"}'
  ),
  (
    5,
    'bbbb2222-2222-2222-2222-222222222222',
    2,
    4,
    'Client Portal',
    'Workspace for clients to review deliverables.',
    '{"status": "review", "priority": "high"}'
  );

SELECT setval(
  pg_get_serial_sequence('auth.users', 'id'),
  COALESCE((SELECT MAX(id) FROM auth.users), 1),
  true
);

SELECT setval(
  pg_get_serial_sequence('auth.organizations', 'id'),
  COALESCE((SELECT MAX(id) FROM auth.organizations), 1),
  true
);

SELECT setval(
  pg_get_serial_sequence('auth.memberships', 'id'),
  COALESCE((SELECT MAX(id) FROM auth.memberships), 1),
  true
);

SELECT setval(
  pg_get_serial_sequence('projects.projects', 'id'),
  COALESCE((SELECT MAX(id) FROM projects.projects), 1),
  true
);

COMMIT;
