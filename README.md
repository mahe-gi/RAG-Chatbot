# RAG Chatbot v2.0

A production-ready Retrieval-Augmented Generation (RAG) chatbot with FastAPI backend, React frontend, and flexible AI/database options.

## Features

- 🤖 **Flexible AI**: Choose Ollama (local, free) or OpenAI (API)
- 🗄️ **Flexible Database**: Docker PostgreSQL, custom DB, or in-memory
- 🔐 **JWT Authentication** with bcrypt password hashing
- 📄 **Document Upload** (PDF, TXT)
- 💬 **Real-time Chat Interface**
- 🎨 **Modern React UI** with Tailwind CSS
- 🔍 **RAG-based Q&A** with ChromaDB vector storage

## Quick Start

### 1. Interactive Setup

```bash
./setup.sh
```

This will ask you:
- **AI Model**: Ollama (local) or OpenAI (API key)
- **Database**: Docker PostgreSQL, custom URL, or in-memory

### 2. Start Application

```bash
./dev.sh
```

This starts all services automatically:
- Ollama (if selected)
- PostgreSQL (if selected)
- Backend API
- Frontend UI

### 3. Access

- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

### 4. Login

- Email: `demo@ragbot.ai`
- Password: `password`

## Project Structure

```
.
├── backend/              # FastAPI backend
│   ├── auth/             # Authentication
│   ├── prisma/           # Database schema
│   ├── main.py           # API server
│   └── ingest_fast.py    # Document ingestion
├── frontend/             # React + Vite
│   └── src/components/   # UI components
├── local_model/          # Ollama scripts
├── docs/                 # Documents for RAG
├── setup.sh              # Interactive setup
└── dev.sh                # Start all services
```

## Configuration Options

### AI Model

**Option 1: Ollama (Recommended)**
- Free and local
- No API costs
- Fast phi model (1.6GB)
- Requires: `brew install ollama`

**Option 2: OpenAI**
- Requires API key
- Pay per use
- GPT-3.5/4 models

### Database

**Option 1: Docker PostgreSQL (Recommended)**
- Easy setup
- Persistent storage
- Requires: Docker Desktop

**Option 2: Custom Database**
- Use existing PostgreSQL
- Provide connection URL

**Option 3: In-Memory**
- No database needed
- Users reset on restart
- Good for testing

## Manual Setup

### Prerequisites

```bash
# Install Ollama (if using local AI)
brew install ollama

# Install Docker Desktop (if using Docker DB)
# Download from: https://www.docker.com/products/docker-desktop

# Install Node.js 18+
# Download from: https://nodejs.org

# Python 3.9+ (usually pre-installed on macOS)
```

### Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your configuration
```

### Frontend

```bash
cd frontend
npm install
```

### Database (if using PostgreSQL)

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Setup schema
cd backend
prisma generate
prisma db push
```

### Start Services

```bash
# Terminal 1: Ollama (if using)
ollama serve

# Terminal 2: Backend
cd backend
source venv/bin/activate
python3 -m uvicorn main:app --reload

# Terminal 3: Frontend
cd frontend
npm run dev
```

## Environment Variables

`backend/.env`:

```env
# Required
SECRET_KEY=<generate with: openssl rand -hex 32>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Optional: OpenAI
OPENAI_API_KEY=sk-...

# Optional: Database
DATABASE_URL=postgresql://user:pass@host:5432/db
```

## Usage

### Upload Documents

1. Login to the app
2. Click "Upload Document"
3. Select PDF or TXT file
4. Click "Re-index Documents"

### Ask Questions

Type your question in the chat interface. The AI will answer based on your uploaded documents.

### API Usage

```bash
# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@ragbot.ai", "password": "password"}'

# Chat
curl -X POST http://localhost:8000/chat \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"question": "What is RAG?"}'
```

## Tech Stack

### Backend
- FastAPI
- ChromaDB (vector storage)
- Ollama / OpenAI
- PostgreSQL + Prisma ORM
- pdfplumber (PDF parsing)
- LangChain

### Frontend
- React 19
- Vite 8
- Tailwind CSS 3.4
- Axios

### Infrastructure
- Docker (PostgreSQL)
- Ollama (local AI)

## Troubleshooting

### Docker not running
```bash
# Start Docker Desktop application
# Wait for whale icon in menu bar
```

### Port already in use
```bash
lsof -ti:8000 | xargs kill -9   # Backend
lsof -ti:5173 | xargs kill -9   # Frontend
lsof -ti:5432 | xargs kill -9   # PostgreSQL
```

### Ollama not found
```bash
brew install ollama
ollama pull phi
```

### Database connection error
```bash
# Check PostgreSQL
docker ps | grep ragbot_postgres

# Restart
docker-compose restart postgres
```

## Development

### View Logs

```bash
tail -f backend.log      # Backend
tail -f frontend.log     # Frontend
tail -f ollama.log       # Ollama
docker logs -f ragbot_postgres  # Database
```

### Database GUI

```bash
cd backend
prisma studio
# Opens http://localhost:5555
```

### Re-index Documents

```bash
cd backend
source venv/bin/activate
python3 ingest_fast.py
```

## Production Deployment

1. Generate strong `SECRET_KEY`
2. Use production database
3. Enable HTTPS
4. Set up rate limiting
5. Configure CORS properly
6. Use environment secrets
7. Set up monitoring

## License

MIT

## Author

Mahesh
