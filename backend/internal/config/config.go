package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	AppEnv    string
	ServerPort string
	WSPort     string

	DBHost    string
	DBPort    string
	DBUser    string
	DBPass    string
	DBName    string
	DBSSLMode string

	RedisHost string
	RedisPass string

	JWTSecret      string
	RefreshSecret  string
	JWTExpiry      time.Duration
	RefreshExpiry  time.Duration

	AWSRegion    string
	AWSAccessKey string
	AWSSecretKey string
	S3Bucket     string

	FirebaseProjectID string
	MapsAPIKey        string

	PaymentKey    string
	PaymentSecret string

	CommissionRate     float64
	MaxTechDebt        float64
	MatchRadiusStart   int
	MatchRadiusMax     int
	MatchTimeout       int
	ArrivalDistance    int
}

func Load() *Config {
	return &Config{
		AppEnv:     getEnv("APP_ENV", "development"),
		ServerPort: getEnv("SERVER_PORT", "8080"),
		WSPort:     getEnv("WS_PORT", "8081"),

		DBHost:    getEnv("DB_HOST", "localhost"),
		DBPort:    getEnv("DB_PORT", "5432"),
		DBUser:    getEnv("DB_USER", "techapp"),
		DBPass:    getEnv("DB_PASS", "techapp_secret"),
		DBName:    getEnv("DB_NAME", "techapp"),
		DBSSLMode: getEnv("DB_SSL_MODE", "disable"),

		RedisHost: getEnv("REDIS_HOST", "localhost:6379"),
		RedisPass: getEnv("REDIS_PASS", ""),

		JWTSecret:     getEnv("JWT_SECRET", "dev-jwt-secret"),
		RefreshSecret: getEnv("REFRESH_SECRET", "dev-refresh-secret"),
		JWTExpiry:     parseDuration(getEnv("JWT_EXPIRY", "15m")),
		RefreshExpiry: parseDuration(getEnv("REFRESH_EXPIRY", "720h")),

		AWSRegion:    getEnv("AWS_REGION", "us-east-1"),
		AWSAccessKey: getEnv("AWS_ACCESS_KEY", ""),
		AWSSecretKey: getEnv("AWS_SECRET_KEY", ""),
		S3Bucket:     getEnv("S3_BUCKET", "techapp-uploads"),

		FirebaseProjectID: getEnv("FIREBASE_PROJECT_ID", ""),
		MapsAPIKey:        getEnv("MAPS_API_KEY", ""),

		PaymentKey:    getEnv("PAYMENT_KEY", ""),
		PaymentSecret: getEnv("PAYMENT_SECRET", ""),

		CommissionRate:   parseFloat(getEnv("COMMISSION_RATE", "0.20")),
		MaxTechDebt:      parseFloat(getEnv("MAX_TECH_DEBT", "500.00")),
		MatchRadiusStart: parseInt(getEnv("MATCH_RADIUS_START", "5000")),
		MatchRadiusMax:   parseInt(getEnv("MATCH_RADIUS_MAX", "25000")),
		MatchTimeout:     parseInt(getEnv("MATCH_TIMEOUT_SECONDS", "30")),
		ArrivalDistance:  parseInt(getEnv("ARRIVAL_DISTANCE_METERS", "100")),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func parseDuration(s string) time.Duration {
	d, err := time.ParseDuration(s)
	if err != nil {
		return 15 * time.Minute
	}
	return d
}

func parseFloat(s string) float64 {
	f, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0
	}
	return f
}

func parseInt(s string) int {
	i, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return i
}
