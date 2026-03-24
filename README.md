# Tech App - Home Services Platform

## Architecture

- **Mobile App**: Flutter (single binary, role-based access)
- **Backend**: Go modular monolith
- **Admin Panel**: React web app
- **Database**: PostgreSQL + PostGIS
- **Cache**: Redis
- **Storage**: AWS S3

## Project Structure

```
tech-app/
├── backend/          # Go modular monolith
├── mobile/           # Flutter app
├── admin/            # React admin panel
├── docker-compose.yml
└── .env.example
```

## Getting Started

### Prerequisites

- Go 1.22+
- Flutter 3.19+
- Node.js 20+
- Docker & Docker Compose
- PostgreSQL 16 with PostGIS
- Redis 7+

### Backend

```bash
cd backend
cp ../.env.example .env
go mod download
go run cmd/api/main.go
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

### Admin Panel

```bash
cd admin
npm install
npm run dev
```

### Docker (Full Stack)

```bash
docker-compose up -d
```

## Performance Targets

- Booking match: < 1 second
- API response: < 200 ms
- Socket delivery: < 120 ms

## Scaling Strategy

- Phase 1: Modular monolith
- Phase 2: Extract matching service (>5k concurrent bookings)
- Phase 3: Extract chat
- Phase 4: Introduce Kafka
