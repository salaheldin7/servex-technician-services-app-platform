package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/techapp/backend/internal/config"
	"github.com/techapp/backend/internal/database"
	"github.com/techapp/backend/internal/workers"
)

func main() {
	cfg := config.Load()

	db, err := database.NewPostgres(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	rdb := database.NewRedis(cfg)
	defer rdb.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start background workers
	dispatcher := workers.NewDispatcher(db, rdb, cfg)
	dispatcher.Start(ctx)

	log.Println("Worker process started")

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down workers...")
	cancel()
	time.Sleep(5 * time.Second)
	log.Println("Workers stopped")
}
