# Quick Reference Card

## One-Time Setup

```bash
# 1. Install prerequisites
# - Docker Desktop
# - Ollama
# - Node.js 18+
# - Python 3.9+

# 2. Run complete setup
./setup_all.sh

# This will:
# - Start PostgreSQL
# - Setup backend + database
# - Setup frontend
# - Pull Ollama model
# - Ingest sample documents
```

## Daily Usage

### Start Everything (2 Terminals)

**Terminal 1 - Ollama:**
```bash
cd local_model
./start_ollama.sh
```

**Terminal 2 - App:**
```bash
./dev.sh
```

### Access

- Frontend: http://localhost:5173
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Database UI: `cd backend && prisma studio`

### Demo Login

- Email: demo@ragbot.ai
- Password: password

## Common Commands

### Database

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Stop PostgreSQL
docker-compose stop postgres

# View logs
docker logs ragbot_postgres

# Database GUI
cd backend && prisma studio

# Reset database
cd backend && prisma db push --force-reset
```

### Backend

```bash
cd backend
source venv/bin/activate

# Run server
python3 -m uvicorn main:app --reload

# Ingest documents
python3 ingest_fast.py

# Generate Prisma client
prisma generate

# Push schema changes
prisma db push
```

### Frontend

```bash
cd frontend

# Install dependencies
npm install

# Run dev server
npm run dev

# Build for production
npm run build
```

### Ollama

```bash
# Start server
ollama serve

# List models
ollama list

# Pull model
ollama pull phi

# Remove model
ollama rm phi
```

### Docker

```bash
# View running containers
docker ps

# Stop all containers
docker-compose down

# Remove everything (including data)
docker-compose down -v

# View logs
docker logs -f ragbot_postgres
```

## Project Structure

```
.
├── backend/              # FastAPI + Python
│   ├── auth/             # Authentication
│   ├── prisma/           # Database schema
│   ├── main.py           # API server
│   └── ingest_fast.py    # Document ingestion
├── frontend/             # React + Vite
│   └── src/components/   # UI components
├── local_model/          # Ollama scripts
├── docs/                 # Documents for RAG
├── dev.sh                # Main startup script
└── docker-compose.yml    # PostgreSQL config
```

## API Endpoints

### Authentication
```bash
# Register
POST /auth/register
Body: {"email": "user@example.com", "password": "pass", "name": "Name"}

# Login
POST /auth/login
Body: {"email": "user@example.com", "password": "pass"}

# Get current user
GET /auth/me
Header: Authorization: Bearer <token>
```

### Chat
```bash
# Ask question
POST /chat
Header: Authorization: Bearer <token>
Body: {"question": "What is RAG?", "session_id": "default"}
```

### Documents
```bash
# Upload document
POST /upload
Header: Authorization: Bearer <token>
Body: multipart/form-data with file

# Re-index documents
POST /ingest
Header: Authorization: Bearer <token>
```

## Environment Variables

`backend/.env`:
```env
SECRET_KEY=<generate with: openssl rand -hex 32>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
DATABASE_URL=postgresql://ragbot:ragbot123@localhost:5432/ragbot_db
```

## Troubleshooting

### Port already in use
```bash
# Find and kill process
lsof -ti:8000 | xargs kill -9   # Backend
lsof -ti:5173 | xargs kill -9   # Frontend
lsof -ti:5432 | xargs kill -9   # PostgreSQL
lsof -ti:11434 | xargs kill -9  # Ollama
```

### Database connection error
```bash
# Check if running
docker ps | grep ragbot_postgres

# Restart
docker-compose restart postgres

# Check logs
docker logs ragbot_postgres
```

### Prisma errors
```bash
cd backend
source venv/bin/activate
pip install --upgrade prisma
prisma generate
```

### Ollama not responding
```bash
# Check if running
curl http://localhost:11434/api/tags

# Restart
pkill ollama
ollama serve
```

## Git Commands

```bash
# Check status
git status

# Add all changes
git add -A

# Commit
git commit -m "your message"

# Push to GitHub
git push origin main

# View history
git log --oneline

# View changes
git diff
```

## Logs

```bash
# Backend logs
tail -f backend.log

# Frontend logs
tail -f frontend.log

# PostgreSQL logs
docker logs -f ragbot_postgres

# All logs
tail -f backend.log frontend.log
```

## Performance Tips

1. Use phi model (faster than llama2)
2. Keep PostgreSQL running (don't restart)
3. Ingest documents once, query many times
4. Use larger chunks for faster ingestion
5. Close unused browser tabs

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Generate strong SECRET_KEY
- [ ] Use HTTPS in production
- [ ] Enable rate limiting
- [ ] Add email verification
- [ ] Implement password reset
- [ ] Regular database backups
- [ ] Monitor logs for suspicious activity

## Resources

- [FastAPI Docs](https://fastapi.tiangolo.com)
- [Prisma Docs](https://www.prisma.io/docs)
- [React Docs](https://react.dev)
- [Ollama Docs](https://ollama.ai/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs)
