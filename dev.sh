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

# Check if a port is in use
check_port() {
    lsof -ti:$1 > /dev/null 2>&1
}

# Kill process on port
kill_port() {
    if check_port $1; then
        lsof -ti:$1 | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down services...${NC}"
    
    # Kill services
    pkill -9 ollama 2>/dev/null || true
    kill_port 8000
    kill_port 5173
    docker-compose stop postgres > /dev/null 2>&1 || true
    
    echo -e "${GREEN}✓ All services stopped${NC}"
    exit 0
}

trap cleanup INT TERM

clear
echo -e "${BOLD}=========================================="
echo "RAG Chatbot v2.0 - Development Server"
echo -e "==========================================${NC}"
echo ""

# Read configuration
if [ ! -f "backend/.env" ]; then
    echo -e "${RED}Error: Configuration not found${NC}"
    echo ""
    echo "Please run setup first:"
    echo -e "  ${YELLOW}./setup.sh${NC}"
    echo ""
    exit 1
fi

# Load config
source backend/.env

# Detect configuration
USE_OLLAMA=true
USE_DATABASE=true

if [ ! -z "$OPENAI_API_KEY" ]; then
    USE_OLLAMA=false
fi

if [ -z "$DATABASE_URL" ]; then
    USE_DATABASE=false
fi

# Show configuration
echo -e "${CYAN}Configuration:${NC}"
if [ "$USE_OLLAMA" = true ]; then
    echo "  AI: Ollama (Local)"
else
    echo "  AI: OpenAI (API)"
fi

if [ "$USE_DATABASE" = true ]; then
    echo "  DB: PostgreSQL"
else
    echo "  DB: In-memory"
fi
echo ""

# ============================================
# Start Ollama
# ============================================
if [ "$USE_OLLAMA" = true ]; then
    echo -e "${BLUE}[1/4] Starting Ollama...${NC}"
    
    if ! check_port 11434; then
        ollama serve > ollama.log 2>&1 &
        sleep 3
        
        if check_port 11434; then
            echo -e "${GREEN}  ✓ Ollama running on port 11434${NC}"
        else
            echo -e "${RED}  ✗ Failed to start Ollama${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}  ✓ Ollama already running${NC}"
    fi
    
    # Check phi model
    if ! ollama list | grep -q "phi"; then
        echo "  Pulling phi model..."
        ollama pull phi
    fi
else
    echo -e "${BLUE}[1/4] Using OpenAI API${NC}"
    echo -e "${GREEN}  ✓ OpenAI configured${NC}"
fi
echo ""

# ============================================
# Start PostgreSQL
# ============================================
if [ "$USE_DATABASE" = true ]; then
    echo -e "${BLUE}[2/4] Starting PostgreSQL...${NC}"
    
    if [[ "$DATABASE_URL" == *"localhost:5432"* ]]; then
        # Using Docker PostgreSQL
        if ! check_port 5432; then
            if docker info > /dev/null 2>&1; then
                docker-compose up -d postgres > /dev/null 2>&1
                sleep 5
                
                if check_port 5432; then
                    echo -e "${GREEN}  ✓ PostgreSQL running on port 5432${NC}"
                else
                    echo -e "${RED}  ✗ Failed to start PostgreSQL${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}  ✗ Docker not running${NC}"
                echo "  Please start Docker Desktop"
                exit 1
            fi
        else
            echo -e "${GREEN}  ✓ PostgreSQL already running${NC}"
        fi
    else
        # Using custom database
        echo -e "${GREEN}  ✓ Using custom database${NC}"
    fi
else
    echo -e "${BLUE}[2/4] Skipping Database${NC}"
    echo -e "${YELLOW}  ⚠ Using in-memory authentication${NC}"
fi
echo ""

# ============================================
# Start Backend
# ============================================
echo -e "${BLUE}[3/4] Starting Backend...${NC}"

cd backend
source venv/bin/activate

# Generate Prisma client if needed
if [ -f "prisma/schema.prisma" ] && [ "$USE_DATABASE" = true ]; then
    echo "  Generating Prisma client..."
    PATH="$PWD/venv/bin:$PATH" venv/bin/python3 -m prisma generate > /dev/null 2>&1 || true
fi

# Ingest documents
echo "  Ingesting documents..."
venv/bin/python3 ingest_fast.py > /dev/null 2>&1 || true

# Start backend
kill_port 8000
venv/bin/python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
BACKEND_PID=$!

cd ..

# Wait for backend
for i in {1..15}; do
    if check_port 8000; then
        echo -e "${GREEN}  ✓ Backend running on port 8000 (PID: $BACKEND_PID)${NC}"
        break
    fi
    sleep 1
done

if ! check_port 8000; then
    echo -e "${RED}  ✗ Failed to start backend${NC}"
    echo "  Check: tail -f backend.log"
    exit 1
fi
echo ""

# ============================================
# Start Frontend
# ============================================
echo -e "${BLUE}[4/4] Starting Frontend...${NC}"

cd frontend
kill_port 5173
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# Wait for frontend
for i in {1..20}; do
    if check_port 5173; then
        echo -e "${GREEN}  ✓ Frontend running on port 5173 (PID: $FRONTEND_PID)${NC}"
        break
    fi
    sleep 1
done

if ! check_port 5173; then
    echo -e "${RED}  ✗ Failed to start frontend${NC}"
    echo "  Check: tail -f frontend.log"
    exit 1
fi
echo ""

# ============================================
# Success Message
# ============================================
echo ""
echo -e "${GREEN}${BOLD}=========================================="
echo "🚀 All Services Running!"
echo -e "==========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}📱 Access Your Application:${NC}"
echo ""
echo -e "  ${GREEN}➜ Frontend:${NC}  http://localhost:5173"
echo -e "  ${GREEN}➜ Backend:${NC}   http://localhost:8000"
echo -e "  ${GREEN}➜ API Docs:${NC}  http://localhost:8000/docs"
echo ""
echo -e "${CYAN}${BOLD}🔐 Demo Login:${NC}"
echo ""
echo "  Email:    demo@ragbot.ai"
echo "  Password: password"
echo ""
echo -e "${CYAN}${BOLD}⚙️  Services:${NC}"
echo ""
if [ "$USE_OLLAMA" = true ]; then
    echo -e "  ${BLUE}✓${NC} Ollama       → localhost:11434"
fi
if [ "$USE_DATABASE" = true ]; then
    echo -e "  ${BLUE}✓${NC} PostgreSQL   → localhost:5432"
fi
echo -e "  ${BLUE}✓${NC} Backend      → localhost:8000"
echo -e "  ${BLUE}✓${NC} Frontend     → localhost:5173"
echo ""
echo -e "${CYAN}${BOLD}📋 Logs:${NC}"
echo ""
echo "  Backend:   tail -f backend.log"
echo "  Frontend:  tail -f frontend.log"
if [ "$USE_OLLAMA" = true ]; then
    echo "  Ollama:    tail -f ollama.log"
fi
if [ "$USE_DATABASE" = true ] && [[ "$DATABASE_URL" == *"localhost:5432"* ]]; then
    echo "  Database:  docker logs -f ragbot_postgres"
fi
echo ""
echo -e "${RED}⏹  Stop: Press Ctrl+C${NC}"
echo ""
echo "=========================================="
echo ""

# Show live backend logs
tail -f backend.log
