# Local Model - Ollama

This directory contains scripts and configuration for running Ollama locally.

## Quick Start

```bash
./start_ollama.sh
```

This will start the Ollama server on port 11434.

## Models Used

- **phi**: Fast, lightweight model (1.6GB) - recommended for development
- **llama2**: More powerful but slower (3.8GB)

## Install Ollama

If you don't have Ollama installed:

```bash
# macOS
brew install ollama

# Or download from https://ollama.ai
```

## Pull Models

```bash
ollama pull phi
ollama pull llama2
```

## Check Running Models

```bash
ollama list
```

## Stop Ollama

Press `Ctrl+C` in the terminal where Ollama is running.
