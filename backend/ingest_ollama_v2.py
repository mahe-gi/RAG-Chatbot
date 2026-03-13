"""Improved ingestion with better PDF support"""
import os
from pathlib import Path
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.schema import Document
import pdfplumber

DOCS_DIR = "./docs"
CHROMA_DIR = "./chroma_db"

def load_pdf_with_pdfplumber(file_path):
    """Load PDF using pdfplumber (faster and more reliable)"""
    documents = []
    try:
        with pdfplumber.open(file_path) as pdf:
            for page_num, page in enumerate(pdf.pages):
                text = page.extract_text()
                if text and text.strip():
                    doc = Document(
                        page_content=text,
                        metadata={
                            "source": os.path.basename(file_path),
                            "page": page_num + 1
                        }
                    )
                    documents.append(doc)
        print(f"  ✅ Loaded {len(documents)} pages from {os.path.basename(file_path)}")
    except Exception as e:
        print(f"  ❌ Error loading {os.path.basename(file_path)}: {e}")
    return documents

def load_txt_file(file_path):
    """Load TXT file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            text = f.read()
        doc = Document(
            page_content=text,
            metadata={
                "source": os.path.basename(file_path),
                "page": 1
            }
        )
        print(f"  ✅ Loaded {os.path.basename(file_path)}")
        return [doc]
    except Exception as e:
        print(f"  ❌ Error loading {os.path.basename(file_path)}: {e}")
        return []

def ingest_documents():
    """Load documents from docs/ folder and ingest into ChromaDB using Ollama"""
    docs_path = Path(DOCS_DIR)
    
    if not docs_path.exists():
        docs_path.mkdir(parents=True, exist_ok=True)
        return {"status": "warning", "message": "No documents found in ./docs. Add .pdf or .txt files first."}
    
    documents = []
    
    print("📄 Loading documents...")
    
    # Load PDF files with pdfplumber
    pdf_files = list(docs_path.glob("*.pdf"))
    for pdf_file in pdf_files:
        docs = load_pdf_with_pdfplumber(str(pdf_file))
        documents.extend(docs)
    
    # Load TXT files
    txt_files = list(docs_path.glob("*.txt"))
    for txt_file in txt_files:
        docs = load_txt_file(str(txt_file))
        documents.extend(docs)
    
    if not documents:
        return {"status": "warning", "message": "No documents found in ./docs. Add .pdf or .txt files first."}
    
    print(f"\n📊 Total documents loaded: {len(documents)}")
    print("✂️  Splitting into chunks...")
    
    # Split documents into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=500,
        chunk_overlap=50,
        length_function=len,
    )
    chunks = text_splitter.split_documents(documents)
    
    print(f"✅ Created {len(chunks)} chunks")
    print("🔢 Creating embeddings with Ollama...")
    
    # Create embeddings using Ollama (local, free) - phi is faster
    embeddings = OllamaEmbeddings(model="phi")
    
    # Remove existing ChromaDB if it exists
    if Path(CHROMA_DIR).exists():
        import shutil
        shutil.rmtree(CHROMA_DIR)
        print("🗑️  Cleared old vector database")
    
    # Create new vector store
    print("💾 Storing in ChromaDB...")
    Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory=CHROMA_DIR
    )
    
    print("✅ Done!\n")
    
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
