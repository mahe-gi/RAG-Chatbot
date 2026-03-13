@echo off
setlocal enabledelayedexpansion

echo 🚀 RAG Chatbot v2.0 - Development Setup
echo ========================================

REM Create .env if it doesn't exist
if not exist .env (
    echo 📝 Creating .env from .env.example...
    copy .env.example .env
    echo ⚠️  Please edit .env and add your OPENAI_API_KEY
)

REM Create virtual environment
if not exist venv (
    echo 🐍 Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo ✅ Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo 📦 Installing dependencies...
python -m pip install -q --upgrade pip
pip install -q -r requirements.txt

REM Create docs directory
if not exist docs mkdir docs

REM Create sample document if docs is empty
dir /b docs | findstr "^" >nul || (
    echo 📄 Creating sample document...
    (
        echo Retrieval-Augmented Generation ^(RAG^)
        echo.
        echo RAG is a technique that combines a large language model with a document retrieval system.
        echo Instead of relying solely on the LLM's training data, RAG retrieves relevant documents
        echo from a knowledge base and uses them as context for generating answers.
        echo.
        echo How RAG Works:
        echo 1. Document Ingestion: Documents are split into chunks and embedded into vectors
        echo 2. Vector Storage: Embeddings are stored in a vector database like ChromaDB
        echo 3. Query Processing: User questions are embedded using the same model
        echo 4. Retrieval: The system finds the most relevant document chunks
        echo 5. Generation: The LLM generates an answer using the retrieved context
        echo.
        echo Benefits of RAG:
        echo - Reduces hallucinations by grounding answers in real documents
        echo - Enables Q&A over private or proprietary content
        echo - No need to fine-tune or retrain the LLM
        echo - Easy to update knowledge by adding new documents
    ) > docs\sample.txt
)

REM Ingest documents
echo 📚 Ingesting documents...
python ingest.py

REM Create static directory
if not exist static mkdir static

echo.
echo ✅ Setup complete!
echo.
echo 🌐 Starting server at http://localhost:8000
echo 📖 API docs at http://localhost:8000/docs
echo.
echo Demo accounts:
echo   demo@ragbot.ai / password
echo   admin@ragbot.ai / admin123
echo.

REM Start server
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
