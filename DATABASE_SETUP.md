# Database Setup Guide

This guide explains how to set up PostgreSQL with Prisma for real authentication.

## Architecture

- **Database**: PostgreSQL 16 (Alpine - lightweight)
- **ORM**: Prisma (Python client)
- **Container**: Docker Compose
- **Authentication**: JWT with bcrypt password hashing

## Quick Setup

### 1. Start PostgreSQL

```bash
docker-compose up -d postgres
```

This will:
- Pull PostgreSQL 16 Alpine image (lightweight)
- Create a container named `ragbot_postgres`
- Expose port 5432
- Create database `ragbot_db`
- Set up user `ragbot` with password `ragbot123`

### 2. Setup Database Schema

```bash
cd backend
./setup_db.sh
```

This will:
- Activate Python virtual environment
- Install Prisma and dependencies
- Generate Prisma client
- Create database tables (users, sessions)
- Create demo users

### 3. Verify Setup

```bash
# Check if PostgreSQL is running
docker ps | grep ragbot_postgres

# Check database connection
docker exec ragbot_postgres psql -U ragbot -d ragbot_db -c "\dt"
```

You should see tables: `users` and `sessions`

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR UNIQUE NOT NULL,
  password VARCHAR NOT NULL,
  name VARCHAR,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Sessions Table
```sql
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Demo Users

Two demo users are automatically created:

1. **Demo User**
   - Email: demo@ragbot.ai
   - Password: password

2. **Admin User**
   - Email: admin@ragbot.ai
   - Password: admin123

## Environment Variables

Add to `backend/.env`:

```env
SECRET_KEY=your-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Database
DATABASE_URL=postgresql://ragbot:ragbot123@localhost:5432/ragbot_db
```

## Prisma Commands

### Generate Client
```bash
cd backend
prisma generate
```

### Push Schema to Database
```bash
cd backend
prisma db push
```

### View Database in Browser
```bash
cd backend
prisma studio
```

This opens a web UI at http://localhost:5555 to view/edit data.

### Reset Database
```bash
cd backend
prisma db push --force-reset
```

## Docker Commands

### Start PostgreSQL
```bash
docker-compose up -d postgres
```

### Stop PostgreSQL
```bash
docker-compose stop postgres
```

### View Logs
```bash
docker logs ragbot_postgres
docker logs -f ragbot_postgres  # Follow logs
```

### Connect to PostgreSQL CLI
```bash
docker exec -it ragbot_postgres psql -U ragbot -d ragbot_db
```

### Remove Everything (including data)
```bash
docker-compose down -v
```

## Connection Details

- **Host**: localhost
- **Port**: 5432
- **Database**: ragbot_db
- **User**: ragbot
- **Password**: ragbot123
- **Connection String**: `postgresql://ragbot:ragbot123@localhost:5432/ragbot_db`

## API Endpoints

### Register New User
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword",
    "name": "John Doe"
  }'
```

### Login
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@ragbot.ai",
    "password": "password"
  }'
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### Get Current User
```bash
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Troubleshooting

### PostgreSQL not starting
```bash
# Check if port 5432 is already in use
lsof -ti:5432

# Kill existing process
lsof -ti:5432 | xargs kill -9

# Restart container
docker-compose restart postgres
```

### Prisma client not found
```bash
cd backend
source venv/bin/activate
pip install prisma
prisma generate
```

### Database connection error
```bash
# Check if PostgreSQL is running
docker ps | grep ragbot_postgres

# Check logs
docker logs ragbot_postgres

# Verify connection
docker exec ragbot_postgres pg_isready -U ragbot
```

### Reset everything
```bash
# Stop and remove containers
docker-compose down -v

# Remove Prisma client
cd backend
rm -rf venv/lib/python*/site-packages/prisma

# Start fresh
docker-compose up -d postgres
./setup_db.sh
```

## Security Notes

1. **Change default password** in production
2. **Use strong SECRET_KEY** (generate with `openssl rand -hex 32`)
3. **Enable SSL** for PostgreSQL in production
4. **Use environment variables** for sensitive data
5. **Implement rate limiting** for auth endpoints
6. **Add email verification** for new users
7. **Implement password reset** functionality

## Production Deployment

For production, update `docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    # Add SSL configuration
    command: >
      postgres
      -c ssl=on
      -c ssl_cert_file=/etc/ssl/certs/server.crt
      -c ssl_key_file=/etc/ssl/private/server.key
```

## Benefits of This Setup

✓ Real database persistence (not in-memory)
✓ Proper user management with Prisma ORM
✓ Secure password hashing with bcrypt
✓ JWT token authentication
✓ Easy to scale and deploy
✓ Lightweight PostgreSQL (Alpine image)
✓ Docker containerization
✓ Type-safe database queries with Prisma
