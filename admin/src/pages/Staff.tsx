import { useState } from 'react'
import { api } from '../lib/api'
import { errMsg, useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { ErrorBox, Field, Loading } from '../ui'

interface Row { id: string; fullName: string; email: string; role: string; status: string }

export default function Staff() {
  const t = useT()
  const { data, error, loading, reload } = useLoad(() => api<Row[]>('/admin/staff'), [])
  const [f, setF] = useState({ email: '', fullName: '', password: '', role: 'MANAGER', phone: '' })
  const [err, setErr] = useState('')
  const create = async (e: React.FormEvent) => {
    e.preventDefault()
    try { await api('/admin/staff', { method: 'POST', body: { ...f, phone: f.phone || null } }); setF({ ...f, email: '', fullName: '', password: '', phone: '' }); setErr(''); reload() }
    catch (e2) { setErr(errMsg(e2)) }
  }
  const toggle = async (r: Row) => {
    try { await api(`/admin/staff/${r.id}/active`, { method: 'PUT', body: { active: r.status !== 'ACTIVE' } }); reload() } catch (e2) { setErr(errMsg(e2)) }
  }
  return (
    <>
      <h1>{t('staff')}</h1>
      <form className="card" onSubmit={create}>
        <div className="row">
          <Field label="Email"><input type="email" value={f.email} onChange={e => setF({ ...f, email: e.target.value })} required /></Field>
          <Field label="Full name"><input value={f.fullName} onChange={e => setF({ ...f, fullName: e.target.value })} required /></Field>
          <Field label="Phone"><input value={f.phone} onChange={e => setF({ ...f, phone: e.target.value })} /></Field>
          <Field label="Role"><select value={f.role} onChange={e => setF({ ...f, role: e.target.value })}><option>MANAGER</option><option>ADMIN</option><option>COURIER</option></select></Field>
          <Field label="Password (min 10)"><input type="password" minLength={10} value={f.password} onChange={e => setF({ ...f, password: e.target.value })} required autoComplete="new-password" /></Field>
          <button type="submit">Create</button>
        </div>
        {err && <p className="error" role="alert">{err}</p>}
      </form>
      {loading && <Loading />}
      {error && <ErrorBox message={error} onRetry={reload} />}
      {data && <div className="card"><table><tbody>{data.map(r => (
        <tr key={r.id}><td>{r.fullName}</td><td>{r.email}</td><td>{r.role}</td><td>{r.status}</td>
          <td><button className="secondary" onClick={() => toggle(r)}>{r.status === 'ACTIVE' ? 'Disable' : 'Enable'}</button></td></tr>))}</tbody></table></div>}
    </>
  )
}
