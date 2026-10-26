import { useState } from 'react'
import { Link } from 'react-router-dom'
import { api, type Page } from '../lib/api'
import { formatMoney } from '../lib/format'
import { useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { Empty, ErrorBox, Field, Loading, Pager } from '../ui'

interface Row { id: string; fullName: string; email?: string; phone?: string; status: string; createdAt: string }
interface Detail { customer: Row; orders: { id: string; number: string; status: string; totalMinor: number; createdAt: string }[] }

export default function Customers() {
  const t = useT()
  const [q, setQ] = useState('')
  const [page, setPage] = useState(0)
  const [sel, setSel] = useState<string | null>(null)
  const { data, error, loading, reload } = useLoad(() => api<Page<Row>>(`/admin/customers?page=${page}&q=${encodeURIComponent(q)}`), [q, page])
  const detail = useLoad(() => sel ? api<Detail>(`/admin/customers/${sel}`) : Promise.resolve(null), [sel])
  return (
    <>
      <h1>{t('customers')}</h1>
      <div className="row"><Field label={t('search')}><input value={q} onChange={e => { setQ(e.target.value); setPage(0) }} /></Field></div>
      {loading && <Loading />}
      {error && <ErrorBox message={error} onRetry={reload} />}
      {data && (data.items.length === 0 ? <Empty /> : <div className="card"><table><tbody>{data.items.map(c => (
        <tr key={c.id}><td>{c.fullName}</td><td>{c.email}</td><td>{c.phone}</td><td>{c.status}</td><td><button className="secondary" onClick={() => setSel(c.id)}>Orders</button></td></tr>))}</tbody></table>
        <Pager page={data.page} totalPages={data.totalPages} onPage={setPage} /></div>)}
      {detail.data && <div className="card"><h2>{detail.data.customer.fullName}</h2><table><tbody>{detail.data.orders.map(o => (
        <tr key={o.id}><td><Link to={`/orders/${o.id}`}>{o.number}</Link></td><td>{o.status}</td><td>{formatMoney(o.totalMinor)}</td><td>{new Date(o.createdAt).toLocaleString()}</td></tr>))}</tbody></table></div>}
    </>
  )
}
