import { useState } from 'react'
import { api } from '../lib/api'
import { errMsg, useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { ErrorBox, Loading } from '../ui'

const HELP: Record<string, string> = {
  'delivery.days_ahead': 'How many days (including today) customers can book',
  'delivery.lead_minutes': 'Minimum minutes before a window starts that it can still be booked',
  'delivery.immediate_enabled': 'true enables immediate delivery (off by default)',
  'fees.service_minor': 'Service fee in tiyn (100 = 1 ₸)',
  'orders.unpaid_ttl_minutes': 'Minutes before an unpaid online order is cancelled',
  'payment.cash_enabled': 'true allows payment on delivery',
}

export default function SettingsPage() {
  const t = useT()
  const { data, error, loading, reload } = useLoad(() => api<Record<string, string>>('/admin/settings'), [])
  const [edit, setEdit] = useState<Record<string, string>>({})
  const [msg, setMsg] = useState('')
  const save = async () => {
    try { await api('/admin/settings', { method: 'PUT', body: edit }); setEdit({}); setMsg('Saved'); reload() } catch (e) { setMsg(errMsg(e)) }
  }
  if (loading) return <Loading />
  if (error || !data) return <ErrorBox message={error ?? ''} onRetry={reload} />
  return (
    <>
      <h1>{t('settings')}</h1>
      <div className="card">
        <table><tbody>{Object.entries(data).map(([k, v]) => (
          <tr key={k}><td><b>{k}</b><br /><span className="muted">{HELP[k]}</span></td>
            <td><input aria-label={k} value={edit[k] ?? v} onChange={e => setEdit({ ...edit, [k]: e.target.value })} /></td></tr>))}</tbody></table>
        <div className="row"><button disabled={Object.keys(edit).length === 0} onClick={save}>{t('save')}</button><span role="status">{msg}</span></div>
      </div>
    </>
  )
}
