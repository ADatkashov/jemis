import { Link } from 'react-router-dom'
import { api } from '../lib/api'
import { formatMoney, formatQuantity } from '../lib/format'
import { useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { ErrorBox, Loading } from '../ui'

interface Dash {
  ordersToday: number; paidRevenueTodayMinor: number; currency: string; awaitingProcessing: number; inDelivery: number
  lowStockCount: number
  lowStock: { id: string; sku: string; name: string; availableMilli: number; thresholdMilli: number }[]
  recentOrders: { id: string; number: string; status: string; paymentStatus: string; totalMinor: number }[]
}

export default function Dashboard() {
  const t = useT()
  const { data, error, loading, reload } = useLoad(() => api<Dash>('/admin/dashboard'), [])
  if (loading) return <Loading />
  if (error || !data) return <ErrorBox message={error ?? ''} onRetry={reload} />
  return (
    <>
      <h1>{t('dashboard')}</h1>
      <div className="grid">
        <div className="card metric">{t('ordersToday')}<b>{data.ordersToday}</b></div>
        <div className="card metric">{t('paidRevenue')}<b>{formatMoney(data.paidRevenueTodayMinor, data.currency)}</b></div>
        <div className="card metric">{t('awaiting')}<b>{data.awaitingProcessing}</b></div>
        <div className="card metric">{t('inDelivery')}<b>{data.inDelivery}</b></div>
        <div className="card metric">{t('lowStock')}<b>{data.lowStockCount}</b></div>
      </div>
      <p className="muted">Revenue counts only orders whose payment succeeded today; unpaid, cancelled and refunded orders are excluded.</p>
      <div className="card">
        <h2>{t('recent')}</h2>
        <table>
          <thead><tr><th>#</th><th>Status</th><th>Payment</th><th>Total</th></tr></thead>
          <tbody>{data.recentOrders.map(o => (
            <tr key={o.id}><td><Link to={`/orders/${o.id}`}>{o.number}</Link></td><td><span className="badge">{o.status}</span></td>
              <td>{o.paymentStatus}</td><td>{formatMoney(o.totalMinor)}</td></tr>))}</tbody>
        </table>
      </div>
      <div className="card">
        <h2>{t('lowStock')}</h2>
        <table>
          <tbody>{data.lowStock.map(p => (
            <tr key={p.id}><td>{p.sku}</td><td>{p.name}</td><td>{formatQuantity(p.availableMilli)}</td></tr>))}</tbody>
        </table>
      </div>
    </>
  )
}
