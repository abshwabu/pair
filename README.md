# Pair

Pair is an accountability app that matches two users around a shared goal (reading a book, watching a show, a fitness habit, etc.) and gives them a shared todo list, real-time chat, and daily check-in streaks.

## Repo Layout

```
/backend   → Laravel 11 API (PHP 8.3, Sanctum, Horizon, Reverb)
/mobile    → Flutter 3.x mobile app (Riverpod, GoRouter, Dio)
/web       → Next.js 14 web client (Phase 2 — placeholder only)
```

## Prerequisites

- **Docker & Docker Compose** (for backend services)
- **Flutter 3.x** (for mobile development)
- **PHP 8.3 & Composer** (only if running backend outside Docker)

## Getting Started

### 1. Backend (Laravel + Postgres + Redis + Reverb)

```bash
# From the repo root
cp backend/.env.example backend/.env

# Start all services
docker-compose up --build -d

# Run migrations (first time)
docker exec -it pair_backend_app php artisan migrate

# Generate app key (first time)
docker exec -it pair_backend_app php artisan key:generate
```

Services:
| Service  | URL / Port        |
|----------|-------------------|
| Laravel  | http://localhost:8000 |
| Reverb   | ws://localhost:8080   |
| Postgres | localhost:5432        |
| Redis    | localhost:6379        |

### 2. Mobile (Flutter)

```bash
cd mobile
flutter pub get
```

**Emulator / simulator** (backend on the same machine):

```bash
flutter run
```

**Physical device** (phone must reach your dev machine over Wi‑Fi):

```bash
cp dart_defines.local.json.example dart_defines.local.json
# Edit dart_defines.local.json — set API_BASE_URL to http://<your-lan-ip>:8000/api/v1

# From repo root:
./scripts/run_mobile_dev.sh
```

Or pass defines inline (stop any running app first — hot reload does **not** apply new values):

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1 \
  --dart-define=REVERB_PORT=8080 \
  --dart-define=REVERB_SCHEME=http
```

On startup, debug builds log the resolved `API_BASE_URL` and Reverb endpoint. If you see `http://10.0.2.2:8000/api/v1` on a physical phone, the defines were not compiled in — quit the app and run again with the flags above.

### 3. Web (Phase 2)

Not built yet. See `/web/README.md`.

## API Conventions

- REST endpoints under `/api/v1/...`
- JSON responses wrapped as:
  ```json
  {
    "data": { ... },
    "meta": { ... },
    "error": null
  }
  ```
- Auth via `Authorization: Bearer <token>` header (Laravel Sanctum)

## Database

PostgreSQL 16 with UUID primary keys. Tables:

`users` · `goals` · `pod_requests` · `pods` · `pod_members` · `todos` · `messages` · `check_ins` · `streaks` · `reports` · `blocks` · `notifications`

## License

Private — not open source.
# pair
