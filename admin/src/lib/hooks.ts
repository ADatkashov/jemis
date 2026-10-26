import { useCallback, useEffect, useState } from 'react'
import { ApiError } from './api'

/** Loads data with explicit loading / error states and a reload function. */
export function useLoad<T>(fn: () => Promise<T>, deps: unknown[]) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const reload = useCallback(() => {
    setLoading(true)
    setError(null)
    fn().then(setData).catch(e => setError(e instanceof ApiError ? `${e.code}: ${e.message}` : String(e))).finally(() => setLoading(false))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)
  useEffect(reload, [reload])
  return { data, error, loading, reload }
}

export function errMsg(e: unknown): string {
  return e instanceof ApiError ? `${e.code}: ${e.message}` : String(e)
}
