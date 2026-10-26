import { useContext, useMemo, useState } from 'react'
import { NavLink, Navigate, Route, Routes } from 'react-router-dom'
import { loadSession, login, logout } from './lib/api'
import { LangContext, useT, type Lang } from './lib/i18n'
import { Field } from './ui'
import Dashboard from './pages/Dashboard'
import Orders from './pages/Orders'
import OrderDetail from './pages/OrderDetail'
import Products from './pages/Products'
import Categories from './pages/Categories'
import DeliveryPage from './pages/Delivery'
import Promotions from './pages/Promotions'
import Customers from './pages/Customers'
import Staff from './pages/Staff'
import SettingsPage from './pages/Settings'
import Audit from './pages/Audit'

/** The role is read from the token for display only; every endpoint enforces authorization on the server. */
function roleOf(): string | null {
  const s = loadSession()
  if (!s) return null
  try { return JSON.parse(atob(s.accessToken.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'))).role } catch { return null }
}

function Login({ onDone }: { onDone: () => void }) {
  const t = useT()
  const [id, setId] = useState('')
  const [pw, setPw] = useState('')
  const [err, setErr] = useState('')
  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    try { await login(id, pw); if (!['ADMIN', 'MANAGER'].includes(roleOf() ?? '')) { logout(); throw new Error('forbidden') } onDone() }
    catch { setErr('Invalid credentials or insufficient role') }
  }
  return (
    <form className="card login" onSubmit={submit}>
      <h1>JEMIS Admin</h1>
      <div className="row"><Field label="Email"><input value={id} onChange={e => setId(e.target.value)} autoComplete="username" required /></Field></div>
      <div className="row"><Field label="Password"><input type="password" value={pw} onChange={e => setPw(e.target.value)} autoComplete="current-password" required /></Field></div>
      {err && <p className="error" role="alert">{err}</p>}
      <button type="submit">{t('login')}</button>
    </form>
  )
}

export default function App() {
  const [lang, setLang] = useState<Lang>('ru')
  const [authed, setAuthed] = useState(() => loadSession() !== null)
  const ctx = useMemo(() => ({ lang, setLang }), [lang])
  const role = roleOf()
  return (
    <LangContext.Provider value={ctx}>
      {!authed ? <Login onDone={() => setAuthed(true)} /> : <Shell role={role} onLogout={() => { logout(); setAuthed(false) }} />}
    </LangContext.Provider>
  )
}

function Shell({ role, onLogout }: { role: string | null; onLogout: () => void }) {
  const t = useT()
  const links: [string, string][] = [['/', 'dashboard'], ['/orders', 'orders'], ['/products', 'products'], ['/categories', 'categories'],
    ['/delivery', 'delivery'], ['/promotions', 'promotions'], ['/customers', 'customers']]
  if (role === 'ADMIN') links.push(['/staff', 'staff'], ['/settings', 'settings'], ['/audit', 'audit'])
  return (
    <div className="layout">
      <nav className="side" aria-label="Main">
        <div className="brand">JEMIS</div>
        {links.map(([to, k]) => <NavLink key={to} to={to} end={to === '/'}>{t(k)}</NavLink>)}
        <LangSwitch />
        <button className="secondary" style={{ color: '#fff', borderColor: '#fff' }} onClick={onLogout}>{t('logout')}</button>
      </nav>
      <main className="main">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/orders/:id" element={<OrderDetail />} />
          <Route path="/products" element={<Products />} />
          <Route path="/categories" element={<Categories />} />
          <Route path="/delivery" element={<DeliveryPage />} />
          <Route path="/promotions" element={<Promotions />} />
          <Route path="/customers" element={<Customers />} />
          {role === 'ADMIN' && <Route path="/staff" element={<Staff />} />}
          {role === 'ADMIN' && <Route path="/settings" element={<SettingsPage />} />}
          {role === 'ADMIN' && <Route path="/audit" element={<Audit />} />}
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </main>
    </div>
  )
}

function LangSwitch() {
  const { lang, setLang } = useContext(LangContext)
  return (
    <select aria-label="Language" value={lang} onChange={e => setLang(e.target.value as Lang)}>
      <option value="ru">Русский</option><option value="kk">Қазақша</option><option value="en">English</option>
    </select>
  )
}
