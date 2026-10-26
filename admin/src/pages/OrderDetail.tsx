import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { api } from '../lib/api'
import { formatMoney, formatQuantity } from '../lib/format'
import { errMsg, useLoad } from '../lib/hooks'
import { ErrorBox, Field, Loading } from '../ui'

interface Detail {
  order: {
    id: string; number: string; status: string; paymentStatus: string; paymentMethod: string; recipientName: string
    address: { city: string; street: string; house: string; apartment?: string; entrance?: string; floor?: string; intercom?: string }
    slot?: { date: string; start: string; end: string }; instructions?: string
    subtotalMinor: number; discountMinor: number; deliveryFeeMinor: number; serviceFeeMinor: number; totalMinor: number; promoCode?: string
    items: { productId: string; sku: string; name: string; unitPriceMinor: number; quantityMilli: number; lineTotalMinor: number }[]
    timeline: { status: string; note?: string; at: string }[]
  }
  operatorNotes?: string; recipientPhone?: string
  courier?: { id: string; name: string; phone?: string }
  payments: { id: string; provider: string; status: string; amountMinor: number; failureReason?: string }[]
  issues: { description: string; createdAt: string }[]
  allowedNext: string[]
}
interface Courier { id: string; displayName: string; active: boolean }

export default function OrderDetail() {
  const { id } = useParams()
  const { data, error, loading, reload } = useLoad(() => api<Detail>(`/admin/orders/${id}`), [id])
  const couriers = useLoad(() => api<Courier[]>('/admin/delivery/couriers'), [])
  const [msg, setMsg] = useState('')
  const [notes, setNotes] = useState<string | null>(null)
  const [courierId, setCourierId] = useState('')

  const act = async (fn: () => Promise<unknown>) => {
    setMsg('')
    try { await fn(); reload() } catch (e) { setMsg(errMsg(e)) }
  }
  if (loading && !data) return <Loading />
  if (error || !data) return <ErrorBox message={error ?? ''} onRetry={reload} />
  const o = data.order
  return (
    <>
      <h1>{o.number} <span className="badge">{o.status}</span></h1>
      {msg && <p className="error" role="alert">{msg}</p>}
      <div className="card">
        <h2>Status</h2>
        <div className="row">
          {data.allowedNext.map(s => (
            <button key={s} className={s === 'CANCELLED' ? 'danger' : ''}
              onClick={() => { if (s !== 'CANCELLED' || confirm('Cancel this order?')) void act(() => api(`/admin/orders/${id}/status`, { method: 'POST', body: { status: s } })) }}>
              → {s}
            </button>))}
          {o.paymentStatus === 'SUCCEEDED' && ['CANCELLED', 'DELIVERED'].includes(o.status) &&
            <button className="secondary" onClick={() => confirm('Refund this order?') && void act(() => api(`/admin/orders/${id}/refund`, { method: 'POST' }))}>Refund</button>}
        </div>
        {o.status === 'READY_FOR_DELIVERY' && (
          <div className="row">
            <Field label="Courier">
              <select value={courierId} onChange={e => setCourierId(e.target.value)}>
                <option value="">—</option>{couriers.data?.filter(c => c.active).map(c => <option key={c.id} value={c.id}>{c.displayName}</option>)}
              </select>
            </Field>
            <button disabled={!courierId} onClick={() => void act(() => api(`/admin/orders/${id}/assign`, { method: 'POST', body: { courierId } }))}>Offer to courier</button>
          </div>)}
        {data.courier && <p>Courier: {data.courier.name} {data.courier.phone}</p>}
      </div>
      <div className="card">
        <h2>Delivery</h2>
        <p>{o.recipientName} {data.recipientPhone}<br />{o.address.city}, {o.address.street} {o.address.house}
          {o.address.apartment && `, apt ${o.address.apartment}`}{o.address.entrance && `, entrance ${o.address.entrance}`}{o.address.floor && `, floor ${o.address.floor}`}{o.address.intercom && `, intercom ${o.address.intercom}`}</p>
        {o.slot && <p>{o.slot.date} {o.slot.start.slice(0, 5)}–{o.slot.end.slice(0, 5)}</p>}
        {o.instructions && <p className="muted">{o.instructions}</p>}
      </div>
      <div className="card">
        <h2>Items</h2>
        <table>
          <tbody>
            {o.items.map(i => <tr key={i.productId}><td>{i.sku}</td><td>{i.name}</td><td>{formatQuantity(i.quantityMilli)}</td><td>{formatMoney(i.unitPriceMinor)}</td><td>{formatMoney(i.lineTotalMinor)}</td></tr>)}
            <tr><td colSpan={4}>Subtotal</td><td>{formatMoney(o.subtotalMinor)}</td></tr>
            {o.discountMinor > 0 && <tr><td colSpan={4}>Discount {o.promoCode}</td><td>-{formatMoney(o.discountMinor)}</td></tr>}
            <tr><td colSpan={4}>Delivery</td><td>{formatMoney(o.deliveryFeeMinor)}</td></tr>
            {o.serviceFeeMinor > 0 && <tr><td colSpan={4}>Service fee</td><td>{formatMoney(o.serviceFeeMinor)}</td></tr>}
            <tr><td colSpan={4}><b>Total</b></td><td><b>{formatMoney(o.totalMinor)}</b></td></tr>
          </tbody>
        </table>
      </div>
      <div className="card">
        <h2>Payment ({o.paymentMethod}) <span className="badge">{o.paymentStatus}</span></h2>
        <table><tbody>{data.payments.map(p => <tr key={p.id}><td>{p.provider}</td><td>{p.status}</td><td>{formatMoney(p.amountMinor)}</td><td>{p.failureReason}</td></tr>)}</tbody></table>
      </div>
      {data.issues.length > 0 && <div className="card"><h2>Delivery issues</h2>{data.issues.map((i, k) => <p key={k}>{new Date(i.createdAt).toLocaleString()}: {i.description}</p>)}</div>}
      <div className="card">
        <h2>Timeline</h2>
        <ul>{o.timeline.map((e, k) => <li key={k}>{new Date(e.at).toLocaleString()} — {e.status} {e.note && <span className="muted">({e.note})</span>}</li>)}</ul>
      </div>
      <div className="card">
        <h2>Operator notes</h2>
        <textarea rows={3} style={{ width: '100%' }} value={notes ?? data.operatorNotes ?? ''} onChange={e => setNotes(e.target.value)} />
        <div className="row"><button disabled={!notes} onClick={() => void act(() => api(`/admin/orders/${id}/notes`, { method: 'POST', body: { notes } }))}>Save</button></div>
      </div>
    </>
  )
}
