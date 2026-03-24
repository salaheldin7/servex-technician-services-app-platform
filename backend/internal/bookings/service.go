package bookings

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"github.com/techapp/backend/internal/matching"
	"github.com/techapp/backend/internal/websocket"
)

type Service struct {
	repo    *Repository
	matcher *matching.Service
	wsHub   *websocket.Hub
	rdb     *redis.Client
}

func NewService(repo *Repository, matcher *matching.Service, wsHub *websocket.Hub, rdb *redis.Client) *Service {
	return &Service{repo: repo, matcher: matcher, wsHub: wsHub, rdb: rdb}
}

// storePendingRequest saves a booking request to Redis so the technician can fetch it later
func (s *Service) storePendingRequest(ctx context.Context, technicianUserID string, requestData map[string]interface{}) {
	key := fmt.Sprintf("pending_requests:%s", technicianUserID)
	data, err := json.Marshal(requestData)
	if err != nil {
		return
	}
	bookingID := fmt.Sprintf("%v", requestData["booking_id"])
	s.rdb.HSet(ctx, key, bookingID, string(data))
	s.rdb.Expire(ctx, key, 5*time.Minute) // auto-expire after 5 min
}

// removePendingRequest removes a booking request from a technician's pending list
func (s *Service) removePendingRequest(ctx context.Context, technicianUserID string, bookingID string) {
	key := fmt.Sprintf("pending_requests:%s", technicianUserID)
	s.rdb.HDel(ctx, key, bookingID)
}

// GetPendingRequests returns all pending booking requests for a technician
func (s *Service) GetPendingRequests(ctx context.Context, technicianUserID string) ([]map[string]interface{}, error) {
	key := fmt.Sprintf("pending_requests:%s", technicianUserID)
	entries, err := s.rdb.HGetAll(ctx, key).Result()
	if err != nil {
		return nil, err
	}

	var requests []map[string]interface{}
	for _, val := range entries {
		var req map[string]interface{}
		if err := json.Unmarshal([]byte(val), &req); err == nil {
			requests = append(requests, req)
		}
	}
	return requests, nil
}

func (s *Service) Create(ctx context.Context, userID uuid.UUID, req *CreateBookingRequest) (*Booking, error) {
	// Enforce: only one active booking per customer
	activeCount, err := s.repo.CountActiveByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("check active bookings: %w", err)
	}
	if activeCount > 0 {
		return nil, fmt.Errorf("you already have an active booking. Please complete or cancel it first")
	}

	booking := &Booking{
		UserID:         userID,
		CategoryID:     req.CategoryID,
		Description:    req.Description,
		Address:        req.Address,
		Lat:            *req.Lat,
		Lng:            *req.Lng,
		ScheduledAt:    req.ScheduledAt,
		PaymentMethod:  req.PaymentMethod,
		StreetName:     req.StreetName,
		BuildingName:   req.BuildingName,
		BuildingNumber: req.BuildingNumber,
		Floor:          req.Floor,
		Apartment:      req.Apartment,
		FullAddress:    req.FullAddress,
	}

	// Parse optional UUID fields from string
	if req.CountryID != "" {
		if id, err := uuid.Parse(req.CountryID); err == nil {
			booking.CountryID = &id
		}
	}
	if req.GovernorateID != "" {
		if id, err := uuid.Parse(req.GovernorateID); err == nil {
			booking.GovernorateID = &id
		}
	}
	if req.CityID != "" {
		if id, err := uuid.Parse(req.CityID); err == nil {
			booking.CityID = &id
		}
	}
	if req.AddressID != "" {
		if id, err := uuid.Parse(req.AddressID); err == nil {
			booking.AddressID = &id
		}
	}

	if err := s.repo.Create(ctx, booking); err != nil {
		return nil, fmt.Errorf("create booking: %w", err)
	}

	// Re-fetch with joins (category name, user name, etc.)
	fullBooking, err := s.repo.GetByID(ctx, booking.ID)
	if err != nil {
		// Booking was created; return what we have
		fullBooking = booking
	}

	// Build rich request data for technician popup
	requestData := map[string]interface{}{
		"booking_id":      fullBooking.ID,
		"lat":             fullBooking.Lat,
		"lng":             fullBooking.Lng,
		"category":        fullBooking.CategoryID.String(),
		"category_name":   fullBooking.CategoryName,
		"description":     fullBooking.Description,
		"address":         fullBooking.FullAddress,
		"estimated_price": fullBooking.EstimatedCost,
		"customer_name":   fullBooking.UserName,
		"timeout":         60,
	}

	// If a specific technician was chosen, send request directly to them
	if req.TechnicianID != "" {
		_, parseErr := uuid.Parse(req.TechnicianID)
		if parseErr == nil {
			s.wsHub.SendToUser(req.TechnicianID, websocket.Event{
				Type: "booking_request",
				Data: requestData,
			})
			s.storePendingRequest(ctx, req.TechnicianID, requestData)
		}
	} else if req.AutoAssign {
		// Auto-assign: Start matching process async
		go s.matcher.FindMatch(context.Background(), fullBooking.ID, fullBooking.Lat, fullBooking.Lng, fullBooking.CategoryID.String())
	} else {
		// Default: Start matching process async
		go s.matcher.FindMatch(context.Background(), fullBooking.ID, fullBooking.Lat, fullBooking.Lng, fullBooking.CategoryID.String())
	}

	// Notify user via WebSocket
	s.wsHub.SendToUser(userID.String(), websocket.Event{
		Type: "booking_created",
		Data: map[string]interface{}{"booking_id": fullBooking.ID},
	})

	return fullBooking, nil
}

func (s *Service) Get(ctx context.Context, bookingID uuid.UUID) (*Booking, error) {
	return s.repo.GetByID(ctx, bookingID)
}

func (s *Service) List(ctx context.Context, userID uuid.UUID, role string, page, pageSize int) ([]Booking, int, error) {
	if role == "technician" {
		return s.repo.ListByTechnician(ctx, userID, page, pageSize)
	}
	return s.repo.ListByUser(ctx, userID, page, pageSize)
}

func (s *Service) Accept(ctx context.Context, bookingID, technicianID uuid.UUID) error {
	booking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	if booking.Status != StatusSearching {
		return fmt.Errorf("booking cannot be accepted in current state: %s", booking.Status)
	}

	if err := s.repo.AssignTechnician(ctx, bookingID, technicianID); err != nil {
		return err
	}

	// Re-fetch to get the generated arrival code
	updatedBooking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	// Notify customer that technician accepted — include arrival code
	s.wsHub.SendToUser(booking.UserID.String(), websocket.Event{
		Type: "booking_accepted",
		Data: map[string]interface{}{
			"booking_id":    bookingID,
			"technician_id": technicianID,
			"arrival_code":  updatedBooking.ArrivalCode,
			"status":        string(StatusAssigned),
			"task_status":   "technician_coming",
		},
	})

	// Notify technician with booking details for navigation
	s.wsHub.SendToUser(technicianID.String(), websocket.Event{
		Type: "booking_accepted",
		Data: map[string]interface{}{
			"booking_id":  bookingID,
			"lat":         booking.Lat,
			"lng":         booking.Lng,
			"address":     booking.FullAddress,
			"description": booking.Description,
			"status":      string(StatusAssigned),
			"task_status": "technician_coming",
		},
	})

	// Remove from pending requests
	s.removePendingRequest(ctx, technicianID.String(), bookingID.String())

	return nil
}

func (s *Service) Cancel(ctx context.Context, bookingID uuid.UUID, userID string, reason string) error {
	booking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	if !CancellableStates[booking.Status] {
		return fmt.Errorf("booking cannot be cancelled in state: %s", booking.Status)
	}

	cancelledBy := "user"
	if booking.TechnicianID != nil && booking.TechnicianID.String() == userID {
		cancelledBy = "technician"
	}

	// If still searching (no technician assigned), hard-delete — don't save as a cancelled booking
	if booking.Status == StatusSearching {
		if err := s.repo.Delete(ctx, bookingID); err != nil {
			return err
		}
		// Still notify user so mobile UI navigates away
		s.wsHub.SendToUser(booking.UserID.String(), websocket.Event{
			Type: "booking_cancelled",
			Data: map[string]interface{}{"booking_id": bookingID, "cancelled_by": cancelledBy, "status": string(StatusCancelled)},
		})
		return nil
	}

	if err := s.repo.Cancel(ctx, bookingID, reason, cancelledBy); err != nil {
		return err
	}

	// Notify parties
	s.wsHub.SendToUser(booking.UserID.String(), websocket.Event{
		Type: "booking_cancelled",
		Data: map[string]interface{}{"booking_id": bookingID, "cancelled_by": cancelledBy, "status": string(StatusCancelled)},
	})
	if booking.TechnicianID != nil {
		s.wsHub.SendToUser(booking.TechnicianID.String(), websocket.Event{
			Type: "booking_cancelled",
			Data: map[string]interface{}{"booking_id": bookingID, "cancelled_by": cancelledBy, "status": string(StatusCancelled)},
		})
	}

	return nil
}

func (s *Service) Arrive(ctx context.Context, bookingID uuid.UUID) error {
	booking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	if !CanTransition(booking.Status, StatusArrived) {
		return fmt.Errorf("invalid state transition from %s to arrived", booking.Status)
	}

	if err := s.repo.UpdateStatusAndTask(ctx, bookingID, StatusArrived, TaskTechnicianComing); err != nil {
		return err
	}

	s.wsHub.SendToUser(booking.UserID.String(), websocket.Event{
		Type: "technician_arrived",
		Data: map[string]interface{}{"booking_id": bookingID, "arrival_code": booking.ArrivalCode, "status": string(StatusArrived)},
	})

	return nil
}

func (s *Service) VerifyArrival(ctx context.Context, bookingID uuid.UUID, code string, techLat, techLng float64) error {
	booking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	// Verify arrival code
	if booking.ArrivalCode != code {
		return fmt.Errorf("invalid arrival code")
	}

	// Verify GPS distance (100 meters)
	distance := haversineDistance(booking.Lat, booking.Lng, techLat, techLng)
	if distance > 100 {
		return fmt.Errorf("technician is too far from booking location (%.0f meters)", distance)
	}

	return nil
}

func (s *Service) StartJob(ctx context.Context, bookingID uuid.UUID) error {
	booking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	if !CanTransition(booking.Status, StatusActive) {
		return fmt.Errorf("invalid state transition from %s to active", booking.Status)
	}

	if err := s.repo.StartJob(ctx, bookingID); err != nil {
		return err
	}

	s.wsHub.SendToUser(booking.UserID.String(), websocket.Event{
		Type: "job_started",
		Data: map[string]interface{}{"booking_id": bookingID, "status": string(StatusActive)},
	})
	if booking.TechnicianID != nil {
		s.wsHub.SendToUser(booking.TechnicianID.String(), websocket.Event{
			Type: "job_started",
			Data: map[string]interface{}{"booking_id": bookingID, "status": string(StatusActive)},
		})
	}

	return nil
}

func (s *Service) Complete(ctx context.Context, bookingID uuid.UUID, finalCost float64) error {
	booking, err := s.repo.GetByID(ctx, bookingID)
	if err != nil {
		return err
	}

	if !CanTransition(booking.Status, StatusCompleted) {
		return fmt.Errorf("invalid state transition from %s to completed", booking.Status)
	}

	// Auto-calculate final cost based on duration if not provided
	durationMinutes := 0
	if booking.StartedAt != nil {
		durationMinutes = int(math.Round(float64(time.Since(*booking.StartedAt).Minutes())))
	}

	if finalCost <= 0 && booking.EstimatedCost > 0 && durationMinutes > 0 {
		// Use estimated_cost as the hourly rate, calculate based on actual duration
		// Minimum charge: 1 hour (estimated_cost). Beyond that, pro-rate by the minute.
		hourlyRate := booking.EstimatedCost
		if durationMinutes <= 60 {
			finalCost = hourlyRate // Minimum 1 hour charge
		} else {
			finalCost = hourlyRate * float64(durationMinutes) / 60.0
		}
		// Round to 2 decimal places
		finalCost = math.Round(finalCost*100) / 100
	}

	// Fallback: if still no price, use estimated cost
	if finalCost <= 0 {
		finalCost = booking.EstimatedCost
	}

	if err := s.repo.CompleteJob(ctx, bookingID, finalCost); err != nil {
		return err
	}

	// Notify both parties with receipt data
	event := websocket.Event{
		Type: "job_completed",
		Data: map[string]interface{}{
			"booking_id":       bookingID,
			"final_cost":       finalCost,
			"duration_minutes": durationMinutes,
			"status":           string(StatusCompleted),
			"task_status":      "technician_finished",
		},
	}
	s.wsHub.SendToUser(booking.UserID.String(), event)
	if booking.TechnicianID != nil {
		s.wsHub.SendToUser(booking.TechnicianID.String(), event)
	}

	return nil
}

// haversineDistance calculates the distance between two points in meters
func haversineDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000 // Earth radius in meters
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

// NotifyTechnicianOfSearchingBookings sends pending searching bookings to a technician
// who just came online, so they can accept them in real-time.
func (s *Service) NotifyTechnicianOfSearchingBookings(ctx context.Context, technicianUserID uuid.UUID) {
	searchingBookings, err := s.repo.FindSearchingForTechnician(ctx, technicianUserID)
	if err != nil {
		return
	}

	for _, b := range searchingBookings {
		requestData := map[string]interface{}{
			"booking_id":      b.ID,
			"lat":             b.Lat,
			"lng":             b.Lng,
			"category":        b.CategoryID.String(),
			"category_name":   b.CategoryName,
			"description":     b.Description,
			"address":         b.FullAddress,
			"estimated_price": b.EstimatedCost,
			"customer_name":   b.UserName,
			"timeout":         60,
		}

		s.wsHub.SendToUser(technicianUserID.String(), websocket.Event{
			Type: "booking_request",
			Data: requestData,
		})

		s.storePendingRequest(ctx, technicianUserID.String(), requestData)
	}
}
