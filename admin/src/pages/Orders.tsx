import { useState } from 'react'
import { Link } from 'react-router-dom'
import { api, type Page } from '../lib/api'
import { formatMoney } from '../lib/format'
import { useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { Empty, ErrorBox, Field, Loading, Pager } from '../ui'

interface Row { id: string; number: string; status: string; paymentStatus: string; recipientName: string; totalMinor: number; createdAt: string }
export const STATUSES = ['PENDING_PAYMENT', 'CONFIRMED', 'ACCEPTED', 'PREPARING', 'READY_FOR_DELIVERY', 'ASSIGNED_TO_COURIER', 'PICKED_UP', 'ON_THE_WAY', 'DELIVERED', 'CANCELLED', 'REFUNDED']

export default function Orders() {
  const t = useT()
  const [q, setQ] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(0)
  const { data, error, loading, reload } = useLoad(() => {
    const p = new URLSearchParams({ page: String(page), size: '25' })
    if (q) p.set('q', q)
    if (status) p.set('status', status)
    return api<Page<Row>>('/admin/orders?' + p)
  }, [q, status, page])
  return (
    <>
      <h1>{t('orders')}</h1>
      <div className="row">
        <Field label={t('search')}><input value={q} onChange={e => { setQ(e.target.value); setPage(0) }} placeholder="JM-100001 / name / phone" /></Field>
        <Field label="Status">
          <select value={status} onChange={e => { setStatus(e.target.value); setPage(0) }}>
            <option value="">—</option>{STATUSES.map(s => <option key={s}>{s}</option>)}
          </select>
        </Field>
      </div>
      {loading && <Loading />}
      {error && <ErrorBox message={error} onRetry={reload} />}
      {data && (data.items.length === 0 ? <Empty /> : (
        <div className="card">
          <table>
            <thead><tr><th>#</th><th>Date</th><th>Recipient</th><th>Status</th><th>Payment</th><th>Total</th></tr></thead>
            <tbody>{data.items.map(o => (
              <tr key={o.id}><td><Link to={`/orders/${o.id}`}>{o.number}</Link></td><td>{new Date(o.createdAt).toLocaleString()}</td>
                <td>{o.recipientName}</td><td><span className="badge">{o.status}</span></td><td>{o.paymentStatus}</td><td>{formatMoney(o.totalMinor)}</td></tr>))}</tbody>
          </table>
          <Pager page={data.page} totalPages={data.totalPages} onPage={setPage} />
        </div>
      ))}
    </>
  )
}
