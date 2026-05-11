package users

import "time"

//  ---- DB Schema
// CREATE TABLE auth.users (
//     id BIGSERIAL PRIMARY KEY,
//     public_id UUID NOT NULL DEFAULT gen_random_uuid(),
//     email TEXT NOT NULL UNIQUE,
//     full_name TEXT NOT NULL,
//     is_active BOOLEAN NOT NULL DEFAULT TRUE,
//     preferences JSONB NOT NULL DEFAULT '{}',
//     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
//     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
//     deleted_at TIMESTAMPTZ
// );

type User struct {
	ID          int64
	PublicID    string
	Email       string
	FullName    string
	IsActive    bool
	Preferences map[string]any
	CreatedAt   time.Time
	UpdatedAt   time.Time
	DeletedAt   *time.Time
}

type OrganizationMember struct {
	UserID           int64
	Email            string
	FullName         string
	OrganizationID   int64
	OrganizationName string
	Role             string
}
