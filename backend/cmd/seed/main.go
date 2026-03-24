package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	if len(os.Args) < 5 {
		fmt.Println("Usage: go run cmd/seed/main.go <email> <password> <full_name> <role>")
		fmt.Println("")
		fmt.Println("Available admin roles:")
		fmt.Println("  super_admin       - Full access to everything")
		fmt.Println("  admin             - General admin access")
		fmt.Println("  operations_admin  - Manage bookings, technicians, categories")
		fmt.Println("  support_admin     - Manage support tickets")
		fmt.Println("")
		fmt.Println("Example:")
		fmt.Println(`  go run cmd/seed/main.go admin@techapp.com admin123456 "System Admin" super_admin`)
		os.Exit(1)
	}

	email := os.Args[1]
	password := os.Args[2]
	fullName := os.Args[3]
	role := os.Args[4]

	validRoles := map[string]bool{
		"admin": true, "super_admin": true,
		"operations_admin": true, "support_admin": true,
	}
	if !validRoles[role] {
		log.Fatalf("Invalid role '%s'. Must be one of: admin, super_admin, operations_admin, support_admin", role)
	}

	// Connect to DB using env vars (same as backend)
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbUser := getEnv("DB_USER", "techapp")
	dbPass := getEnv("DB_PASS", "techapp_secret")
	dbName := getEnv("DB_NAME", "techapp")
	dbSSL := getEnv("DB_SSL_MODE", "disable")

	dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", dbUser, dbPass, dbHost, dbPort, dbName, dbSSL)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer pool.Close()

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	// Generate a username from email prefix
	username := email[:len(email)-len("@techapp.com")]
	if username == "" {
		username = "admin"
	}

	id := uuid.New()
	now := time.Now().UTC()

	query := `
		INSERT INTO users (id, email, phone, username, password_hash, full_name, role, is_active, language, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, true, 'en', $8, $8)
		ON CONFLICT (email) DO UPDATE SET
			password_hash = EXCLUDED.password_hash,
			full_name = EXCLUDED.full_name,
			role = EXCLUDED.role,
			is_active = true,
			deleted_at = NULL,
			updated_at = EXCLUDED.updated_at
	`

	_, err = pool.Exec(ctx, query, id, email, "+1000000000", username, string(hash), fullName, role, now)
	if err != nil {
		log.Fatalf("Failed to create admin user: %v", err)
	}

	fmt.Println("✓ Admin user created/updated successfully!")
	fmt.Printf("  Email: %s\n", email)
	fmt.Printf("  Role:  %s\n", role)
	fmt.Printf("  Name:  %s\n", fullName)
	fmt.Println("\nYou can now login at the admin panel with these credentials.")
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
