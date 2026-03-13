#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${BOLD}=========================================="
echo "RAG Chatbot v2.0 - Interactive Setup"
echo -e "==========================================${NC}"
echo ""

# ============================================
# AI Model Configuration
# ============================================
echo -e "${CYAN}${BOLD}1. AI Model Configuration${NC}"
echo ""
echo "Choose your AI provider:"
echo "  1) Ollama (Local, Free, Recommended)"
echo "  2) OpenAI (API Key Required, Paid)"
echo ""
read -p "Enter choice [1-2]: " ai_choice

if [ "$ai_choice" = "2" ]; then
    echo ""
    read -p "Enter your OpenAI API Key: " openai_key
    if [ -z "$openai_key" ]; then
        echo -e "${RED}Error: OpenAI API key is required${NC}"
        exit 1
    fi
    USE_OLLAMA=false
    OPENAI_API_KEY=$openai_key
else
    USE_OLLAMA=true
    OPENAI_API_KEY=""
fi

echo ""

# ============================================
# Database Configuration
# ============================================
echo -e "${CYAN}${BOLD}2. Database Configuration${NC}"
echo ""
echo "Choose your database setup:"
echo "  1) Docker PostgreSQL (Recommended, Easy)"
echo "  2) Custom Database URL (Existing PostgreSQL)"
echo "  3) Skip Database (In-memory auth only)"
echo ""
read -p "Enter choice [1-3]: " db_choice

if [ "$db_choice" = "2" ]; then
    echo ""
    read -p "Enter Database URL (e.g., postgresql://user:pass@host:5432/db): " db_url
    if [ -z "$db_url" ]; then
        echo -e "${RED}Error: Database URL is required${NC}"
        exit 1
    fi
    USE_DOCKER_DB=false
    USE_DATABASE=true
    DATABASE_URL=$db_url
elif [ "$db_choice" = "3" ]; then
    USE_DOCKER_DB=false
    USE_DATABASE=false
    DATABASE_URL=""
else
    USE_DOCKER_DB=true
    USE_DATABASE=true
    DATABASE_URL="postgresql://ragbot:ragbot123@localhost:5432/ragbot_db"
fi

echo ""
echo -e "${YELLOW}=========================================="
echo "Configuration Summary"
echo -e "==========================================${NC}"
echo ""
echo -e "${BOLD}AI Model:${NC}"
if [ "$USE_OLLAMA" = true ]; then
    echo "  ✓ Ollama (Local)"
else
    echo "  ✓ OpenAI (API Key: ${OPENAI_API_KEY:0:10}...)"
fi
echo ""
echo -e "${BOLD}Database:${NC}"
if [ "$USE_DOCKER_DB" = true ]; then
    echo "  ✓ Docker PostgreSQL"
elif [ "$USE_DATABASE" = true ]; then
    echo "  ✓ Custom Database"
else
    echo "  ✓ In-memory (No persistence)"
fi
echo ""
read -p "Continue with this configuration? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Setup cancelled"
    exit 0
fi

echo ""
echo -e "${CYAN}${BOLD}Starting Setup...${NC}"
echo ""

# ============================================
# Backend Setup
# ============================================
echo -e "${BLUE}[1/4] Setting up Backend...${NC}"
cd backend

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "  Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
echo "  Installing Python dependencies..."
venv/bin/python3 -m pip install -q --upgrade pip

# Install base dependencies
venv/bin/python3 -m pip install -q fastapi uvicorn python-dotenv python-multipart 'python-jose[cryptography]' passlib bcrypt email-validator
venv/bin/python3 -m pip install -q langchain langchain-community chromadb pdfplumber

# Install database dependencies if needed
if [ "$USE_DATABASE" = true ]; then
    echo "  Installing database dependencies..."
    venv/bin/python3 -m pip install -q sqlalchemy asyncpg
fi

# Create .env file
echo "  Creating configuration file..."
cat > .env << EOF
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF

if [ "$USE_OLLAMA" = false ]; then
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env
fi

if [ "$USE_DATABASE" = true ]; then
    echo "DATABASE_URL=$DATABASE_URL" >> .env
fi

# Setup database if using SQLAlchemy
if [ "$USE_DATABASE" = true ]; then
    echo "  Database will be initialized on first run..."
    
    if [ "$USE_DOCKER_DB" = true ]; then
        # Start Docker PostgreSQL
        cd ..
        if docker info > /dev/null 2>&1; then
            echo "  Starting PostgreSQL..."
            docker-compose up -d postgres > /dev/null 2>&1
            sleep 5
        else
            echo -e "${YELLOW}  Warning: Docker not running, skipping PostgreSQL start${NC}"
        fi
        cd backend
    fi
fi

cd ..
echo -e "${GREEN}  ✓ Backend setup complete${NC}"
echo ""

# ============================================
# Frontend Setup
# ============================================
echo -e "${BLUE}[2/4] Setting up Frontend...${NC}"
cd frontend

if [ ! -d "node_modules" ]; then
    echo "  Installing frontend dependencies..."
    npm install > /dev/null 2>&1
fi

cd ..
echo -e "${GREEN}  ✓ Frontend setup complete${NC}"
echo ""

# ============================================
# AI Model Setup
# ============================================
if [ "$USE_OLLAMA" = true ]; then
    echo -e "${BLUE}[3/4] Setting up Ollama...${NC}"
    
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}  Error: Ollama not installed${NC}"
        echo "  Install from: https://ollama.ai"
        exit 1
    fi
    
    # Start Ollama if not running
    if ! lsof -ti:11434 > /dev/null 2>&1; then
        echo "  Starting Ollama server..."
        ollama serve > ollama.log 2>&1 &
        sleep 3
    fi
    
    # Pull phi model
    if ! ollama list | grep -q "phi"; then
        echo "  Pulling phi model (this may take a few minutes)..."
        ollama pull phi
    fi
    
    echo -e "${GREEN}  ✓ Ollama setup complete${NC}"
else
    echo -e "${BLUE}[3/4] Using OpenAI API${NC}"
    echo -e "${GREEN}  ✓ OpenAI configured${NC}"
fi
echo ""

# ============================================
# Document Ingestion
# ============================================
echo -e "${BLUE}[4/4] Setting up Documents...${NC}"

# Create docs directory
if [ ! -d "docs" ]; then
    mkdir -p docs
fi

# Create sample document
if [ ! "$(ls -A docs)" ]; then
    echo "  Creating sample document..."
    cat > docs/sample.txt << 'EOF'
Retrieval-Augmented Generation (RAG)

RAG is a technique that combines a large language model with a document retrieval system.
Instead of relying solely on the LLM's training data, RAG retrieves relevant documents
from a knowledge base and uses them as context for generating answers.

How RAG Works:
1. Document Ingestion: Documents are split into chunks and embedded into vectors
2. Vector Storage: Embeddings are stored in a vector database like ChromaDB
3. Query Processing: User questions are embedded using the same model
4. Retrieval: The system finds the most relevant document chunks
5. Generation: The LLM generates an answer using the retrieved context

Benefits of RAG:
- Reduces hallucinations by grounding answers in real documents
- Enables Q&A over private or proprietary content
- No need to fine-tune or retrain the LLM
- Easy to update knowledge by adding new documents
EOF
fi

# Ingest documents
echo "  Ingesting documents..."
cd backend
source venv/bin/activate
venv/bin/python3 ingest_fast.py > /dev/null 2>&1 || echo -e "${YELLOW}  Warning: Document ingestion skipped${NC}"
cd ..

echo -e "${GREEN}  ✓ Documents ready${NC}"
echo ""

# ============================================
# Success Message
# ============================================
echo ""
echo -e "${GREEN}${BOLD}=========================================="
echo "✓ Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}Start your application:${NC}"
echo ""
echo -e "  ${YELLOW}./dev.sh${NC}"
echo ""
echo -e "${CYAN}${BOLD}Access URLs:${NC}"
echo ""
echo "  Frontend:  http://localhost:5173"
echo "  Backend:   http://localhost:8000"
echo "  API Docs:  http://localhost:8000/docs"
echo ""
echo -e "${CYAN}${BOLD}Demo Login:${NC}"
echo ""
echo "  Email:    demo@ragbot.ai"
echo "  Password: password"
echo ""
echo -e "${CYAN}${BOLD}Configuration saved to:${NC}"
echo ""
echo "  backend/.env"
echo ""
