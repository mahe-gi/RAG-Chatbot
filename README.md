# RAG Chatbot v2.0

AI-powered document assistant using Retrieval-Augmented Generation (RAG).

## Quick Start

### Windows
```bash
dev.bat
```

### macOS/Linux
```bash
chmod +x dev.sh
./dev.sh
```

The script will:
1. Create a virtual environment
2. Install dependencies
3. Create `.env` from `.env.example`
4. Ingest sample documents
5. Start the server at http://localhost:8000

## Setup

1. Add your OpenAI API key to `.env`:
```
OPENAI_API_KEY=your_key_here
```

2. Add documents to the `docs/` folder (PDF or TXT files)

3. Run the ingest script:
```bash
python ingest.py
```

## Demo Accounts

- `demo@ragbot.ai` / `password`
- `admin@ragbot.ai` / `admin123`

## API Endpoints

- `POST /auth/login` - Login
- `POST /auth/logout` - Logout
- `GET /auth/me` - Get current user
- `POST /chat` - Ask a question (requires auth)
- `POST /ingest` - Ingest documents (requires auth)
- `GET /health` - Health check

API docs: http://localhost:8000/docs

## CLI Mode

```bash
python chat.py
```

## Tech Stack

- FastAPI + Uvicorn
- LangChain + OpenAI
- ChromaDB
- JWT authentication
- Vanilla JS frontend
