#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Testing RAG Chatbot System..."
echo ""

# Test 1: Backend imports
echo -n "1. Testing backend imports... "
cd backend
source venv/bin/activate
python -c "from main import app; from auth.routes import router; from ingest_fast import ingest_documents; from retriever_ollama import ask_question" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "   Run: cd backend && pip install -r requirements.txt"
    exit 1
fi
cd ..

# Test 2: Frontend dependencies
echo -n "2. Testing frontend dependencies... "
if [ -d "frontend/node_modules" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "   Run: cd frontend && npm install"
fi

# Test 3: Configuration
echo -n "3. Testing configuration... "
if [ -f "backend/.env" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "   Run: ./setup.sh"
    exit 1
fi

# Test 4: Ollama
echo -n "4. Testing Ollama... "
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "   Install from: https://ollama.ai"
fi

# Test 5: Docker
echo -n "5. Testing Docker... "
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "   Start Docker Desktop or use custom DATABASE_URL"
fi

echo ""
echo -e "${GREEN}System check complete!${NC}"
echo ""
echo "Start the application with: ./dev.sh"
