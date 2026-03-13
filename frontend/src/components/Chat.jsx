import { useState, useRef, useEffect } from 'react'

const API_BASE = 'http://localhost:8000'

export default function Chat({ user, token, onLogout }) {
  const [messages, setMessages] = useState([
    { role: 'assistant', content: "Hello! I'm your document intelligence assistant. Upload documents and ask me anything about them." }
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [ingesting, setIngesting] = useState(false)
  const messagesEndRef = useRef(null)
  const fileInputRef = useRef(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const handleSend = async () => {
    if (!input.trim() || loading) return

    const userMessage = input.trim()
    setInput('')
    setMessages(prev => [...prev, { role: 'user', content: userMessage }])
    setLoading(true)

    try {
      const res = await fetch(`${API_BASE}/chat`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          question: userMessage,
          session_id: 'session-' + Date.now()
        })
      })

      if (res.ok) {
        const data = await res.json()
        setMessages(prev => [...prev, { role: 'assistant', content: data.answer }])
      } else {
        setMessages(prev => [...prev, { role: 'assistant', content: 'Unable to process your request. Please try again.' }])
      }
    } catch (error) {
      setMessages(prev => [...prev, { role: 'assistant', content: 'Connection error. Please check if the server is running.' }])
    } finally {
      setLoading(false)
    }
  }

  const handleUpload = async (e) => {
    const file = e.target.files[0]
    if (!file) return

    setUploading(true)
    const formData = new FormData()
    formData.append('file', file)

    try {
      const res = await fetch(`${API_BASE}/upload`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
        body: formData
      })

      if (res.ok) {
        const data = await res.json()
        setMessages(prev => [...prev, {
          role: 'system',
          content: `Document uploaded successfully: ${data.filename}\n\nClick "Re-index Documents" to process it.`
        }])
      } else {
        setMessages(prev => [...prev, {
          role: 'system',
          content: 'Upload failed. Only PDF and TXT files are supported.'
        }])
      }
    } catch (error) {
      setMessages(prev => [...prev, {
        role: 'system',
        content: 'Upload error. Please try again.'
      }])
    } finally {
      setUploading(false)
      e.target.value = ''
    }
  }

  const handleIngest = async () => {
    if (!confirm('Re-index all documents? This may take several minutes for large files.')) return

    setIngesting(true)
    setMessages(prev => [...prev, {
      role: 'system',
      content: 'Indexing documents... This may take a few minutes for large PDFs.'
    }])

    try {
      const res = await fetch(`${API_BASE}/ingest`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      })

      if (res.ok) {
        const data = await res.json()
        setMessages(prev => [...prev, {
          role: 'system',
          content: `Indexing complete!\n\nProcessed: ${data.doc_count} documents\nChunks created: ${data.chunk_count}\n\nYou can now ask questions about your documents.`
        }])
      } else {
        setMessages(prev => [...prev, {
          role: 'system',
          content: 'Indexing failed. Please try again.'
        }])
      }
    } catch (error) {
      setMessages(prev => [...prev, {
        role: 'system',
        content: 'Connection error during indexing.'
      }])
    } finally {
      setIngesting(false)
    }
  }

  const handleLogout = async () => {
    try {
      await fetch(`${API_BASE}/auth/logout`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      })
    } catch (error) {
      console.error('Logout error:', error)
    }
    onLogout()
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className="w-72 bg-white border-r border-gray-200 flex flex-col shadow-sm">
        {/* Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary-900 rounded-xl flex items-center justify-center shadow-md">
              <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
              </svg>
            </div>
            <div>
              <h1 className="text-lg font-bold text-gray-900">RAG Chatbot</h1>
              <p className="text-xs text-gray-500">Document Assistant</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="flex-1 p-4 space-y-3">
          <div className="mb-4">
            <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
              Document Actions
            </h2>
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept=".pdf,.txt"
            onChange={handleUpload}
            className="hidden"
          />
          
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="sidebar-button bg-primary-900 hover:bg-primary-800 text-white shadow-sm hover:shadow"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
            <span>{uploading ? 'Uploading...' : 'Upload Document'}</span>
          </button>

          <button
            onClick={handleIngest}
            disabled={ingesting}
            className="sidebar-button bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 shadow-sm hover:shadow"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            <span>{ingesting ? 'Indexing...' : 'Re-index Documents'}</span>
          </button>

          {/* Info Box */}
          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-xl">
            <div className="flex items-start gap-2">
              <svg className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
              </svg>
              <div>
                <p className="text-xs font-semibold text-blue-900 mb-1">Quick Start</p>
                <p className="text-xs text-blue-700 leading-relaxed">
                  Upload PDF or TXT files, re-index them, then ask questions about the content.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* User Profile */}
        <div className="p-4 border-t border-gray-200 bg-gray-50">
          <div className="mb-3 pb-3 border-b border-gray-200">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                <span className="text-sm font-semibold text-primary-900">
                  {(user.name || user.email).charAt(0).toUpperCase()}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 truncate">{user.name || 'User'}</p>
                <p className="text-xs text-gray-500 truncate">{user.email}</p>
              </div>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 rounded-lg transition-all duration-200 text-sm font-medium shadow-sm"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            Sign Out
          </button>
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col">
        {/* Chat Header */}
        <div className="bg-white border-b border-gray-200 px-6 py-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Conversation</h2>
              <p className="text-sm text-gray-500">Ask questions about your documents</p>
            </div>
            <div className="flex items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-medium">
                <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                Connected
              </span>
            </div>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4 scrollbar-hide">
          {messages.map((msg, idx) => (
            <div
              key={idx}
              className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div className={msg.role === 'user' ? 'message-user' : msg.role === 'system' ? 'message-system' : 'message-assistant'}>
                <div className="whitespace-pre-wrap leading-relaxed text-sm">
                  {msg.content}
                </div>
              </div>
            </div>
          ))}
          
          {loading && (
            <div className="flex justify-start">
              <div className="message-assistant">
                <div className="flex items-center gap-2">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }}></div>
                  </div>
                  <span className="text-sm text-gray-500">Thinking...</span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <div className="bg-white border-t border-gray-200 p-4 shadow-lg">
          <div className="max-w-4xl mx-auto">
            <div className="flex gap-3">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
                placeholder="Type your question here..."
                className="input-field flex-1"
                disabled={loading}
              />
              <button
                onClick={handleSend}
                disabled={loading || !input.trim()}
                className="btn-primary px-6"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
              </button>
            </div>
            <p className="text-xs text-gray-500 mt-2 text-center">
              Press Enter to send • Shift + Enter for new line
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
