import { api } from '../lib/api'
import { useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { ErrorBox, Loading } from '../ui'

interface Row { createdAt: string; actorEmail?: string; action: string; entity: string; entityId?: string; details?: string }

export default function Audit() {
  const t = useT()
  const { data, error, loading, reload } = useLoad(() => api<Row[]>('/admin/audit-log?size=100'), [])
  if (loading) return <Loading />
  if (error || !data) return <ErrorBox message={error ?? ''} onRetry={reload} />
  return (
    <>
      <h1>{t('audit')}</h1>
      <div className="card"><table><thead><tr><th>Time</th><th>Actor</th><th>Action</th><th>Entity</th><th>Details</th></tr></thead><tbody>{data.map((r, i) => (
        <tr key={i}><td>{new Date(r.createdAt).toLocaleString()}</td><td>{r.actorEmail}</td><td>{r.action}</td><td>{r.entity} {r.entityId}</td><td>{r.details}</td></tr>))}</tbody></table></div>
    </>
  )
}
