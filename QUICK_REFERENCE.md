# Quick Reference

## Setup & Start

```bash
# First time setup (interactive)
./setup.sh

# Start all services
./dev.sh

# Stop all services
# Press Ctrl+C in the terminal running dev.sh
```

## Access URLs

- Frontend: http://localhost:5173
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Database GUI: `cd backend && prisma studio`

## Demo Login

- Email: `demo@ragbot.ai`
- Password: `password`

## Common Commands

### Services

```bash
# Start everything
./dev.sh

# Start Ollama only
ollama serve

# Start PostgreSQL only
docker-compose up -d postgres

# Stop PostgreSQL
docker-compose stop postgres

# View running containers
docker ps
```

### Backend

```bash
cd backend
source venv/bin/activate

# Run server
python3 -m uvicorn main:app --reload

# Ingest documents
python3 ingest_fast.py

# Database operations
prisma generate      # Generate client
prisma db push       # Push schema
prisma studio        # Open GUI
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

### Logs

```bash
# View logs
tail -f backend.log
tail -f frontend.log
tail -f ollama.log
docker logs -f ragbot_postgres

# Follow all logs
tail -f backend.log frontend.log
```

### Ports

```bash
# Check if port is in use
lsof -ti:8000    # Backend
lsof -ti:5173    # Frontend
lsof -ti:5432    # PostgreSQL
lsof -ti:11434   # Ollama

# Kill process on port
lsof -ti:8000 | xargs kill -9
```

## API Examples

### Authentication

```bash
# Register
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }'

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@ragbot.ai",
    "password": "password"
  }'

# Get current user
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer <token>"
```

### Chat

```bash
# Ask question
curl -X POST http://localhost:8000/chat \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is RAG?",
    "session_id": "default"
  }'
```

### Documents

```bash
# Upload document
curl -X POST http://localhost:8000/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@document.pdf"

# Re-index documents
curl -X POST http://localhost:8000/ingest \
  -H "Authorization: Bearer <token>"
```

## Configuration

### Environment Variables

Edit `backend/.env`:

```env
# Required
SECRET_KEY=<openssl rand -hex 32>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Optional: OpenAI
OPENAI_API_KEY=sk-...

# Optional: Database
DATABASE_URL=postgresql://user:pass@host:5432/db
```

### Generate Secret Key

```bash
openssl rand -hex 32
```

## Ollama Commands

```bash
# Start server
ollama serve

# List models
ollama list

# Pull model
ollama pull phi
ollama pull llama2

# Remove model
ollama rm phi

# Test model
curl http://localhost:11434/api/tags
```

## Docker Commands

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Stop PostgreSQL
docker-compose stop postgres

# View logs
docker logs ragbot_postgres
docker logs -f ragbot_postgres  # Follow

# Connect to database
docker exec -it ragbot_postgres psql -U ragbot -d ragbot_db

# Remove everything (including data)
docker-compose down -v
```

## Database Commands

```bash
cd backend
source venv/bin/activate

# Generate Prisma client
prisma generate

# Push schema to database
prisma db push

# Reset database (WARNING: deletes all data)
prisma db push --force-reset

# Open database GUI
prisma studio
```

## Troubleshooting

### Docker not running
```bash
# Start Docker Desktop app
# Wait for whale icon in menu bar
```

### Port conflicts
```bash
# Find and kill process
lsof -ti:8000 | xargs kill -9
```

### Ollama not responding
```bash
# Restart Ollama
pkill ollama
ollama serve
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

### Frontend not loading
```bash
# Check logs
tail -f frontend.log

# Reinstall dependencies
cd frontend
rm -rf node_modules
npm install
```

### Backend errors
```bash
# Check logs
tail -f backend.log

# Reinstall dependencies
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

## Project Structure

```
.
├── backend/              # FastAPI backend
│   ├── auth/             # Authentication
│   ├── prisma/           # Database schema
│   ├── venv/             # Python environment
│   ├── main.py           # API server
│   └── .env              # Configuration
├── frontend/             # React frontend
│   ├── src/              # Source code
│   └── node_modules/     # Dependencies
├── local_model/          # Ollama scripts
├── docs/                 # Documents for RAG
├── setup.sh              # Interactive setup
├── dev.sh                # Start all services
└── docker-compose.yml    # PostgreSQL config
```

## Git Commands

```bash
# Check status
git status

# Add changes
git add -A

# Commit
git commit -m "message"

# Push
git push origin main

# View history
git log --oneline
```

## Performance Tips

1. Use phi model (faster than llama2)
2. Keep services running (don't restart)
3. Ingest documents once
4. Use larger chunks for faster ingestion
5. Close unused browser tabs

## Security Checklist

- [ ] Change default PostgreSQL password
- [ ] Generate strong SECRET_KEY
- [ ] Use HTTPS in production
- [ ] Enable rate limiting
- [ ] Add email verification
- [ ] Regular database backups
- [ ] Monitor logs
