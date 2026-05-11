package users

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/jackc/pgx/v5"
)

type Repository struct {
	conn *pgx.Conn
}

func NewRepository(conn *pgx.Conn) *Repository {
	return &Repository{conn: conn}
}

func (r *Repository) FindByEmail(ctx context.Context, email string) (User, error) {
	const query = `
SELECT
  id,
  public_id,
  email,
  full_name,
  is_active,
  preferences,
  created_at,
  updated_at,
  deleted_at
FROM auth.users
WHERE email = $1
`

	var user User
	var preferences []byte

	err := r.conn.QueryRow(ctx, query, email).Scan(
		&user.ID,
		&user.PublicID,
		&user.Email,
		&user.FullName,
		&user.IsActive,
		&preferences,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.DeletedAt,
	)
	if err != nil {
		return User{}, fmt.Errorf("find user by email: %w", err)
	}

	if len(preferences) > 0 {
		if err := json.Unmarshal(preferences, &user.Preferences); err != nil {
			return User{}, fmt.Errorf("decode user preferences: %w", err)
		}
	}

	return user, nil
}

func (r *Repository) ListOrganizationMembers(
	ctx context.Context,
	organizationID int64,
) ([]OrganizationMember, error) {
	const query = `
SELECT
  u.id,
  u.email,
  u.full_name,
  o.id,
  o.name,
  m.role
FROM auth.memberships AS m
JOIN auth.users AS u
  ON u.id = m.user_id
JOIN auth.organizations AS o
  ON o.id = m.organization_id
WHERE o.id = $1
ORDER BY u.id
`

	rows, err := r.conn.Query(ctx, query, organizationID)
	if err != nil {
		return nil, fmt.Errorf("list organization members: %w", err)
	}
	defer rows.Close()

	members := make([]OrganizationMember, 0)
	for rows.Next() {
		var member OrganizationMember
		if err := rows.Scan(
			&member.UserID,
			&member.Email,
			&member.FullName,
			&member.OrganizationID,
			&member.OrganizationName,
			&member.Role,
		); err != nil {
			return nil, fmt.Errorf("scan organization member: %w", err)
		}

		members = append(members, member)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate organization members: %w", err)
	}

	return members, nil
}
