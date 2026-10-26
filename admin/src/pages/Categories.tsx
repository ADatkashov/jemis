import { useState } from 'react'
import { api } from '../lib/api'
import { errMsg, useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { ErrorBox, Field, Loading } from '../ui'

interface Cat { id?: string; parentId?: string | null; slug: string; nameRu: string; nameKk: string; nameEn: string; icon?: string; imageUrl?: string; sortOrder: number; active: boolean }
const blank: Cat = { slug: '', nameRu: '', nameKk: '', nameEn: '', sortOrder: 0, active: true }

export default function Categories() {
  const t = useT()
  const { data, error, loading, reload } = useLoad(() => api<Cat[]>('/admin/categories'), [])
  const [c, setC] = useState<Cat | null>(null)
  const [err, setErr] = useState('')
  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      if (c!.id) await api(`/admin/categories/${c!.id}`, { method: 'PUT', body: c })
      else await api('/admin/categories', { method: 'POST', body: c })
      setC(null); setErr(''); reload()
    } catch (e2) { setErr(errMsg(e2)) }
  }
  const set = <K extends keyof Cat>(k: K, v: Cat[K]) => setC(prev => ({ ...prev!, [k]: v }))
  return (
    <>
      <h1>{t('categories')}</h1>
      <div className="row"><button onClick={() => setC(blank)}>+ New</button></div>
      {c && (
        <form className="card" onSubmit={save}>
          <div className="row">
            <Field label="Slug (a-z, 0-9, -)"><input value={c.slug} pattern="[a-z0-9\-]+" onChange={e => set('slug', e.target.value)} required /></Field>
            <Field label="Parent"><select value={c.parentId ?? ''} onChange={e => set('parentId', e.target.value || null)}><option value="">—</option>{data?.filter(x => x.id !== c.id).map(x => <option key={x.id} value={x.id}>{x.nameRu}</option>)}</select></Field>
            <Field label="Icon key"><input value={c.icon ?? ''} onChange={e => set('icon', e.target.value)} /></Field>
            <Field label="Sort"><input type="number" value={c.sortOrder} onChange={e => set('sortOrder', Number(e.target.value))} /></Field>
            <Field label="Active"><input type="checkbox" checked={c.active} onChange={e => set('active', e.target.checked)} /></Field>
          </div>
          <div className="row">
            <Field label="Name (ru)"><input value={c.nameRu} onChange={e => set('nameRu', e.target.value)} required /></Field>
            <Field label="Name (kk)"><input value={c.nameKk} onChange={e => set('nameKk', e.target.value)} required /></Field>
            <Field label="Name (en)"><input value={c.nameEn} onChange={e => set('nameEn', e.target.value)} required /></Field>
          </div>
          {err && <p className="error" role="alert">{err}</p>}
          <div className="row"><button type="submit">Save</button><button type="button" className="secondary" onClick={() => setC(null)}>Cancel</button></div>
        </form>)}
      {loading && <Loading />}
      {error && <ErrorBox message={error} onRetry={reload} />}
      {data && <div className="card"><table><tbody>{data.map(x => (
        <tr key={x.id}><td>{x.sortOrder}</td><td>{x.slug}</td><td>{x.nameRu} / {x.nameKk} / {x.nameEn}</td><td>{x.active ? '✓' : '—'}</td>
          <td><button className="secondary" onClick={() => setC(x)}>Edit</button></td></tr>))}</tbody></table></div>}
    </>
  )
}
