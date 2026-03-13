"""Alternative retriever using Ollama (local, free)"""
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from langchain_community.vectorstores import Chroma
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate
from pathlib import Path

CHROMA_DIR = "./chroma_db"

def get_rag_chain():
    """Initialize and return the RAG chain using Ollama"""
    if not Path(CHROMA_DIR).exists():
        return None
    
    # Use Ollama embeddings (free, local)
    embeddings = OllamaEmbeddings(model="phi")
    
    vectorstore = Chroma(
        persist_directory=CHROMA_DIR,
        embedding_function=embeddings
    )
    
    retriever = vectorstore.as_retriever(search_kwargs={"k": 4})
    
    # Use Ollama LLM (free, local) - phi is much faster than llama2
    llm = Ollama(model="phi", temperature=0)
    
    prompt_template = """Use the following pieces of context to answer the question at the end. 
If you don't know the answer based on the context, just say that you don't have enough information to answer.

Context:
{context}

Question: {question}

Answer:"""
    
    PROMPT = PromptTemplate(
        template=prompt_template, input_variables=["context", "question"]
    )
    
    chain = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=retriever,
        return_source_documents=True,
        chain_type_kwargs={"prompt": PROMPT}
    )
    
    return chain

def ask_question(question: str):
    """Ask a question using the RAG chain"""
    chain = get_rag_chain()
    
    if chain is None:
        return {
            "answer": "No documents have been ingested yet. Please ingest documents first.",
            "sources": []
        }
    
    result = chain({"query": question})
    
    sources = []
    for doc in result.get("source_documents", []):
        sources.append({
            "content": doc.page_content[:200],
            "source": doc.metadata.get("source", "unknown"),
            "page": doc.metadata.get("page", 0)
        })
    
    return {
        "answer": result["result"],
        "sources": sources
    }
