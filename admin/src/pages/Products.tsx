import { useState } from 'react'
import { api, type Page } from '../lib/api'
import { formatMoney, formatQuantity, parseMoney, parseQuantity } from '../lib/format'
import { errMsg, useLoad } from '../lib/hooks'
import { useT } from '../lib/i18n'
import { Empty, ErrorBox, Field, Loading, Pager } from '../ui'

interface Product {
  id?: string; categoryId: string; sku: string; brand?: string; nameRu: string; nameKk: string; nameEn: string
  descriptionRu?: string; descriptionKk?: string; descriptionEn?: string
  unit: string; weighted: boolean; stepMilli: number; packLabel?: string; priceMinor: number; oldPriceMinor?: number | null
  imageUrl?: string; stockMilli?: number; reservedMilli?: number; lowStockMilli: number; active: boolean
}
interface Category { id: string; nameRu: string }
const UNITS = ['PIECE', 'KG', 'G', 'L', 'ML', 'PACK']
const blank = (categoryId: string): Product => ({ categoryId, sku: '', nameRu: '', nameKk: '', nameEn: '', unit: 'PIECE', weighted: false, stepMilli: 1000, priceMinor: 0, lowStockMilli: 5000, active: true })

export default function Products() {
  const t = useT()
  const [q, setQ] = useState('')
  const [page, setPage] = useState(0)
  const [edit, setEdit] = useState<Product | null>(null)
  const cats = useLoad(() => api<Category[]>('/admin/categories'), [])
  const { data, error, loading, reload } = useLoad(() => api<Page<Product>>(`/admin/products?size=25&page=${page}&q=${encodeURIComponent(q)}`), [q, page])
  return (
    <>
      <h1>{t('products')}</h1>
      <div className="row">
        <Field label={t('search')}><input value={q} onChange={e => { setQ(e.target.value); setPage(0) }} /></Field>
        <button disabled={!cats.data?.length} onClick={() => setEdit(blank(cats.data![0].id))}>+ New</button>
      </div>
      {edit && cats.data && <ProductForm initial={edit} categories={cats.data} onClose={() => setEdit(null)} onSaved={() => { setEdit(null); reload() }} />}
      {loading && <Loading />}
      {error && <ErrorBox message={error} onRetry={reload} />}
      {data && (data.items.length === 0 ? <Empty /> : (
        <div className="card">
          <table>
            <thead><tr><th>SKU</th><th>Name</th><th>Price</th><th>Stock / reserved</th><th>Active</th><th /></tr></thead>
            <tbody>{data.items.map(p => (
              <tr key={p.id}><td>{p.sku}</td><td>{p.nameRu}</td><td>{formatMoney(p.priceMinor)}{p.oldPriceMinor ? <s className="muted"> {formatMoney(p.oldPriceMinor)}</s> : null}</td>
                <td>{formatQuantity(p.stockMilli ?? 0)} / {formatQuantity(p.reservedMilli ?? 0)}</td><td>{p.active ? '✓' : '—'}</td>
                <td><button className="secondary" onClick={() => setEdit(p)}>Edit</button></td></tr>))}</tbody>
          </table>
          <Pager page={data.page} totalPages={data.totalPages} onPage={setPage} />
        </div>
      ))}
    </>
  )
}

function ProductForm({ initial, categories, onClose, onSaved }: { initial: Product; categories: Category[]; onClose: () => void; onSaved: () => void }) {
  const [p, setP] = useState(initial)
  const [price, setPrice] = useState(String(initial.priceMinor / 100).replace('.', ','))
  const [old, setOld] = useState(initial.oldPriceMinor ? String(initial.oldPriceMinor / 100).replace('.', ',') : '')
  const [delta, setDelta] = useState('')
  const [reason, setReason] = useState('')
  const [err, setErr] = useState('')
  const set = <K extends keyof Product>(k: K, v: Product[K]) => setP(prev => ({ ...prev, [k]: v }))

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    const pm = parseMoney(price)
    const om = old.trim() ? parseMoney(old) : null
    if (pm === null || (old.trim() && om === null)) { setErr('Invalid price'); return }
    if (om !== null && om <= pm) { setErr('Previous price must be higher than the price'); return }
    try {
      const body = { ...p, priceMinor: pm, oldPriceMinor: om }
      if (p.id) await api(`/admin/products/${p.id}`, { method: 'PUT', body })
      else await api('/admin/products', { method: 'POST', body })
      onSaved()
    } catch (e2) { setErr(errMsg(e2)) }
  }
  const adjust = async () => {
    const d = parseQuantity(delta.replace('-', ''))
    if (d === null || !reason.trim()) { setErr('Enter a quantity and a reason'); return }
    try { await api(`/admin/products/${p.id}/stock`, { method: 'POST', body: { deltaMilli: delta.startsWith('-') ? -d : d, reason } }); onSaved() }
    catch (e2) { setErr(errMsg(e2)) }
  }
  return (
    <form className="card" onSubmit={save}>
      <h2>{p.id ? 'Edit product' : 'New product'}</h2>
      <div className="row">
        <Field label="SKU"><input value={p.sku} onChange={e => set('sku', e.target.value)} required /></Field>
        <Field label="Category"><select value={p.categoryId} onChange={e => set('categoryId', e.target.value)}>{categories.map(c => <option key={c.id} value={c.id}>{c.nameRu}</option>)}</select></Field>
        <Field label="Brand"><input value={p.brand ?? ''} onChange={e => set('brand', e.target.value)} /></Field>
      </div>
      <div className="row">
        <Field label="Name (ru)"><input value={p.nameRu} onChange={e => set('nameRu', e.target.value)} required /></Field>
        <Field label="Name (kk)"><input value={p.nameKk} onChange={e => set('nameKk', e.target.value)} required /></Field>
        <Field label="Name (en)"><input value={p.nameEn} onChange={e => set('nameEn', e.target.value)} required /></Field>
      </div>
      <div className="row">
        <Field label="Description (ru)"><textarea value={p.descriptionRu ?? ''} onChange={e => set('descriptionRu', e.target.value)} /></Field>
        <Field label="Description (kk)"><textarea value={p.descriptionKk ?? ''} onChange={e => set('descriptionKk', e.target.value)} /></Field>
        <Field label="Description (en)"><textarea value={p.descriptionEn ?? ''} onChange={e => set('descriptionEn', e.target.value)} /></Field>
      </div>
      <div className="row">
        <Field label="Unit"><select value={p.unit} onChange={e => set('unit', e.target.value)}>{UNITS.map(u => <option key={u}>{u}</option>)}</select></Field>
        <Field label="Sold by weight/volume"><input type="checkbox" checked={p.weighted} onChange={e => set('weighted', e.target.checked)} /></Field>
        <Field label="Step (milli-units, 1000 = 1)"><input type="number" min={1} value={p.stepMilli} onChange={e => set('stepMilli', Number(e.target.value))} /></Field>
        <Field label="Pack label"><input value={p.packLabel ?? ''} onChange={e => set('packLabel', e.target.value)} /></Field>
      </div>
      <div className="row">
        <Field label="Price, ₸ (per 1 unit)"><input value={price} onChange={e => setPrice(e.target.value)} inputMode="decimal" required /></Field>
        <Field label="Previous price, ₸"><input value={old} onChange={e => setOld(e.target.value)} inputMode="decimal" /></Field>
        <Field label="Image URL"><input value={p.imageUrl ?? ''} onChange={e => set('imageUrl', e.target.value)} /></Field>
        <Field label="Active"><input type="checkbox" checked={p.active} onChange={e => set('active', e.target.checked)} /></Field>
      </div>
      {p.id && (
        <div className="row">
          <span>Stock {formatQuantity(p.stockMilli ?? 0)}, reserved {formatQuantity(p.reservedMilli ?? 0)}</span>
          <Field label="Adjust by (e.g. 10 or -2.5)"><input value={delta} onChange={e => setDelta(e.target.value)} /></Field>
          <Field label="Reason"><input value={reason} onChange={e => setReason(e.target.value)} /></Field>
          <button type="button" className="secondary" onClick={adjust}>Apply adjustment</button>
        </div>)}
      {err && <p className="error" role="alert">{err}</p>}
      <div className="row"><button type="submit">Save</button><button type="button" className="secondary" onClick={onClose}>Cancel</button></div>
    </form>
  )
}
