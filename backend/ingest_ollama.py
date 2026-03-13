"""Alternative ingestion using Ollama (local, free)"""
import os
from pathlib import Path
from langchain_community.document_loaders import PyPDFLoader, TextLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma

DOCS_DIR = "./docs"
CHROMA_DIR = "./chroma_db"

def ingest_documents():
    """Load documents from docs/ folder and ingest into ChromaDB using Ollama"""
    docs_path = Path(DOCS_DIR)
    
    if not docs_path.exists():
        docs_path.mkdir(parents=True, exist_ok=True)
        return {"status": "warning", "message": "No documents found in ./docs. Add .pdf or .txt files first."}
    
    documents = []
    
    # Load PDF files
    for pdf_file in docs_path.glob("*.pdf"):
        loader = PyPDFLoader(str(pdf_file))
        documents.extend(loader.load())
    
    # Load TXT files
    for txt_file in docs_path.glob("*.txt"):
        loader = TextLoader(str(txt_file))
        documents.extend(loader.load())
    
    if not documents:
        return {"status": "warning", "message": "No documents found in ./docs. Add .pdf or .txt files first."}
    
    # Split documents into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        length_function=len,
    )
    chunks = text_splitter.split_documents(documents)
    
    # Create embeddings using Ollama (local, free) - phi is faster
    embeddings = OllamaEmbeddings(model="phi")
    
    # Remove existing ChromaDB if it exists
    if Path(CHROMA_DIR).exists():
        import shutil
        shutil.rmtree(CHROMA_DIR)
    
    # Create new vector store
    Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory=CHROMA_DIR
    )
    
    return {
        "status": "success",
        "message": "Documents successfully ingested into ChromaDB using Ollama.",
        "doc_count": len(documents),
        "chunk_count": len(chunks)
    }

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()
    result = ingest_documents()
    print(result)
