package auth

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"regexp"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"github.com/techapp/backend/internal/config"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	repo *Repository
	rdb  *redis.Client
	cfg  *config.Config
}

func NewService(repo *Repository, rdb *redis.Client, cfg *config.Config) *Service {
	return &Service{repo: repo, rdb: rdb, cfg: cfg}
}

func (s *Service) Register(ctx context.Context, req *RegisterRequest) (*TokenPair, error) {
	// Check if email exists
	exists, err := s.repo.EmailExists(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("check email: %w", err)
	}
	if exists {
		return nil, fmt.Errorf("email already registered")
	}

	// Check if phone exists
	exists, err = s.repo.PhoneExists(ctx, req.Phone)
	if err != nil {
		return nil, fmt.Errorf("check phone: %w", err)
	}
	if exists {
		return nil, fmt.Errorf("phone already registered")
	}

	// Handle username - auto-generate if empty, otherwise validate uniqueness
	username := req.Username
	if username == "" {
		username, err = s.generateUniqueUsername(ctx, req.FullName)
		if err != nil {
			return nil, fmt.Errorf("generate username: %w", err)
		}
	} else {
		// Check if provided username is unique
		exists, err = s.repo.UsernameExists(ctx, username)
		if err != nil {
			return nil, fmt.Errorf("check username: %w", err)
		}
		if exists {
			return nil, fmt.Errorf("username already taken")
		}
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	user := &User{
		Email:        req.Email,
		Phone:        req.Phone,
		Username:     username,
		PasswordHash: string(hash),
		FullName:     req.FullName,
		Role:         req.Role,
		IsActive:     true,
		Language:     "en",
	}

	if err := s.repo.CreateUser(ctx, user); err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	// Auto-create technician_profiles row for technician users
	if req.Role == "technician" {
		if err := s.repo.CreateTechnicianProfile(ctx, user.ID); err != nil {
			return nil, fmt.Errorf("create technician profile: %w", err)
		}
	}

	return s.generateTokenPair(user)
}

// GenerateUsername generates a unique username from a full name
func (s *Service) GenerateUsername(ctx context.Context, fullName string) (string, error) {
	return s.generateUniqueUsername(ctx, fullName)
}

// CheckUsernameAvailable checks if a username is available
func (s *Service) CheckUsernameAvailable(ctx context.Context, username string) (bool, error) {
	exists, err := s.repo.UsernameExists(ctx, username)
	if err != nil {
		return false, err
	}
	return !exists, nil
}

// UpdateUsername updates a user's username
func (s *Service) UpdateUsername(ctx context.Context, userID uuid.UUID, username string) error {
	// Check availability
	exists, err := s.repo.UsernameExists(ctx, username)
	if err != nil {
		return fmt.Errorf("check username: %w", err)
	}
	if exists {
		return fmt.Errorf("username already taken")
	}
	return s.repo.UpdateUsername(ctx, userID, username)
}

func (s *Service) generateUniqueUsername(ctx context.Context, fullName string) (string, error) {
	// Clean name: take first name, lowercase, remove non-alphanumeric
	re := regexp.MustCompile(`[^a-zA-Z0-9]`)
	parts := strings.Fields(fullName)
	baseName := ""
	if len(parts) > 0 {
		baseName = strings.ToLower(re.ReplaceAllString(parts[0], ""))
	}
	if baseName == "" {
		baseName = "user"
	}

	// Try up to 50 times to generate a unique username
	for i := 0; i < 50; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(9000))
		if err != nil {
			return "", err
		}
		suffix := n.Int64() + 1000
		username := fmt.Sprintf("%s%d", baseName, suffix)

		exists, err := s.repo.UsernameExists(ctx, username)
		if err != nil {
			return "", err
		}
		if !exists {
			return username, nil
		}
	}
	return "", fmt.Errorf("failed to generate unique username")
}

func (s *Service) Login(ctx context.Context, req *LoginRequest) (*TokenPair, error) {
	user, err := s.repo.GetByEmail(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	if !user.IsActive {
		return nil, fmt.Errorf("account is deactivated")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// Ensure technician_profiles row exists for technician users
	if user.Role == "technician" {
		_ = s.repo.CreateTechnicianProfile(ctx, user.ID)
	}

	return s.generateTokenPair(user)
}

func (s *Service) RefreshToken(ctx context.Context, refreshToken string) (*TokenPair, error) {
	token, err := jwt.Parse(refreshToken, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return []byte(s.cfg.RefreshSecret), nil
	})

	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid refresh token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("invalid token claims")
	}

	// Check if token is revoked
	tokenID := claims["jti"].(string)
	revoked, _ := s.rdb.Get(ctx, "revoked:"+tokenID).Result()
	if revoked != "" {
		return nil, fmt.Errorf("token has been revoked")
	}

	userID, err := uuid.Parse(claims["sub"].(string))
	if err != nil {
		return nil, fmt.Errorf("invalid user ID in token")
	}

	user, err := s.repo.GetByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("user not found")
	}

	// Revoke old refresh token (rotation)
	s.rdb.Set(ctx, "revoked:"+tokenID, "1", s.cfg.RefreshExpiry)

	return s.generateTokenPair(user)
}

func (s *Service) SendOTP(ctx context.Context, phone string) error {
	code, err := generateOTP()
	if err != nil {
		return fmt.Errorf("generate OTP: %w", err)
	}

	// Store OTP in Redis with 5 minute expiry
	key := "otp:" + phone
	err = s.rdb.Set(ctx, key, code, 5*time.Minute).Err()
	if err != nil {
		return fmt.Errorf("store OTP: %w", err)
	}

	// TODO: Send OTP via SMS provider
	fmt.Printf("OTP for %s: %s\n", phone, code)

	return nil
}

func (s *Service) VerifyOTP(ctx context.Context, phone, code string) (*TokenPair, error) {
	key := "otp:" + phone
	stored, err := s.rdb.Get(ctx, key).Result()
	if err != nil {
		return nil, fmt.Errorf("OTP expired or not found")
	}

	if stored != code {
		return nil, fmt.Errorf("invalid OTP")
	}

	// Delete used OTP
	s.rdb.Del(ctx, key)

	user, err := s.repo.GetByPhone(ctx, phone)
	if err != nil {
		return nil, fmt.Errorf("user not found")
	}

	return s.generateTokenPair(user)
}

func (s *Service) Logout(ctx context.Context, userID string) error {
	key := "session:" + userID
	return s.rdb.Del(ctx, key).Err()
}

func (s *Service) ValidateToken(tokenStr string) (*Claims, error) {
	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return []byte(s.cfg.JWTSecret), nil
	})

	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}

	mapClaims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("invalid claims")
	}

	return &Claims{
		UserID: mapClaims["sub"].(string),
		Email:  mapClaims["email"].(string),
		Role:   mapClaims["role"].(string),
	}, nil
}

func (s *Service) generateTokenPair(user *User) (*TokenPair, error) {
	now := time.Now()

	// Access token
	accessClaims := jwt.MapClaims{
		"sub":   user.ID.String(),
		"email": user.Email,
		"role":  user.Role,
		"iat":   now.Unix(),
		"exp":   now.Add(s.cfg.JWTExpiry).Unix(),
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessStr, err := accessToken.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, fmt.Errorf("sign access token: %w", err)
	}

	// Refresh token
	refreshID := uuid.New().String()
	refreshClaims := jwt.MapClaims{
		"sub": user.ID.String(),
		"jti": refreshID,
		"iat": now.Unix(),
		"exp": now.Add(s.cfg.RefreshExpiry).Unix(),
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshStr, err := refreshToken.SignedString([]byte(s.cfg.RefreshSecret))
	if err != nil {
		return nil, fmt.Errorf("sign refresh token: %w", err)
	}

	return &TokenPair{
		AccessToken:  accessStr,
		RefreshToken: refreshStr,
		ExpiresIn:    int64(s.cfg.JWTExpiry.Seconds()),
		Role:         user.Role,
	}, nil
}

func generateOTP() (string, error) {
	code := ""
	for i := 0; i < 6; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		code += n.String()
	}
	return code, nil
}
