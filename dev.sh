#!/bin/bash
set -e

echo "=========================================="
echo "RAG Chatbot v2.0 - Complete Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    lsof -ti:$1 > /dev/null 2>&1
}

# Function to kill process on port
kill_port() {
    if check_port $1; then
        echo -e "${YELLOW}Killing process on port $1...${NC}"
        lsof -ti:$1 | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down services...${NC}"
    kill_port 11434  # Ollama
    kill_port 8000   # Backend
    kill_port 5173   # Frontend
    exit 0
}

# Trap Ctrl+C
trap cleanup INT TERM

# Step 1: Check if Ollama is installed
echo "Step 1: Checking Ollama..."
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Error: Ollama is not installed${NC}"
    echo "Install from: https://ollama.ai"
    exit 1
fi
echo -e "${GREEN}✓ Ollama found${NC}"
echo ""

# Step 2: Start Ollama
echo "Step 2: Starting Ollama..."
kill_port 11434
ollama serve > /dev/null 2>&1 &
OLLAMA_PID=$!
sleep 3

# Check if Ollama started
if ! check_port 11434; then
    echo -e "${RED}Error: Failed to start Ollama${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Ollama running on port 11434${NC}"

# Check for phi model
if ! ollama list | grep -q "phi"; then
    echo -e "${YELLOW}Pulling phi model...${NC}"
    ollama pull phi
fi
echo -e "${GREEN}✓ Phi model ready${NC}"
echo ""

# Step 3: Setup Python environment
echo "Step 3: Setting up Python environment..."
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -q --upgrade pip
pip3 install -q -r requirements.txt
echo -e "${GREEN}✓ Python dependencies installed${NC}"
echo ""

# Step 4: Create .env if needed
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
    echo -e "${YELLOW}⚠ Please edit .env and add your configuration${NC}"
fi

# Create docs directory
mkdir -p docs

# Create sample document if docs is empty
if [ ! "$(ls -A docs)" ]; then
    echo "Creating sample document..."
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

# Step 5: Ingest documents
echo "Step 4: Ingesting documents..."
python3 ingest_fast.py
echo ""

# Step 6: Start Backend
echo "Step 5: Starting Backend API..."
kill_port 8000
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 > /dev/null 2>&1 &
BACKEND_PID=$!
sleep 3

# Check if backend started
if ! check_port 8000; then
    echo -e "${RED}Error: Failed to start backend${NC}"
    cleanup
    exit 1
fi
echo -e "${GREEN}✓ Backend running on port 8000${NC}"
echo ""

# Step 7: Setup Frontend
echo "Step 6: Setting up Frontend..."
cd frontend

# Install frontend dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

# Step 8: Start Frontend
echo "Step 7: Starting Frontend..."
kill_port 5173
npm run dev > /dev/null 2>&1 &
FRONTEND_PID=$!
cd ..
sleep 5

# Check if frontend started
if ! check_port 5173; then
    echo -e "${RED}Error: Failed to start frontend${NC}"
    cleanup
    exit 1
fi
echo -e "${GREEN}✓ Frontend running on port 5173${NC}"
echo ""

# Success message
echo "=========================================="
echo -e "${GREEN}✓ All services started successfully!${NC}"
echo "=========================================="
echo ""
echo "Access your application:"
echo ""
echo "  Frontend:  http://localhost:5173"
echo "  Backend:   http://localhost:8000"
echo "  API Docs:  http://localhost:8000/docs"
echo ""
echo "Login credentials:"
echo "  demo@ragbot.ai / password"
echo "  admin@ragbot.ai / admin123"
echo ""
echo "Services running:"
echo "  - Ollama (port 11434)"
echo "  - Backend API (port 8000)"
echo "  - Frontend UI (port 5173)"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Keep script running
wait
