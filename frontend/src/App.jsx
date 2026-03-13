import { useState, useEffect } from 'react'
import Login from './components/Login'
import Chat from './components/Chat'

const API_BASE = 'http://localhost:8000'

function App() {
  const [token, setToken] = useState(localStorage.getItem('token'))
  const [user, setUser] = useState(null)

  useEffect(() => {
    if (token) {
      fetchUser()
    }
  }, [token])

  const fetchUser = async () => {
    try {
      const res = await fetch(`${API_BASE}/auth/me`, {
        headers: { 'Authorization': `Bearer ${token}` }
      })
      if (res.ok) {
        const data = await res.json()
        setUser(data)
      } else {
        handleLogout()
      }
    } catch (error) {
      console.error('Error fetching user:', error)
      handleLogout()
    }
  }

  const handleLogin = (newToken) => {
    localStorage.setItem('token', newToken)
    setToken(newToken)
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken(null)
    setUser(null)
  }

  if (!token || !user) {
    return <Login onLogin={handleLogin} />
  }

  return <Chat user={user} token={token} onLogout={handleLogout} />
}

export default App
