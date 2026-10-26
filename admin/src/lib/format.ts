/** Money is integer minor units (tiyn); quantities are integer milli-units. No floating point math on money. */
export function formatMoney(minor: number, currency = 'KZT', locale = 'ru-RU'): string {
  const sign = minor < 0 ? '-' : ''
  const abs = Math.abs(minor)
  const whole = Math.floor(abs / 100)
  const frac = abs % 100
  const wholeStr = new Intl.NumberFormat(locale).format(whole)
  const symbol = currency === 'KZT' ? '₸' : currency
  return `${sign}${wholeStr}${frac ? ',' + String(frac).padStart(2, '0') : ''} ${symbol}`
}

/** Parses a user-entered amount like "1 290,50" into minor units; returns null if invalid. */
export function parseMoney(input: string): number | null {
  const s = input.replace(/\s/g, '').replace(',', '.')
  if (!/^\d+(\.\d{1,2})?$/.test(s)) return null
  const [w, f = ''] = s.split('.')
  return Number(w) * 100 + Number(f.padEnd(2, '0'))
}

export function formatQuantity(milli: number): string {
  const whole = Math.floor(milli / 1000)
  const frac = milli % 1000
  return frac ? `${whole}.${String(frac).padStart(3, '0').replace(/0+$/, '')}` : String(whole)
}

export function parseQuantity(input: string): number | null {
  const s = input.replace(',', '.').trim()
  if (!/^\d+(\.\d{1,3})?$/.test(s)) return null
  const [w, f = ''] = s.split('.')
  return Number(w) * 1000 + Number(f.padEnd(3, '0'))
}
