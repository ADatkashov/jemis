import { useState } from 'react'
import { api } from '../lib/api'
import { formatMoney, parseMoney } from '../lib/format'
import { errMsg, useLoad } from '../lib/hooks'
import { ErrorBox, Field, Loading } from '../ui'

interface Zone { id?: string; name: string; city: string; feeMinor: number; minOrderMinor: number; freeDeliveryThresholdMinor?: number | null; active: boolean }
interface Slot { id?: string; startTime: string; endTime: string; capacity: number; daysOfWeek: string; extraFeeMinor: number; active: boolean }
interface Courier { id: string; displayName: string; phone?: string; active: boolean; trackingConsent: boolean }

export default function DeliveryPage() {
  const zones = useLoad(() => api<Zone[]>('/admin/delivery/zones'), [])
  const slots = useLoad(() => api<Slot[]>('/admin/delivery/slots'), [])
  const couriers = useLoad(() => api<Courier[]>('/admin/delivery/couriers'), [])
  return (
    <>
      <h1>Delivery</h1>
      <p className="muted">Delivery zones currently match by city only; no geocoding/polygon provider is configured.</p>
      {zones.loading ? <Loading /> : zones.error ? <ErrorBox message={zones.error} onRetry={zones.reload} /> : <Zones list={zones.data ?? []} reload={zones.reload} />}
      {slots.loading ? <Loading /> : slots.error ? <ErrorBox message={slots.error} onRetry={slots.reload} /> : <Slots list={slots.data ?? []} reload={slots.reload} />}
      <div className="card"><h2>Couriers</h2><table><tbody>{couriers.data?.map(c => (
        <tr key={c.id}><td>{c.displayName}</td><td>{c.phone}</td><td>{c.active ? 'active' : 'disabled'}</td><td>{c.trackingConsent ? 'location sharing on' : 'location sharing off'}</td></tr>))}</tbody></table>
        <p className="muted">Create couriers in Staff (role COURIER).</p></div>
    </>
  )
}

function Zones({ list, reload }: { list: Zone[]; reload: () => void }) {
  const [z, setZ] = useState<(Zone & { fee: string; min: string; free: string }) | null>(null)
  const [err, setErr] = useState('')
  const open = (x?: Zone) => setZ({ name: '', city: '', feeMinor: 0, minOrderMinor: 0, active: true, ...x,
    fee: String((x?.feeMinor ?? 0) / 100), min: String((x?.minOrderMinor ?? 0) / 100), free: x?.freeDeliveryThresholdMinor ? String(x.freeDeliveryThresholdMinor / 100) : '' })
  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    const fee = parseMoney(z!.fee), min = parseMoney(z!.min), free = z!.free.trim() ? parseMoney(z!.free) : null
    if (fee === null || min === null || (z!.free.trim() && free === null)) { setErr('Invalid amount'); return }
    const body = { name: z!.name, city: z!.city, feeMinor: fee, minOrderMinor: min, freeDeliveryThresholdMinor: free, active: z!.active }
    try { if (z!.id) await api(`/admin/delivery/zones/${z!.id}`, { method: 'PUT', body }); else await api('/admin/delivery/zones', { method: 'POST', body }); setZ(null); setErr(''); reload() }
    catch (e2) { setErr(errMsg(e2)) }
  }
  return (
    <div className="card">
      <h2>Zones, fees and minimums</h2>
      <table><thead><tr><th>Name</th><th>City</th><th>Fee</th><th>Minimum</th><th>Free from</th><th>Active</th><th /></tr></thead>
        <tbody>{list.map(x => <tr key={x.id}><td>{x.name}</td><td>{x.city}</td><td>{formatMoney(x.feeMinor)}</td><td>{formatMoney(x.minOrderMinor)}</td>
          <td>{x.freeDeliveryThresholdMinor ? formatMoney(x.freeDeliveryThresholdMinor) : '—'}</td><td>{x.active ? '✓' : '—'}</td><td><button className="secondary" onClick={() => open(x)}>Edit</button></td></tr>)}</tbody></table>
      <div className="row"><button onClick={() => open()}>+ Zone</button></div>
      {z && <form onSubmit={save}>
        <div className="row">
          <Field label="Name"><input value={z.name} onChange={e => setZ({ ...z, name: e.target.value })} required /></Field>
          <Field label="City (must equal the customer's address city)"><input value={z.city} onChange={e => setZ({ ...z, city: e.target.value })} required /></Field>
          <Field label="Delivery fee, ₸"><input value={z.fee} onChange={e => setZ({ ...z, fee: e.target.value })} /></Field>
          <Field label="Minimum order, ₸"><input value={z.min} onChange={e => setZ({ ...z, min: e.target.value })} /></Field>
          <Field label="Free delivery from, ₸"><input value={z.free} onChange={e => setZ({ ...z, free: e.target.value })} /></Field>
          <Field label="Active"><input type="checkbox" checked={z.active} onChange={e => setZ({ ...z, active: e.target.checked })} /></Field>
        </div>
        {err && <p className="error" role="alert">{err}</p>}
        <div className="row"><button type="submit">Save</button><button type="button" className="secondary" onClick={() => setZ(null)}>Cancel</button></div>
      </form>}
    </div>
  )
}

function Slots({ list, reload }: { list: Slot[]; reload: () => void }) {
  const [s, setS] = useState<(Slot & { extra: string }) | null>(null)
  const [err, setErr] = useState('')
  const open = (x?: Slot) => setS({ startTime: '10:00', endTime: '12:00', capacity: 10, daysOfWeek: '1,2,3,4,5,6,7', extraFeeMinor: 0, active: true, ...x, extra: String((x?.extraFeeMinor ?? 0) / 100) })
  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    const extra = parseMoney(s!.extra)
    if (extra === null) { setErr('Invalid amount'); return }
    const body = { startTime: s!.startTime.slice(0, 5), endTime: s!.endTime.slice(0, 5), capacity: s!.capacity, daysOfWeek: s!.daysOfWeek, extraFeeMinor: extra, active: s!.active }
    try { if (s!.id) await api(`/admin/delivery/slots/${s!.id}`, { method: 'PUT', body }); else await api('/admin/delivery/slots', { method: 'POST', body }); setS(null); setErr(''); reload() }
    catch (e2) { setErr(errMsg(e2)) }
  }
  return (
    <div className="card">
      <h2>Delivery windows and capacity</h2>
      <table><thead><tr><th>Window</th><th>Capacity / window</th><th>Days (1=Mon)</th><th>Extra fee</th><th>Active</th><th /></tr></thead>
        <tbody>{list.map(x => <tr key={x.id}><td>{x.startTime.slice(0, 5)}–{x.endTime.slice(0, 5)}</td><td>{x.capacity}</td><td>{x.daysOfWeek}</td><td>{formatMoney(x.extraFeeMinor)}</td><td>{x.active ? '✓' : '—'}</td>
          <td><button className="secondary" onClick={() => open(x)}>Edit</button></td></tr>)}</tbody></table>
      <div className="row"><button onClick={() => open()}>+ Window</button></div>
      {s && <form onSubmit={save}>
        <div className="row">
          <Field label="From"><input type="time" value={s.startTime.slice(0, 5)} onChange={e => setS({ ...s, startTime: e.target.value })} required /></Field>
          <Field label="To"><input type="time" value={s.endTime.slice(0, 5)} onChange={e => setS({ ...s, endTime: e.target.value })} required /></Field>
          <Field label="Capacity (orders)"><input type="number" min={0} value={s.capacity} onChange={e => setS({ ...s, capacity: Number(e.target.value) })} /></Field>
          <Field label="Days, e.g. 1,2,3"><input value={s.daysOfWeek} pattern="[1-7](,[1-7])*" onChange={e => setS({ ...s, daysOfWeek: e.target.value })} /></Field>
          <Field label="Extra fee, ₸"><input value={s.extra} onChange={e => setS({ ...s, extra: e.target.value })} /></Field>
          <Field label="Active"><input type="checkbox" checked={s.active} onChange={e => setS({ ...s, active: e.target.checked })} /></Field>
        </div>
        {err && <p className="error" role="alert">{err}</p>}
        <div className="row"><button type="submit">Save</button><button type="button" className="secondary" onClick={() => setS(null)}>Cancel</button></div>
      </form>}
    </div>
  )
}
