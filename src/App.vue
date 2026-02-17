<script setup>
import { ref } from 'vue'

// Proxied through Vite to avoid CORS - maps to http://localhost:8000/generes
const API_URL = '/api/generes'

const responseData = ref(null)
const loading = ref(false)
const error = ref(null)

async function fetchFromBackend() {
  loading.value = true
  error.value = null
  responseData.value = null

  try {
    const res = await fetch(API_URL)
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`)
    const data = await res.json()
    responseData.value = data
  } catch (err) {
    error.value = err.message || 'Failed to fetch data'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="app">
    <header class="header">
      <h1>Recordtec</h1>
      <p class="subtitle">Cloud networking test</p>
    </header>

    <main class="main">
      <button
        class="fetch-btn"
        :disabled="loading"
        @click="fetchFromBackend"
      >
        {{ loading ? 'Loading...' : 'Call Backend' }}
      </button>

      <div v-if="error" class="response-box error">
        <strong>Error:</strong> {{ error }}
      </div>

      <div v-else-if="responseData" class="response-box">
        <h3>Response</h3>
        <pre class="json-display">{{ JSON.stringify(responseData, null, 2) }}</pre>
      </div>
    </main>
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  padding: 2rem;
  font-family: system-ui, -apple-system, sans-serif;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  color: #e8e8e8;
}

.header {
  text-align: center;
  margin-bottom: 3rem;
}

.header h1 {
  font-size: 2rem;
  font-weight: 600;
  margin: 0;
  letter-spacing: 0.05em;
}

.subtitle {
  color: #94a3b8;
  margin-top: 0.25rem;
}

.main {
  max-width: 36rem;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
}

.fetch-btn {
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 500;
  color: #0f172a;
  background: #38bdf8;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: background 0.2s, transform 0.1s;
}

.fetch-btn:hover:not(:disabled) {
  background: #7dd3fc;
  transform: translateY(-1px);
}

.fetch-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.response-box {
  width: 100%;
  padding: 1.25rem;
  background: #0f172a;
  border-radius: 0.5rem;
  border: 1px solid #334155;
}

.response-box h3 {
  margin: 0 0 0.75rem 0;
  font-size: 0.9rem;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.json-display {
  margin: 0;
  font-size: 0.9rem;
  line-height: 1.5;
  overflow-x: auto;
  color: #cbd5e1;
}

.response-box.error {
  border-color: #f87171;
  background: rgba(248, 113, 113, 0.1);
}

.response-box.error strong {
  color: #f87171;
}
</style>
