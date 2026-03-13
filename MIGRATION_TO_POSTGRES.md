# Migration Guide: From In-Memory to PostgreSQL

This guide explains the changes made to implement real database authentication.

## What Changed

### Before (In-Memory Auth)
- Hardcoded demo users in `auth/auth.py`
- No database persistence
- Users lost on server restart
- SHA256 password hashing

### After (PostgreSQL + Prisma)
- Real PostgreSQL database
- Persistent user storage
- Prisma ORM for type-safe queries
- bcrypt password hashing (more secure)
- Docker containerization

## New Files

### Database Configuration
- `docker-compose.yml` - PostgreSQL container setup
- `backend/prisma/schema.prisma` - Database schema
- `backend/auth/database.py` - Prisma client connection

### Setup Scripts
- `backend/setup_db.sh` - Database initialization
- `setup_all.sh` - Complete project setup

### Documentation
- `DATABASE_SETUP.md` - Detailed database guide
- `MIGRATION_TO_POSTGRES.md` - This file

## Modified Files

### Backend
- `backend/requirements.txt` - Added Prisma, asyncpg, bcrypt
- `backend/.env.example` - Added DATABASE_URL
- `backend/auth/auth.py` - Rewritten to use Prisma
- `backend/auth/routes.py` - Updated for async operations
- `backend/main.py` - Added lifespan events for DB connection

### Configuration
- `.gitignore` - Added database and Prisma files
- `dev.sh` - Added PostgreSQL check
- `README.md` - Updated with database setup

## Database Schema

### Users Table
```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  password  String
  name      String?
  isActive  Boolean  @default(true)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  sessions  Session[]
}
```

### Sessions Table
```prisma
model Session {
  id        String   @id @default(uuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id])
}
```

## Migration Steps

### 1. Install Docker Desktop
Download from: https://www.docker.com/products/docker-desktop

### 2. Start PostgreSQL
```bash
docker-compose up -d postgres
```

### 3. Setup Database
```bash
cd backend
./setup_db.sh
```

This will:
- Install Prisma dependencies
- Generate Prisma client
- Create database tables
- Create demo users

### 4. Update Environment
```bash
cd backend
cp .env.example .env
# Edit .env and add:
# DATABASE_URL=postgresql://ragbot:ragbot123@localhost:5432/ragbot_db
```

### 5. Test
```bash
# Start the application
./dev.sh

# Test login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@ragbot.ai", "password": "password"}'
```

## API Changes

### Authentication Flow

**Before:**
1. Login → Check hardcoded users → Return JWT

**After:**
1. Login → Query PostgreSQL → Verify bcrypt hash → Return JWT
2. Protected routes → Verify JWT → Query PostgreSQL for user

### New Endpoints

All endpoints remain the same:
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `GET /auth/me` - Get current user

### Response Format

**Login Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**User Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "demo@ragbot.ai",
  "name": "Demo User",
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## Benefits

### Security
✓ bcrypt password hashing (vs SHA256)
✓ Proper salt generation
✓ Configurable work factor
✓ Industry standard

### Persistence
✓ Users survive server restarts
✓ Session management
✓ Audit trail (createdAt, updatedAt)

### Scalability
✓ Can handle thousands of users
✓ Indexed queries
✓ Relational data
✓ Easy to add features (roles, permissions, etc.)

### Developer Experience
✓ Type-safe queries with Prisma
✓ Auto-generated client
✓ Migration system
✓ Database GUI (Prisma Studio)

## Rollback

If you need to rollback to in-memory auth:

```bash
git log --oneline  # Find commit before migration
git checkout <commit-hash>
```

Or manually:
1. Remove `docker-compose.yml`
2. Remove `backend/prisma/`
3. Remove `backend/auth/database.py`
4. Restore old `backend/auth/auth.py` and `backend/auth/routes.py`
5. Remove Prisma from `requirements.txt`

## Adding New Features

### Add a Field to User
1. Edit `backend/prisma/schema.prisma`
```prisma
model User {
  // ... existing fields
  role String @default("user")  // Add this
}
```

2. Push changes
```bash
cd backend
prisma db push
```

3. Update code to use new field

### Add a New Table
1. Edit `backend/prisma/schema.prisma`
```prisma
model Document {
  id        String   @id @default(uuid())
  userId    String
  filename  String
  content   String
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id])
}
```

2. Update User model
```prisma
model User {
  // ... existing fields
  documents Document[]
}
```

3. Push changes
```bash
cd backend
prisma db push
```

## Troubleshooting

### Prisma client not found
```bash
cd backend
source venv/bin/activate
pip install prisma
prisma generate
```

### Database connection error
```bash
# Check PostgreSQL
docker ps | grep ragbot_postgres

# Check logs
docker logs ragbot_postgres

# Restart
docker-compose restart postgres
```

### Migration conflicts
```bash
cd backend
prisma db push --force-reset  # WARNING: Deletes all data
```

## Production Considerations

1. **Use strong passwords** for PostgreSQL
2. **Enable SSL** for database connections
3. **Backup database** regularly
4. **Use environment variables** for all secrets
5. **Implement rate limiting** on auth endpoints
6. **Add email verification** for new users
7. **Implement password reset** flow
8. **Add 2FA** for enhanced security
9. **Monitor database** performance
10. **Set up database replication** for high availability

## Resources

- [Prisma Documentation](https://www.prisma.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
