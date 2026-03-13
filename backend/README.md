# Backend - FastAPI RAG Chatbot

This directory contains the FastAPI backend for the RAG Chatbot.

## Features

- JWT Authentication
- Document Upload (PDF, TXT)
- Document Ingestion with ChromaDB
- RAG-based Question Answering
- Ollama Integration (Local AI)

## Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings
```

## Run

```bash
# From project root
./dev.sh

# Or manually
cd backend
source venv/bin/activate
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and get JWT token
- `POST /chat` - Ask questions (requires auth)
- `POST /upload` - Upload documents (requires auth)
- `POST /ingest` - Re-index documents (requires auth)
- `GET /docs` - API documentation

## Demo Accounts

- demo@ragbot.ai / password
- admin@ragbot.ai / admin123

## Structure

- `main.py` - FastAPI application
- `auth/` - Authentication module
- `ingest_fast.py` - Document ingestion with pdfplumber
- `retriever_ollama.py` - RAG retrieval with Ollama
- `chroma_db/` - Vector database storage
- `venv/` - Python virtual environment
