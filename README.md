# RAG Chatbot v2.0

A production-ready Retrieval-Augmented Generation (RAG) chatbot with FastAPI backend, React frontend, and local AI using Ollama.

## Features

- 🔐 JWT Authentication
- 📄 Document Upload (PDF, TXT)
- 🤖 Local AI with Ollama (no API costs)
- 💬 Real-time Chat Interface
- 🎨 Modern React UI with Tailwind CSS
- 🔍 RAG-based Question Answering
- 📊 ChromaDB Vector Storage

## Project Structure

```
.
├── backend/          # FastAPI backend
│   ├── auth/         # Authentication module
│   ├── chroma_db/    # Vector database
│   ├── venv/         # Python virtual environment
│   ├── main.py       # FastAPI app
│   ├── ingest_fast.py
│   ├── retriever_ollama.py
│   └── requirements.txt
├── frontend/         # React + Vite frontend
│   ├── src/
│   │   ├── components/
│   │   │   ├── Login.jsx
│   │   │   └── Chat.jsx
│   │   ├── App.jsx
│   │   └── main.jsx
│   └── package.json
├── local_model/      # Ollama configuration
│   └── start_ollama.sh
├── docs/             # Documents for RAG
└── dev.sh            # Development startup script
```

## Quick Start

### Prerequisites

- Python 3.9+
- Node.js 18+
- Ollama
- Docker Desktop (for PostgreSQL)

### Installation

1. Clone the repository:
```bash
git clone git@github.com:mahe-gi/RAG-Chatbot.git
cd RAG-Chatbot
```

2. Install Ollama:
```bash
# macOS
brew install ollama

# Or download from https://ollama.ai
```

3. Pull the AI model:
```bash
ollama pull phi
```

4. Setup PostgreSQL database:
```bash
# Start PostgreSQL with Docker
docker-compose up -d postgres

# Setup database schema
cd backend
./setup_db.sh
cd ..
```

### Running the Application

**Terminal 1 - Start Ollama:**
```bash
cd local_model
./start_ollama.sh
```

**Terminal 2 - Start Backend & Frontend:**
```bash
./dev.sh
```

The script will:
- Check Ollama is running
- Check PostgreSQL is running (starts if needed)
- Setup Python environment
- Install dependencies
- Ingest documents
- Start backend (port 8000)
- Start frontend (port 5173)

### Access the Application

- Frontend: http://localhost:5173
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

### Demo Accounts

- demo@ragbot.ai / password
- admin@ragbot.ai / admin123

## Usage

1. Login with demo credentials
2. Upload documents (PDF or TXT)
3. Click "Re-index Documents" to process them
4. Ask questions about your documents

## Development

### Backend Only

```bash
cd backend
source venv/bin/activate
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Only

```bash
cd frontend
npm install
npm run dev
```

### Ollama Only

```bash
cd local_model
./start_ollama.sh
```

## Tech Stack

### Backend
- FastAPI
- ChromaDB
- Ollama (phi model)
- pdfplumber
- LangChain
- JWT Authentication
- PostgreSQL + Prisma ORM
- Docker

### Frontend
- React 19
- Vite 8
- Tailwind CSS 3.4
- Axios

### AI
- Ollama (local)
- phi model (1.6GB, fast)

## Configuration

Backend configuration is in `backend/.env`:

```env
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Database
DATABASE_URL=postgresql://ragbot:ragbot123@localhost:5432/ragbot_db
```

Generate a secure SECRET_KEY:
```bash
openssl rand -hex 32
```

## Logs

View real-time logs:

```bash
# Backend logs
tail -f backend.log

# Frontend logs
tail -f frontend.log
```

## Troubleshooting

### Database Issues
```bash
# Check PostgreSQL status
docker ps | grep ragbot_postgres

# View database logs
docker logs ragbot_postgres

# Restart database
docker-compose restart postgres

# Reset database
cd backend
prisma db push --force-reset
```

### Ollama not running
```bash
cd local_model
./start_ollama.sh
```

### Port already in use
```bash
# Kill process on port 8000
lsof -ti:8000 | xargs kill -9

# Kill process on port 5173
lsof -ti:5173 | xargs kill -9
```

### Re-index documents
```bash
cd backend
source venv/bin/activate
python3 ingest_fast.py
```

## License

MIT

## Author

Mahesh
