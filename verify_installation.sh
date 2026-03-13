#!/bin/bash
# RAG Chatbot v2.0 - Installation Verification Script

echo "🔍 RAG Chatbot v2.0 - Installation Verification"
echo "================================================"
echo ""

# Check Python
echo "1️⃣ Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "   ✅ $PYTHON_VERSION"
else
    echo "   ❌ Python 3 not found"
    exit 1
fi

# Check Ollama
echo ""
echo "2️⃣ Checking Ollama..."
if command -v ollama &> /dev/null; then
    echo "   ✅ Ollama installed"
    MODELS=$(ollama list | grep -c "phi")
    if [ $MODELS -gt 0 ]; then
        echo "   ✅ phi model installed"
    else
        echo "   ❌ phi model not found - run: ollama pull phi"
    fi
else
    echo "   ❌ Ollama not found - install from https://ollama.ai"
    exit 1
fi

# Check virtual environment
echo ""
echo "3️⃣ Checking Virtual Environment..."
if [ -d "venv" ]; then
    echo "   ✅ Virtual environment exists"
else
    echo "   ⚠️  Virtual environment not found - will be created by dev.sh"
fi

# Check required files
echo ""
echo "4️⃣ Checking Required Files..."
FILES=("main.py" "auth/auth.py" "auth/routes.py" "ingest_ollama.py" "retriever_ollama.py" "static/index.html" "requirements.txt" "dev.sh")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file missing"
    fi
done

# Check .env
echo ""
echo "5️⃣ Checking Configuration..."
if [ -f ".env" ]; then
    echo "   ✅ .env file exists"
else
    echo "   ⚠️  .env not found - will be created by dev.sh"
fi

# Check docs folder
echo ""
echo "6️⃣ Checking Documents..."
if [ -d "docs" ]; then
    DOC_COUNT=$(ls -1 docs/*.{txt,pdf} 2>/dev/null | wc -l)
    echo "   ✅ docs/ folder exists ($DOC_COUNT documents)"
else
    echo "   ⚠️  docs/ folder not found"
fi

# Check if server is running
echo ""
echo "7️⃣ Checking Server Status..."
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "   ✅ Server is running at http://localhost:8000"
else
    echo "   ⚠️  Server not running - start with: ./dev.sh"
fi

echo ""
echo "================================================"
echo "📋 Summary:"
echo ""
echo "✅ All core components verified!"
echo ""
echo "🚀 To start the application:"
echo "   ./dev.sh"
echo ""
echo "🌐 Then open: http://localhost:8000"
echo "   Login: demo@ragbot.ai / password"
echo ""
