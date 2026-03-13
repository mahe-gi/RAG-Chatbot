#!/bin/bash

echo "🚀 Starting RAG Chatbot v2.0 with Modern UI"
echo "==========================================="
echo ""

# Start backend
echo "📡 Starting backend server..."
source venv/bin/activate
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Wait for backend
sleep 3

# Start frontend
echo "🎨 Starting frontend dev server..."
cd frontend
npm run dev &
FRONTEND_PID=$!

echo ""
echo "✅ Application started!"
echo ""
echo "🌐 Frontend: http://localhost:5173"
echo "📡 Backend:  http://localhost:8000"
echo "📖 API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Wait for Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait
