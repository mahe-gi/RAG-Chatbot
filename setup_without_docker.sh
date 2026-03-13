#!/bin/bash
set -e

echo "=========================================="
echo "RAG Chatbot v2.0 - Setup (No Docker)"
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

echo -e "${YELLOW}This setup skips PostgreSQL and uses in-memory authentication${NC}"
echo -e "${YELLOW}For production use, please use Docker setup with PostgreSQL${NC}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Check prerequisites
log "Checking prerequisites..."

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
log "Step 1/5: Setting up backend..."
cd backend

if [ ! -d "venv" ]; then
    log "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
log "Installing Python dependencies..."
pip install -q --upgrade pip

# Install without Prisma
pip install -q fastapi uvicorn langchain langchain-community chromadb pdfplumber python-dotenv python-multipart python-jose[cryptography] passlib bcrypt

log_success "Backend dependencies installed"

if [ ! -f .env ]; then
    cat > .env << 'EOF'
SECRET_KEY=dev-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF
    log_success "Created .env file"
fi

cd ..

echo ""
log "Step 2/5: Setting up frontend..."
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
log "Step 3/5: Checking Ollama..."
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
log "Step 4/5: Creating sample documents..."
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
log "Step 5/5: Ingesting documents..."
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
echo -e "${YELLOW}Note: Using in-memory authentication (no database)${NC}"
echo -e "${YELLOW}Users will be reset on server restart${NC}"
echo ""
