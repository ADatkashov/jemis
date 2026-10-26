import type { ReactNode } from 'react'
import { useT } from './lib/i18n'

export function Loading() { const t = useT(); return <p className="muted" role="status">{t('loading')}</p> }

export function ErrorBox({ message, onRetry }: { message: string; onRetry?: () => void }) {
  const t = useT()
  return (
    <div className="card error" role="alert">
      {message} {onRetry && <button className="secondary" onClick={onRetry}>{t('retry')}</button>}
    </div>
  )
}

export function Empty() { const t = useT(); return <p className="muted">{t('empty')}</p> }

export function Field({ label, children }: { label: string; children: ReactNode }) { return <label>{label}{children}</label> }

export function Pager({ page, totalPages, onPage }: { page: number; totalPages: number; onPage: (p: number) => void }) {
  if (totalPages <= 1) return null
  return (
    <div className="row" style={{ alignItems: 'center' }}>
      <button className="secondary" disabled={page === 0} onClick={() => onPage(page - 1)}>←</button>
      <span>{page + 1} / {totalPages}</span>
      <button className="secondary" disabled={page + 1 >= totalPages} onClick={() => onPage(page + 1)}>→</button>
    </div>
  )
}
