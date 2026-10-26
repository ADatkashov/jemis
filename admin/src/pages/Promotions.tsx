import { useState } from 'react'
import { api } from '../lib/api'
import { formatMoney, parseMoney } from '../lib/format'
import { errMsg, useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { ErrorBox, Field, Loading } from '../ui'

interface Promo { id?: string; code: string; type: 'PERCENT' | 'FIXED'; value: number; maxDiscountMinor?: number | null; minOrderMinor: number
  startsAt?: string | null; endsAt?: string | null; usageLimit?: number | null; perCustomerLimit?: number | null; stackable: boolean; active: boolean; usedCount?: number }

export default function Promotions() {
  const t = useT()
  const { data, error, loading, reload } = useLoad(() => api<Promo[]>('/admin/promotions'), [])
  const [p, setP] = useState<(Promo & { v: string; min: string; max: string }) | null>(null)
  const [err, setErr] = useState('')
  const open = (x?: Promo) => setP({ code: '', type: 'PERCENT', value: 10, minOrderMinor: 0, stackable: false, active: true, ...x,
    v: x ? (x.type === 'PERCENT' ? String(x.value) : String(x.value / 100)) : '10', min: String((x?.minOrderMinor ?? 0) / 100), max: x?.maxDiscountMinor ? String(x.maxDiscountMinor / 100) : '' })
  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    const value = p!.type === 'PERCENT' ? Number(p!.v) : parseMoney(p!.v)
    const min = parseMoney(p!.min), max = p!.max.trim() ? parseMoney(p!.max) : null
    if (!value || min === null || (p!.max.trim() && max === null)) { setErr('Invalid number'); return }
    const body = { code: p!.code, type: p!.type, value, maxDiscountMinor: max, minOrderMinor: min, startsAt: p!.startsAt || null, endsAt: p!.endsAt || null,
      usageLimit: p!.usageLimit || null, perCustomerLimit: p!.perCustomerLimit || null, stackable: p!.stackable, active: p!.active }
    try { if (p!.id) await api(`/admin/promotions/${p!.id}`, { method: 'PUT', body }); else await api('/admin/promotions', { method: 'POST', body }); setP(null); setErr(''); reload() }
    catch (e2) { setErr(errMsg(e2)) }
  }
  return (
    <>
      <h1>{t('promotions')}</h1>
      <div className="row"><button onClick={() => open()}>+ New</button></div>
      {p && <form className="card" onSubmit={save}>
        <div className="row">
          <Field label="Code"><input value={p.code} onChange={e => setP({ ...p, code: e.target.value })} required /></Field>
          <Field label="Type"><select value={p.type} onChange={e => setP({ ...p, type: e.target.value as Promo['type'] })}><option value="PERCENT">Percent</option><option value="FIXED">Fixed ₸</option></select></Field>
          <Field label={p.type === 'PERCENT' ? 'Percent (1-100)' : 'Amount, ₸'}><input value={p.v} onChange={e => setP({ ...p, v: e.target.value })} /></Field>
          <Field label="Max discount, ₸"><input value={p.max} onChange={e => setP({ ...p, max: e.target.value })} /></Field>
          <Field label="Min order, ₸"><input value={p.min} onChange={e => setP({ ...p, min: e.target.value })} /></Field>
        </div>
        <div className="row">
          <Field label="Starts"><input type="datetime-local" onChange={e => setP({ ...p, startsAt: e.target.value ? new Date(e.target.value).toISOString() : null })} /></Field>
          <Field label="Ends"><input type="datetime-local" onChange={e => setP({ ...p, endsAt: e.target.value ? new Date(e.target.value).toISOString() : null })} /></Field>
          <Field label="Total uses"><input type="number" min={1} value={p.usageLimit ?? ''} onChange={e => setP({ ...p, usageLimit: e.target.value ? Number(e.target.value) : null })} /></Field>
          <Field label="Per customer"><input type="number" min={1} value={p.perCustomerLimit ?? ''} onChange={e => setP({ ...p, perCustomerLimit: e.target.value ? Number(e.target.value) : null })} /></Field>
          <Field label="Also on discounted items"><input type="checkbox" checked={p.stackable} onChange={e => setP({ ...p, stackable: e.target.checked })} /></Field>
          <Field label="Active"><input type="checkbox" checked={p.active} onChange={e => setP({ ...p, active: e.target.checked })} /></Field>
        </div>
        {err && <p className="error" role="alert">{err}</p>}
        <div className="row"><button type="submit">Save</button><button type="button" className="secondary" onClick={() => setP(null)}>Cancel</button></div>
      </form>}
      {loading && <Loading />}
      {error && <ErrorBox message={error} onRetry={reload} />}
      {data && <div className="card"><table><thead><tr><th>Code</th><th>Discount</th><th>Min order</th><th>Used</th><th>Active</th><th /></tr></thead><tbody>{data.map(x => (
        <tr key={x.id}><td>{x.code}</td><td>{x.type === 'PERCENT' ? `${x.value}%` : formatMoney(x.value)}</td><td>{formatMoney(x.minOrderMinor)}</td><td>{x.usedCount}{x.usageLimit ? ` / ${x.usageLimit}` : ''}</td>
          <td>{x.active ? '✓' : '—'}</td><td><button className="secondary" onClick={() => open(x)}>Edit</button></td></tr>))}</tbody></table></div>}
    </>
  )
}
