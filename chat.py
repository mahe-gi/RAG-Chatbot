#!/usr/bin/env python3
"""CLI chat interface for RAG Chatbot"""
from dotenv import load_dotenv
from retriever_ollama import ask_question

load_dotenv()

def main():
    print("RAG Chatbot CLI")
    print("=" * 50)
    print("Type 'exit' or 'quit' to end the session\n")
    
    while True:
        question = input("You: ").strip()
        
        if question.lower() in ['exit', 'quit']:
            print("Goodbye!")
            break
        
        if not question:
            continue
        
        result = ask_question(question)
        print(f"\nBot: {result['answer']}\n")
        
        if result.get('sources'):
            print("Sources:")
            for i, source in enumerate(result['sources'][:2], 1):
                print(f"  [{i}] {source['source']} (page {source['page']})")
            print()

if __name__ == "__main__":
    main()
