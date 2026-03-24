package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"

	"github.com/techapp/backend/internal/config"
	"github.com/techapp/backend/internal/database"
	"github.com/techapp/backend/internal/middleware"
	"github.com/techapp/backend/internal/websocket"

	"github.com/techapp/backend/internal/addresses"
	"github.com/techapp/backend/internal/admin"
	"github.com/techapp/backend/internal/auth"
	"github.com/techapp/backend/internal/bookings"
	"github.com/techapp/backend/internal/categories"
	"github.com/techapp/backend/internal/chat"
	"github.com/techapp/backend/internal/geo"
	"github.com/techapp/backend/internal/locations"
	"github.com/techapp/backend/internal/matching"
	"github.com/techapp/backend/internal/notifications"
	"github.com/techapp/backend/internal/payments"
	"github.com/techapp/backend/internal/ratings"
	"github.com/techapp/backend/internal/settings"
	"github.com/techapp/backend/internal/support"
	"github.com/techapp/backend/internal/technicians"
	"github.com/techapp/backend/internal/users"
	"github.com/techapp/backend/internal/verification"
	"github.com/techapp/backend/internal/wallet"

	"github.com/gin-gonic/gin"
)

// bookingFetcherAdapter wraps bookings.Repository to satisfy matching.BookingFetcher
// without introducing an import cycle.
type bookingFetcherAdapter struct {
	repo *bookings.Repository
}

func (a *bookingFetcherAdapter) GetByIDForMatch(ctx context.Context, id uuid.UUID) (*matching.MatchBooking, error) {
	b, err := a.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return &matching.MatchBooking{
		ID:            b.ID,
		UserID:        b.UserID,
		Status:        string(b.Status),
		Description:   b.Description,
		Address:       b.FullAddress,
		CategoryName:  b.CategoryName,
		UserName:      b.UserName,
		EstimatedCost: b.EstimatedCost,
		Lat:           b.Lat,
		Lng:           b.Lng,
	}, nil
}

// bookingLookupAdapter wraps bookings.Repository to satisfy websocket.BookingLookup
type bookingLookupAdapter struct {
	repo *bookings.Repository
}

func (a *bookingLookupAdapter) GetBookingParticipants(ctx context.Context, bookingID string) (*websocket.BookingParticipants, error) {
	userID, techID, err := a.repo.GetBookingParticipants(ctx, bookingID)
	if err != nil {
		return nil, err
	}
	return &websocket.BookingParticipants{
		UserID:       userID,
		TechnicianID: techID,
	}, nil
}

func (a *bookingLookupAdapter) GetActiveTechnicianBooking(ctx context.Context, technicianUserID string) (*websocket.BookingParticipants, string, error) {
	userID, bookingID, err := a.repo.GetActiveTechnicianBooking(ctx, technicianUserID)
	if err != nil {
		return nil, "", err
	}
	return &websocket.BookingParticipants{
		UserID:       userID,
		TechnicianID: technicianUserID,
	}, bookingID, nil
}

func main() {
	cfg := config.Load()

	db, err := database.NewPostgres(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Run database migrations
	if err := database.RunMigrations(db, "migrations"); err != nil {
		log.Printf("Warning: migration error: %v", err)
	}

	rdb := database.NewRedis(cfg)
	defer rdb.Close()

	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Initialize repositories
	authRepo := auth.NewRepository(db)
	userRepo := users.NewRepository(db)
	techRepo := technicians.NewRepository(db)
	bookingRepo := bookings.NewRepository(db)

	// Wire booking lookup into WS hub for message routing (chat, location)
	wsHub.SetBookingLookup(&bookingLookupAdapter{repo: bookingRepo})

	chatRepo := chat.NewRepository(db)
	paymentRepo := payments.NewRepository(db)
	walletRepo := wallet.NewRepository(db)
	ratingRepo := ratings.NewRepository(db)
	adminRepo := admin.NewRepository(db)
	categoryRepo := categories.NewRepository(db)
	supportRepo := support.NewRepository(db)
	settingsRepo := settings.NewRepository(db)
	locationRepo := locations.NewRepository(db)
	verifyRepo := verification.NewRepository(db)
	notifRepo := notifications.NewRepository(db)
	addressRepo := addresses.NewRepository(db)

	// Initialize services
	authService := auth.NewService(authRepo, rdb, cfg)
	userService := users.NewService(userRepo)
	techService := technicians.NewService(techRepo)
	geoService := geo.NewService(rdb)
	matchingService := matching.NewService(techRepo, &bookingFetcherAdapter{repo: bookingRepo}, geoService, wsHub, cfg, rdb)
	bookingService := bookings.NewService(bookingRepo, matchingService, wsHub, rdb)
	chatService := chat.NewService(chatRepo, wsHub, rdb)
	walletService := wallet.NewService(walletRepo)
	paymentService := payments.NewService(paymentRepo, walletService, cfg)
	ratingService := ratings.NewService(ratingRepo, techRepo)
	notifService := notifications.NewService(cfg, notifRepo)
	adminService := admin.NewService(adminRepo, userRepo, techRepo, bookingRepo, notifService)
	categoryService := categories.NewService(categoryRepo)
	supportService := support.NewService(supportRepo, notifService)
	settingsService := settings.NewService(settingsRepo, authService)
	locationService := locations.NewService(locationRepo)
	verifyService := verification.NewService(verifyRepo, notifService)
	addressService := addresses.NewService(addressRepo)

	// Initialize handlers
	authHandler := auth.NewHandler(authService)
	userHandler := users.NewHandler(userService)
	techHandler := technicians.NewHandler(techService)
	techHandler.SetOnGoOnlineCallback(bookingService)
	bookingHandler := bookings.NewHandler(bookingService)
	chatHandler := chat.NewHandler(chatService)
	paymentHandler := payments.NewHandler(paymentService)
	walletHandler := wallet.NewHandler(walletService)
	ratingHandler := ratings.NewHandler(ratingService)
	adminHandler := admin.NewHandler(adminService)
	categoryHandler := categories.NewHandler(categoryService)
	supportHandler := support.NewHandler(supportService)
	settingsHandler := settings.NewHandler(settingsService)
	locationHandler := locations.NewHandler(locationService)
	verifyHandler := verification.NewHandler(verifyService)
	notifHandler := notifications.NewHandler(notifService)
	addressHandler := addresses.NewHandler(addressService)

	// Setup router
	if cfg.AppEnv == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// Global middleware
	router.Use(middleware.CORS())
	router.Use(middleware.RateLimiter(rdb))
	router.Use(middleware.RequestSizeLimit(10 << 20)) // 10MB
	router.Use(middleware.LanguageHeader())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "time": time.Now().UTC()})
	})

	// Serve uploaded verification files (faces, documents)
	router.Static("/uploads", "./uploads")

	// API routes
	api := router.Group("/api/v1")
	{
		// Public routes
		authRoutes := api.Group("/auth")
		{
			authRoutes.POST("/register", authHandler.Register)
			authRoutes.POST("/login", authHandler.Login)
			authRoutes.POST("/refresh", authHandler.RefreshToken)
			authRoutes.POST("/otp/send", authHandler.SendOTP)
			authRoutes.POST("/otp/verify", authHandler.VerifyOTP)
			authRoutes.POST("/forgot-password", authHandler.ForgotPassword)
			authRoutes.POST("/reset-password", authHandler.ResetPassword)
			authRoutes.GET("/check-username", authHandler.CheckUsername)
			authRoutes.GET("/generate-username", authHandler.GenerateUsername)
		}

		// Public category browsing
		api.GET("/categories", categoryHandler.List)
		api.GET("/categories/:id", categoryHandler.Get)

		// Public location browsing
		api.GET("/locations/countries", locationHandler.ListCountries)
		api.GET("/locations/countries/:country_id/governorates", locationHandler.ListGovernorates)
		api.GET("/locations/governorates/:governorate_id/cities", locationHandler.ListCities)

		// Protected routes
		protected := api.Group("")
		protected.Use(middleware.AuthRequired(cfg))
		{
			// User routes
			protected.GET("/users/me", userHandler.GetProfile)
			protected.PUT("/users/me", userHandler.UpdateProfile)
			protected.POST("/users/me/avatar", userHandler.UploadAvatar)

			// Technician routes
			techRoutes := protected.Group("/technicians")
			{
				techRoutes.POST("/register", techHandler.Register)
				techRoutes.GET("/me", techHandler.GetProfile)
				techRoutes.PUT("/me", techHandler.UpdateProfile)
				techRoutes.PUT("/me/online", techHandler.SetOnline)
				techRoutes.PUT("/me/location", techHandler.UpdateLocation)
				techRoutes.GET("/me/earnings", techHandler.GetEarnings)
				techRoutes.GET("/me/stats", techHandler.GetStats)
				techRoutes.GET("/nearby", techHandler.GetNearby)
				techRoutes.GET("/search", techHandler.SearchByServiceAndLocation)
				techRoutes.POST("/auto-assign", techHandler.AutoAssign)

				// Verification
				techRoutes.POST("/verification/face", verifyHandler.UploadFace)
				techRoutes.POST("/verification/documents", verifyHandler.UploadDocuments)
				techRoutes.POST("/verification/documents/base64", verifyHandler.UploadDocumentsBase64)
				techRoutes.GET("/verification/status", verifyHandler.GetVerificationStatus)

				// Technician services (with wages)
				techRoutes.POST("/services", verifyHandler.AddServices)
				techRoutes.GET("/services", verifyHandler.GetServices)
				techRoutes.DELETE("/services/:id", verifyHandler.RemoveService)

				// Technician service locations
				techRoutes.POST("/service-locations", verifyHandler.AddLocations)
				techRoutes.GET("/service-locations", verifyHandler.GetLocations)
				techRoutes.DELETE("/service-locations/:id", verifyHandler.RemoveLocation)
			}

			// Booking routes
			bookingRoutes := protected.Group("/bookings")
			{
				bookingRoutes.POST("", bookingHandler.Create)
				bookingRoutes.GET("", bookingHandler.List)
				bookingRoutes.GET("/pending-requests", bookingHandler.GetPendingRequests)
				bookingRoutes.GET("/:id", bookingHandler.Get)
				bookingRoutes.POST("/:id/cancel", bookingHandler.Cancel)
				bookingRoutes.POST("/:id/accept", bookingHandler.Accept)
				bookingRoutes.POST("/:id/arrive", bookingHandler.Arrive)
				bookingRoutes.POST("/:id/start", bookingHandler.StartJob)
				bookingRoutes.POST("/:id/complete", bookingHandler.Complete)
				bookingRoutes.POST("/:id/verify-arrival", bookingHandler.VerifyArrival)
			}

			// Chat routes
			chatRoutes := protected.Group("/chat")
			{
				chatRoutes.GET("/bookings/:booking_id/messages", chatHandler.GetMessages)
				chatRoutes.POST("/bookings/:booking_id/messages", chatHandler.SendMessage)
			}

			// Payment routes
			paymentRoutes := protected.Group("/payments")
			{
				paymentRoutes.POST("/bookings/:booking_id/pay", paymentHandler.ProcessPayment)
				paymentRoutes.GET("/history", paymentHandler.GetHistory)
			}

			// Wallet routes
			walletRoutes := protected.Group("/wallet")
			{
				walletRoutes.GET("/balance", walletHandler.GetBalance)
				walletRoutes.GET("/transactions", walletHandler.GetTransactions)
				walletRoutes.POST("/withdraw", walletHandler.RequestWithdrawal)
			}

			// Rating routes
			ratingRoutes := protected.Group("/ratings")
			{
				ratingRoutes.POST("/bookings/:booking_id", ratingHandler.Create)
				ratingRoutes.GET("/technicians/:tech_id", ratingHandler.GetTechnicianRatings)
			}

			// Settings routes
			settingsRoutes := protected.Group("/settings")
			{
				settingsRoutes.PUT("/name", settingsHandler.ChangeName)
				settingsRoutes.PUT("/phone", settingsHandler.ChangePhone)
				settingsRoutes.PUT("/email", settingsHandler.ChangeEmail)
				settingsRoutes.PUT("/language", settingsHandler.ChangeLanguage)
				settingsRoutes.DELETE("/account", settingsHandler.DeleteAccount)
				settingsRoutes.POST("/logout", authHandler.Logout)
			}

			// Support routes
			supportRoutes := protected.Group("/support")
			{
				supportRoutes.POST("/tickets", supportHandler.CreateTicket)
				supportRoutes.GET("/tickets", supportHandler.ListTickets)
				supportRoutes.GET("/tickets/:id", supportHandler.GetTicket)
				supportRoutes.GET("/tickets/:id/messages", supportHandler.GetMessages)
				supportRoutes.POST("/tickets/:id/messages", supportHandler.AddMessage)
			}

			// Notification routes
			notifRoutes := protected.Group("/notifications")
			{
				notifRoutes.GET("", notifHandler.GetNotifications)
				notifRoutes.GET("/unread-count", notifHandler.CountUnread)
				notifRoutes.PUT("/:id/read", notifHandler.MarkRead)
				notifRoutes.PUT("/read-all", notifHandler.MarkAllRead)
			}

			// Address routes
			addressRoutes := protected.Group("/addresses")
			{
				addressRoutes.POST("", addressHandler.Create)
				addressRoutes.GET("", addressHandler.List)
				addressRoutes.GET("/default", addressHandler.GetDefault)
				addressRoutes.PUT("/:id/default", addressHandler.SetDefault)
				addressRoutes.DELETE("/:id", addressHandler.Delete)
			}
		}

		// Admin routes
		adminRoutes := api.Group("/admin")
		adminRoutes.Use(middleware.AuthRequired(cfg))
		adminRoutes.Use(middleware.AdminRequired())
		{
			adminRoutes.GET("/dashboard", adminHandler.Dashboard)
			adminRoutes.GET("/users", adminHandler.ListUsers)
			adminRoutes.GET("/users/:id", adminHandler.GetUser)
			adminRoutes.PUT("/users/:id/ban", adminHandler.BanUser)
			adminRoutes.PUT("/users/:id/unban", adminHandler.UnbanUser)
			adminRoutes.DELETE("/users/:id", adminHandler.DeleteUser)
			adminRoutes.POST("/users/:id/reset-password", adminHandler.ResetUserPassword)
			adminRoutes.GET("/technicians", adminHandler.ListTechnicians)
			adminRoutes.GET("/technicians/:id", adminHandler.GetTechnician)
			adminRoutes.GET("/technicians/:id/verification", adminHandler.GetTechnicianVerification)
			adminRoutes.PUT("/technicians/:id/verify", adminHandler.VerifyTechnician)
			adminRoutes.PUT("/technicians/:id/ban", adminHandler.BanTechnician)
			adminRoutes.PUT("/technicians/:id/unban", adminHandler.UnbanTechnician)
			adminRoutes.GET("/bookings", adminHandler.ListBookings)
			adminRoutes.GET("/bookings/:id", adminHandler.GetBooking)
			adminRoutes.POST("/categories", categoryHandler.Create)
			adminRoutes.PUT("/categories/:id", categoryHandler.Update)
			adminRoutes.DELETE("/categories/:id", categoryHandler.Delete)
			adminRoutes.GET("/payments", adminHandler.ListPayments)
			adminRoutes.GET("/reports/revenue", adminHandler.RevenueReport)
			adminRoutes.GET("/reports/bookings", adminHandler.BookingReport)
			adminRoutes.GET("/support/tickets", supportHandler.AdminListTickets)
			adminRoutes.POST("/support/tickets/:id/messages", supportHandler.AddMessage)
			adminRoutes.PUT("/support/tickets/:id/assign", supportHandler.AssignTicket)
			adminRoutes.PUT("/support/tickets/:id/close", supportHandler.CloseTicket)
		}
	}

	// HTTP Server
	apiServer := &http.Server{
		Addr:         ":" + cfg.ServerPort,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// WebSocket Server
	wsRouter := gin.Default()
	wsRouter.Use(middleware.CORS())
	wsRouter.GET("/ws", func(c *gin.Context) {
		websocket.ServeWS(wsHub, c, cfg)
	})

	wsServer := &http.Server{
		Addr:         ":" + cfg.WSPort,
		Handler:      wsRouter,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Start servers
	go func() {
		log.Printf("API server starting on port %s", cfg.ServerPort)
		if err := apiServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("API server error: %v", err)
		}
	}()

	go func() {
		log.Printf("WebSocket server starting on port %s", cfg.WSPort)
		if err := wsServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("WebSocket server error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down servers...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := apiServer.Shutdown(ctx); err != nil {
		log.Printf("API server forced to shutdown: %v", err)
	}

	if err := wsServer.Shutdown(ctx); err != nil {
		log.Printf("WebSocket server forced to shutdown: %v", err)
	}

	log.Println("Servers stopped")
}
