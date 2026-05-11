-- All active users
SELECT * FROM auth.users WHERE is_active=true;

-- All organizations ordered by `created_at` desc
SELECT * FROM auth.organizations ORDER BY created_at DESC;

-- All projects for one organization
SELECT * FROM projects.projects WHERE organization_id=1;

-- Get all members of one organization with user email and membership role
SELECT u.email, m.role
FROM auth.users u 
JOIN auth.memberships m ON u.id=m.user_id 
WHERE m.organization_id=1;

-- Get all projects of one organization with creator email
SELECT U.email, P.description
FROM projects.projects P
JOIN auth.users U ON U.id=P.created_by
WHERE P.organization_id=1;

-- Get all organizations a user belongs to
SELECT U.email, M.organization_id, M.role
FROM auth.users U
JOIN auth.memberships M ON U.id=M.user_id
WHERE U.id=2;

-- Get project name, organization name, and creator email in one query
SELECT
  p.name AS project_name,
  o.name AS organization_name,
  u.email AS creator_email
FROM projects.projects AS p
JOIN auth.organizations AS o
  ON o.id = p.organization_id
JOIN auth.users AS u
  ON u.id = p.created_by
WHERE o.id=1;

-- Project count per organization
SELECT O.name, COUNT(*) AS no_of_projects
FROM projects.projects P
JOIN auth.organizations O ON O.id=P.organization_id
GROUP BY O.name, O.id;

-- Member count per organization
SELECT O.name, COUNT(*) AS no_of_members
FROM auth.memberships M
JOIN auth.organizations O ON O.id=M.organization_id
GROUP BY O.id, O.name;

-- `auth.users.email` stays unique
SELECT
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint
WHERE conrelid = 'auth.users'::regclass;
-- its already unique

-- ALTER TABLE auth.users
-- ADD CONSTRAINT constraint_name UNIQUE (email);

-- `auth.memberships (organization_id, user_id)` stays unique
SELECT
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint
WHERE conrelid = 'auth.memberships'::regclass;
-- already exsits

-- membership `role` only allows 'owner' or 'member'
ALTER TABLE auth.memberships
ADD CONSTRAINT membership_specific_roles
CHECK (role IN ('owner', 'admin', 'member'));

-- Add indexes

-- 1. Check indexses
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'projects.projects';

-- Use `EXPLAIN ANALYZE`
EXPLAIN ANALYZE
SELECT id, email
FROM auth.users
WHERE email = 'ibrahim@teamsync.dev';

-- Make a real transaction
-- create a new organization
-- create the owner membership for a chosen user
BEGIN;

WITH new_org AS (
  INSERT INTO auth.organizations (name)
  VALUES ('Orbit Labs')
  RETURNING id
)
INSERT INTO auth.memberships (organization_id, user_id, role)
SELECT id, 1, 'owner'
FROM new_org;

COMMIT;