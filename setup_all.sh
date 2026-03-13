#!/bin/bash
set -e

echo "=========================================="
echo "RAG Chatbot v2.0 - Complete Setup"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"
}

# Check prerequisites
log "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    echo "Install from: https://www.docker.com/products/docker-desktop"
    exit 1
fi
log_success "Docker found"

# Check Ollama
if ! command -v ollama &> /dev/null; then
    log_error "Ollama is not installed"
    echo "Install from: https://ollama.ai"
    exit 1
fi
log_success "Ollama found"

# Check Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed"
    echo "Install from: https://nodejs.org"
    exit 1
fi
log_success "Node.js found ($(node --version))"

# Check Python
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed"
    exit 1
fi
log_success "Python found ($(python3 --version))"

echo ""
log "Step 1/6: Starting PostgreSQL..."
docker-compose up -d postgres
sleep 5
log_success "PostgreSQL started"

echo ""
log "Step 2/6: Setting up backend..."
cd backend

if [ ! -d "venv" ]; then
    log "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
log "Installing Python dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt
log_success "Backend dependencies installed"

log "Setting up database..."
if [ ! -f .env ]; then
    cp .env.example .env
    log_warning "Created .env file - please update SECRET_KEY"
fi

log "Generating Prisma client..."
prisma generate > /dev/null 2>&1
log "Pushing database schema..."
prisma db push > /dev/null 2>&1
log_success "Database ready"

cd ..

echo ""
log "Step 3/6: Setting up frontend..."
cd frontend
if [ ! -d "node_modules" ]; then
    log "Installing frontend dependencies..."
    npm install > /dev/null 2>&1
    log_success "Frontend dependencies installed"
else
    log_success "Frontend dependencies already installed"
fi
cd ..

echo ""
log "Step 4/6: Checking Ollama..."
if ! pgrep -x "ollama" > /dev/null; then
    log_warning "Ollama is not running"
    log "Please start Ollama in another terminal:"
    echo -e "${YELLOW}  cd local_model && ./start_ollama.sh${NC}"
    echo ""
    read -p "Press Enter when Ollama is running..."
fi

log "Checking for phi model..."
if ! ollama list | grep -q "phi"; then
    log "Pulling phi model (this may take a few minutes)..."
    ollama pull phi
fi
log_success "Phi model ready"

echo ""
log "Step 5/6: Creating sample documents..."
if [ ! -d "docs" ]; then
    mkdir -p docs
fi

if [ ! "$(ls -A docs)" ]; then
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
    log_success "Sample document created"
fi

echo ""
log "Step 6/6: Ingesting documents..."
cd backend
source venv/bin/activate
python3 ingest_fast.py > /dev/null 2>&1
log_success "Documents ingested"
cd ..

echo ""
echo "=========================================="
log_success "Setup Complete!"
echo "=========================================="
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo "1. Start Ollama (if not already running):"
echo -e "   ${YELLOW}cd local_model && ./start_ollama.sh${NC}"
echo ""
echo "2. Start the application:"
echo -e "   ${YELLOW}./dev.sh${NC}"
echo ""
echo "3. Open your browser:"
echo -e "   ${GREEN}http://localhost:5173${NC}"
echo ""
echo "4. Login with demo account:"
echo "   Email: demo@ragbot.ai"
echo "   Password: password"
echo ""
echo -e "${CYAN}Services:${NC}"
echo "  - PostgreSQL: localhost:5432"
echo "  - Backend API: localhost:8000"
echo "  - Frontend UI: localhost:5173"
echo "  - Ollama: localhost:11434"
echo ""
