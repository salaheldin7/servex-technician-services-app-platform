package geo

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type Service struct {
	rdb *redis.Client
}

func NewService(rdb *redis.Client) *Service {
	return &Service{rdb: rdb}
}

type Location struct {
	UserID string  `json:"user_id"`
	Lat    float64 `json:"lat"`
	Lng    float64 `json:"lng"`
	Time   int64   `json:"time"`
}

// UpdateLocation stores technician location in Redis for real-time access
func (s *Service) UpdateLocation(ctx context.Context, userID string, lat, lng float64) error {
	loc := Location{
		UserID: userID,
		Lat:    lat,
		Lng:    lng,
		Time:   time.Now().Unix(),
	}

	data, _ := json.Marshal(loc)
	key := fmt.Sprintf("location:%s", userID)

	pipe := s.rdb.Pipeline()
	pipe.Set(ctx, key, data, 5*time.Minute) // TTL 5 min — auto-expire if no updates
	pipe.GeoAdd(ctx, "technician_locations", &redis.GeoLocation{
		Name:      userID,
		Longitude: lng,
		Latitude:  lat,
	})
	_, err := pipe.Exec(ctx)
	return err
}

// GetLocation retrieves cached technician location
func (s *Service) GetLocation(ctx context.Context, userID string) (*Location, error) {
	key := fmt.Sprintf("location:%s", userID)
	data, err := s.rdb.Get(ctx, key).Result()
	if err != nil {
		return nil, fmt.Errorf("location not found")
	}

	var loc Location
	if err := json.Unmarshal([]byte(data), &loc); err != nil {
		return nil, err
	}

	return &loc, nil
}

// FindNearby returns technician IDs within radius using Redis GEO
func (s *Service) FindNearby(ctx context.Context, lat, lng float64, radiusMeters float64) ([]string, error) {
	results, err := s.rdb.GeoRadius(ctx, "technician_locations", lng, lat, &redis.GeoRadiusQuery{
		Radius:    radiusMeters,
		Unit:      "m",
		Sort:      "ASC",
		Count:     20,
		WithDist:  true,
		WithCoord: true,
	}).Result()

	if err != nil {
		return nil, err
	}

	var ids []string
	for _, r := range results {
		ids = append(ids, r.Name)
	}
	return ids, nil
}

// ValidateLocationJump checks if a location jump is suspicious (GPS spoofing)
func (s *Service) ValidateLocationJump(ctx context.Context, userID string, newLat, newLng float64) (bool, error) {
	prev, err := s.GetLocation(ctx, userID)
	if err != nil {
		return true, nil // No previous location, allow
	}

	// Check if speed exceeds 200 km/h (suspicious)
	timeDiff := float64(time.Now().Unix()-prev.Time) / 3600 // hours
	if timeDiff <= 0 {
		timeDiff = 0.001
	}

	// Simple distance approximation
	distKm := approximateDistanceKm(prev.Lat, prev.Lng, newLat, newLng)
	speed := distKm / timeDiff

	if speed > 200 {
		return false, fmt.Errorf("suspicious location jump detected: %.0f km/h", speed)
	}

	return true, nil
}

func approximateDistanceKm(lat1, lng1, lat2, lng2 float64) float64 {
	// Approximate distance in km
	dlat := (lat2 - lat1) * 111.0
	dlng := (lng2 - lng1) * 111.0 * 0.7 // rough cos adjustment
	return (dlat*dlat + dlng*dlng) * 0.5  // rough sqrt approximation
}
