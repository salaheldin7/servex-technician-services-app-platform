package matching

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"sort"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"github.com/techapp/backend/internal/config"
	"github.com/techapp/backend/internal/geo"
	"github.com/techapp/backend/internal/technicians"
	"github.com/techapp/backend/internal/websocket"
)

// MatchBooking is a minimal booking view used by the matching engine
// to avoid importing the bookings package (which would cause a cycle).
type MatchBooking struct {
	ID            uuid.UUID
	UserID        uuid.UUID
	Status        string
	Description   string
	Address       string
	CategoryName  string
	UserName      string
	EstimatedCost float64
	Lat           float64
	Lng           float64
}

// BookingFetcher is satisfied by bookings.Repository.
type BookingFetcher interface {
	GetByIDForMatch(ctx context.Context, id uuid.UUID) (*MatchBooking, error)
}

type Service struct {
	techRepo    *technicians.Repository
	bookingRepo BookingFetcher
	geoService  *geo.Service
	wsHub       *websocket.Hub
	cfg         *config.Config
	rdb         *redis.Client
}

func NewService(
	techRepo *technicians.Repository,
	bookingRepo BookingFetcher,
	geoService *geo.Service,
	wsHub *websocket.Hub,
	cfg *config.Config,
	rdb *redis.Client,
) *Service {
	return &Service{
		techRepo:    techRepo,
		bookingRepo: bookingRepo,
		geoService:  geoService,
		wsHub:       wsHub,
		cfg:         cfg,
		rdb:         rdb,
	}
}

type ScoredTechnician struct {
	Profile  technicians.TechnicianProfile
	Score    float64
	Distance float64
}

// FindMatch implements the matching engine algorithm
// Step 1: Query PostGIS within radius
// Step 2: Filter (online, verified, not in active booking)
// Step 3: Score (distance 40%, rating 30%, acceptance 20%, ETA 10%)
// Step 4: Push request via socket with 30s timeout
// Step 5: Expand radius if no match
func (s *Service) FindMatch(ctx context.Context, bookingID uuid.UUID, lat, lng float64, categoryID string) {
	radius := s.cfg.MatchRadiusStart
	maxRadius := s.cfg.MatchRadiusMax
	timeout := time.Duration(s.cfg.MatchTimeout) * time.Second

	for radius <= maxRadius {
		log.Printf("Matching booking %s: searching radius %d meters", bookingID, radius)

		// Step 1 & 2: Query available technicians
		available, err := s.techRepo.FindAvailableForMatching(ctx, lat, lng, radius, categoryID)
		if err != nil {
			log.Printf("Matching error for booking %s: %v", bookingID, err)
			return
		}

		if len(available) == 0 {
			radius = int(float64(radius) * 1.5) // Expand by 50%
			continue
		}

		// Step 3: Score and rank
		scored := s.scoreTechnicians(available, lat, lng, float64(radius))
		sort.Slice(scored, func(i, j int) bool {
			return scored[i].Score > scored[j].Score
		})

		// Step 4: Send booking request to top 5
		limit := 5
		if len(scored) < limit {
			limit = len(scored)
		}

		for _, st := range scored[:limit] {
			requestData := map[string]interface{}{
				"booking_id":      bookingID,
				"lat":             lat,
				"lng":             lng,
				"category":        categoryID,
				"distance":        st.Distance,
				"timeout":         s.cfg.MatchTimeout,
			}

			// Fetch rich booking details if available
			bookingDetail, fetchErr := s.bookingRepo.GetByIDForMatch(ctx, bookingID)
			if fetchErr == nil {
				requestData["description"] = bookingDetail.Description
				requestData["address"] = bookingDetail.Address
				requestData["category_name"] = bookingDetail.CategoryName
				requestData["customer_name"] = bookingDetail.UserName
				requestData["estimated_price"] = bookingDetail.EstimatedCost
			}

			s.wsHub.SendToUser(st.Profile.UserID.String(), websocket.Event{
				Type: "booking_request",
				Data: requestData,
			})

			// Store in Redis for the pending requests page
			if s.rdb != nil {
				key := fmt.Sprintf("pending_requests:%s", st.Profile.UserID.String())
				data, _ := json.Marshal(requestData)
				s.rdb.HSet(ctx, key, bookingID.String(), string(data))
				s.rdb.Expire(ctx, key, 5*time.Minute)
			}
		}

		// Wait for acceptance (simplified — in production use channels/Redis pub-sub)
		time.Sleep(timeout)

		// Check if booking was accepted
		booking, err := s.bookingRepo.GetByIDForMatch(ctx, bookingID)
		if err != nil {
			return
		}

		if booking.Status != "searching" {
			// Already accepted or cancelled
			return
		}

		// Step 5: Expand radius
		radius = int(float64(radius) * 1.5)
	}

	// No match found - notify user
	booking, err := s.bookingRepo.GetByIDForMatch(ctx, bookingID)
	if err != nil {
		return
	}
	s.wsHub.SendToUser(booking.UserID.String(), websocket.Event{
		Type: "no_technician_found",
		Data: map[string]interface{}{"booking_id": bookingID},
	})
}

func (s *Service) scoreTechnicians(techs []technicians.TechnicianProfile, lat, lng, maxDistance float64) []ScoredTechnician {
	var scored []ScoredTechnician

	for _, tech := range techs {
		distance := haversineDistance(lat, lng, tech.CurrentLat, tech.CurrentLng)

		// Score weights: distance 40%, rating 30%, acceptance 20%, ETA 10%
		distanceScore := (1 - (distance / maxDistance)) * 40
		if distanceScore < 0 {
			distanceScore = 0
		}

		ratingScore := (tech.AvgRating / 5.0) * 30
		acceptanceScore := tech.AcceptanceRate * 20

		// ETA approximation: assume 40km/h average speed
		etaMinutes := (distance / 1000) / 40 * 60
		etaScore := math.Max(0, (1-(etaMinutes/30))*10)

		totalScore := distanceScore + ratingScore + acceptanceScore + etaScore

		scored = append(scored, ScoredTechnician{
			Profile:  tech,
			Score:    totalScore,
			Distance: distance,
		})
	}

	return scored
}

func haversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

func init() {
	// Suppress unused import
	_ = fmt.Sprintf
}
