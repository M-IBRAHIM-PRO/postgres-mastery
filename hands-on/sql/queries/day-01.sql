CREATE SCHEMA auth;

CREATE TABLE auth.users (
    id BIGSERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO auth.users (
    email,
    full_name
)
VALUES
('ibrahim@test.com', 'Muhammad Ibrahim'),
('john@test.com', 'John Doe');

SELECT * FROM auth.users;