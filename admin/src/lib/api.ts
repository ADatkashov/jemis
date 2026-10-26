export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string, public details?: Record<string, unknown>) {
    super(message)
  }
}

const KEY = 'jemis.admin.session'
interface Session { accessToken: string; refreshToken: string }

export function loadSession(): Session | null {
  try { return JSON.parse(sessionStorage.getItem(KEY) ?? 'null') } catch { return null }
}
function saveSession(s: Session | null) {
  try { if (s) sessionStorage.setItem(KEY, JSON.stringify(s)); else sessionStorage.removeItem(KEY) } catch { /* storage unavailable */ }
}

let refreshing: Promise<boolean> | null = null
async function refresh(): Promise<boolean> {
  const s = loadSession()
  if (!s) return false
  refreshing ??= fetch('/api/v1/auth/refresh', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ refreshToken: s.refreshToken }),
  }).then(async r => {
    if (!r.ok) { saveSession(null); return false }
    saveSession(await r.json()); return true
  }).finally(() => { refreshing = null })
  return refreshing
}

export async function api<T = unknown>(path: string, init: { method?: string; body?: unknown } = {}, retry = true): Promise<T> {
  const s = loadSession()
  const res = await fetch('/api/v1' + path, {
    method: init.method ?? 'GET',
    headers: { 'Content-Type': 'application/json', ...(s ? { Authorization: `Bearer ${s.accessToken}` } : {}) },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  })
  if (res.status === 401 && retry && s && (await refresh())) return api<T>(path, init, false)
  if (res.status === 204) return undefined as T
  const text = await res.text()
  const data = text ? JSON.parse(text) : null
  if (!res.ok) throw new ApiError(res.status, data?.code ?? 'ERROR', data?.message ?? res.statusText, data?.details)
  return data as T
}

export async function login(identifier: string, password: string): Promise<void> {
  const res = await fetch('/api/v1/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ identifier, password }),
  })
  if (!res.ok) throw new ApiError(res.status, 'INVALID_CREDENTIALS', 'Invalid credentials')
  saveSession(await res.json())
}

export function logout() {
  const s = loadSession()
  if (s) void fetch('/api/v1/auth/logout', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ refreshToken: s.refreshToken }) })
  saveSession(null)
}

export interface Page<T> { items: T[]; page: number; size: number; totalElements: number; totalPages: number }
