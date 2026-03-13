from fastapi import FastAPI, Depends, HTTPException, UploadFile, File
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
import os

from auth.routes import router as auth_router
from auth.auth import get_current_user
from ingest_fast import ingest_documents
from retriever_ollama import ask_question

load_dotenv()

app = FastAPI(title="RAG Chatbot API", version="2.0.0")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include auth routes
app.include_router(auth_router)

# Models
class ChatRequest(BaseModel):
    question: str
    session_id: str = "default"

class ChatResponse(BaseModel):
    answer: str
    session_id: str
    user: str

# Health check
@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.0.0"}

# Chat endpoint
@app.post("/chat", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    current_user: dict = Depends(get_current_user)
):
    result = ask_question(request.question)
    
    return ChatResponse(
        answer=result["answer"],
        session_id=request.session_id,
        user=current_user["email"]
    )

# Ingest endpoint
@app.post("/ingest")
async def ingest(current_user: dict = Depends(get_current_user)):
    result = ingest_documents()
    return result

# Upload document endpoint
@app.post("/upload")
async def upload_document(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    from pathlib import Path
    
    # Check file type
    if not file.filename.endswith(('.pdf', '.txt')):
        raise HTTPException(status_code=400, detail="Only PDF and TXT files are supported")
    
    # Save file to docs folder
    docs_path = Path("../docs")
    docs_path.mkdir(exist_ok=True)
    
    file_path = docs_path / file.filename
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    return {
        "message": f"File '{file.filename}' uploaded successfully",
        "filename": file.filename,
        "size": len(content)
    }

# Serve static files
# Uncomment when React build is ready
# app.mount("/", StaticFiles(directory="frontend/dist", html=True), name="frontend")

@app.get("/")
async def read_root():
    return {
        "message": "RAG Chatbot API v2.0",
        "frontend": "http://localhost:5173",
        "docs": "http://localhost:8000/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
