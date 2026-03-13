# Documents Directory

This directory stores all documents that will be ingested into the RAG system.

## Supported Formats

- PDF files (`.pdf`)
- Text files (`.txt`)

## Usage

1. Add your documents to this directory
2. Run the ingestion process:
   ```bash
   cd backend
   python3 ingest_fast.py
   ```
   Or use the "Re-index Documents" button in the UI

## Notes

- Large PDFs may take a few minutes to process
- Documents are chunked and embedded using Ollama
- Embeddings are stored in `backend/chroma_db/`
- Re-indexing will clear and rebuild the entire vector database

## Sample Document

A sample document (`sample.txt`) is automatically created if this directory is empty.
