#!/bin/bash
set -e

echo "=========================================="
echo "RAG Chatbot v2.0 - Development Server"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log with timestamp
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

log_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ${NC} $1"
}

# Function to check if a port is in use
check_port() {
    lsof -ti:$1 > /dev/null 2>&1
}

# Function to kill process on port
kill_port() {
    if check_port $1; then
        log_warning "Killing existing process on port $1..."
        lsof -ti:$1 | xargs kill -9 2>/dev/null || true
        sleep 1
        log_success "Port $1 cleared"
    fi
}

# Cleanup function
cleanup() {
    echo ""
    log_warning "Shutting down services..."
    kill_port 8000   # Backend
    kill_port 5173   # Frontend
    log_success "All services stopped"
    exit 0
}

# Trap Ctrl+C
trap cleanup INT TERM

# Step 1: Check if Ollama is running
log "Step 1/7: Checking Ollama..."
if ! check_port 11434; then
    log_error "Ollama is not running on port 11434"
    echo ""
    echo "Please start Ollama in a separate terminal:"
    echo -e "${YELLOW}  cd local_model && ./start_ollama.sh${NC}"
    echo "or"
    echo -e "${YELLOW}  ollama serve${NC}"
    echo ""
    exit 1
fi
log_success "Ollama is running on port 11434"

# Check for phi model
log "Checking for phi model..."
if ! ollama list | grep -q "phi"; then
    log_error "phi model not found"
    log_info "Run: ollama pull phi"
    exit 1
fi
log_success "Phi model is available"
echo ""

# Step 1.5: Check if PostgreSQL is running
log "Step 1.5/7: Checking PostgreSQL..."
if ! check_port 5432; then
    log_warning "PostgreSQL is not running"
    log_info "Starting PostgreSQL with Docker..."
    docker-compose up -d postgres
    sleep 5
    
    if ! check_port 5432; then
        log_error "Failed to start PostgreSQL"
        log_info "Run: docker-compose up -d postgres"
        exit 1
    fi
fi
log_success "PostgreSQL is running on port 5432"
echo ""

# Step 2: Setup Python environment
log "Step 2/7: Setting up Python environment..."
cd backend

if [ ! -d "venv" ]; then
    log "Creating virtual environment..."
    python3 -m venv venv
    log_success "Virtual environment created"
fi

log "Activating virtual environment..."
source venv/bin/activate
log_success "Virtual environment activated"

log "Checking Python dependencies..."
pip3 install -q --upgrade pip
pip3 install -q -r requirements.txt
log_success "Python dependencies installed"
echo ""

# Step 3: Create .env if needed
log "Step 3/7: Checking configuration..."
if [ ! -f .env ]; then
    log "Creating .env file from template..."
    cp .env.example .env
    log_warning "Please edit backend/.env and add your configuration"
fi
log_success "Configuration file exists"

# Create docs directory
cd ..
if [ ! -d "docs" ]; then
    log "Creating docs directory..."
    mkdir -p docs
    log_success "docs/ directory created"
fi

# Create sample document if docs is empty
if [ ! "$(ls -A docs)" ]; then
    log "Creating sample document..."
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

# Step 4: Ingest documents
log "Step 4/7: Ingesting documents..."
log_info "This may take a few minutes for large PDFs..."
cd backend
python3 ingest_fast.py 2>&1 | while IFS= read -r line; do
    if [[ $line == *"✅"* ]]; then
        log_success "$line"
    elif [[ $line == *"❌"* ]]; then
        log_error "$line"
    elif [[ $line == *"📄"* ]] || [[ $line == *"📊"* ]] || [[ $line == *"✂️"* ]] || [[ $line == *"🔢"* ]] || [[ $line == *"💾"* ]]; then
        log_info "$line"
    elif [[ $line == *"Error"* ]] || [[ $line == *"error"* ]]; then
        log_error "$line"
    elif [[ $line == *"Warning"* ]] || [[ $line == *"warning"* ]]; then
        log_warning "$line"
    else
        echo "$line"
    fi
done
log_success "Document ingestion complete"
cd ..
echo ""

# Step 5: Start Backend
log "Step 5/7: Starting Backend API..."
kill_port 8000
log "Launching uvicorn server..."
cd backend
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..
log_info "Backend PID: $BACKEND_PID"

log "Waiting for backend to start..."
for i in {1..10}; do
    if check_port 8000; then
        log_success "Backend is running on port 8000"
        break
    fi
    sleep 1
    echo -n "."
done

if ! check_port 8000; then
    log_error "Failed to start backend"
    log_info "Check backend.log for details: tail -f backend.log"
    exit 1
fi
echo ""

# Step 6: Setup Frontend
log "Step 6/7: Starting Frontend..."
cd frontend

# Install frontend dependencies if needed
if [ ! -d "node_modules" ]; then
    log "Installing frontend dependencies..."
    npm install 2>&1 | while IFS= read -r line; do
        if [[ $line == *"added"* ]] || [[ $line == *"packages"* ]]; then
            log_info "$line"
        fi
    done
    log_success "Frontend dependencies installed"
fi

log "Launching Vite dev server..."
kill_port 5173
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
log_info "Frontend PID: $FRONTEND_PID"
cd ..

log "Waiting for frontend to start..."
for i in {1..15}; do
    if check_port 5173; then
        log_success "Frontend is running on port 5173"
        break
    fi
    sleep 1
    echo -n "."
done

if ! check_port 5173; then
    log_error "Failed to start frontend"
    log_info "Check frontend.log for details: tail -f frontend.log"
    exit 1
fi
echo ""

# Success message
echo "=========================================="
log_success "All services started successfully!"
echo "=========================================="
echo ""
echo -e "${CYAN}Access your application:${NC}"
echo ""
echo -e "  ${GREEN}Frontend:${NC}  http://localhost:5173"
echo -e "  ${GREEN}Backend:${NC}   http://localhost:8000"
echo -e "  ${GREEN}API Docs:${NC}  http://localhost:8000/docs"
echo ""
echo -e "${CYAN}Login credentials:${NC}"
echo "  demo@ragbot.ai / password"
echo "  admin@ragbot.ai / admin123"
echo ""
echo -e "${CYAN}Services running:${NC}"
echo "  - Backend API (port 8000) - PID: $BACKEND_PID"
echo "  - Frontend UI (port 5173) - PID: $FRONTEND_PID"
echo ""
echo -e "${CYAN}View logs:${NC}"
echo "  - Backend:  tail -f backend.log"
echo "  - Frontend: tail -f frontend.log"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Keep script running and show live logs
log_info "Showing live backend logs (Ctrl+C to stop)..."
echo ""
tail -f backend.log
