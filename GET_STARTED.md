# Get Started in 2 Minutes

## Step 1: Run Setup

```bash
./setup.sh
```

You'll be asked:

**1. AI Model:**
- Option 1: Ollama (local, free) ← Recommended
- Option 2: OpenAI (need API key)

**2. Database:**
- Option 1: Docker PostgreSQL ← Recommended
- Option 2: Custom database URL
- Option 3: In-memory (no persistence)

## Step 2: Start App

```bash
./dev.sh
```

This automatically starts:
- ✓ Ollama (if selected)
- ✓ PostgreSQL (if selected)
- ✓ Backend API
- ✓ Frontend UI

## Step 3: Open Browser

Go to: http://localhost:5173

Login:
- Email: `demo@ragbot.ai`
- Password: `password`

## That's It!

You now have a working RAG chatbot.

### Next Steps

1. **Upload documents**: Click "Upload Document" button
2. **Re-index**: Click "Re-index Documents" after upload
3. **Ask questions**: Type in the chat interface

### Need Help?

- Full docs: `README.md`
- Quick commands: `QUICK_REFERENCE.md`
- Project structure: `STRUCTURE.md`

### Stop Services

Press `Ctrl+C` in the terminal running `dev.sh`
