import { describe, expect, it } from 'vitest'
import { formatMoney, formatQuantity, parseMoney, parseQuantity } from './format'

describe('money', () => {
  it('formats minor units without floating point', () => {
    expect(formatMoney(118500).replace(/ /g, ' ')).toBe('1 185 ₸')
    expect(formatMoney(99050).replace(/ /g, ' ')).toBe('990,50 ₸')
    expect(formatMoney(5, 'KZT')).toBe('0,05 ₸')
  })
  it('parses user input into minor units', () => {
    expect(parseMoney('1 290,50')).toBe(129050)
    expect(parseMoney('790')).toBe(79000)
    expect(parseMoney('0.1')).toBe(10)
    expect(parseMoney('12.345')).toBeNull()
    expect(parseMoney('abc')).toBeNull()
    expect(parseMoney('-5')).toBeNull()
  })
})

describe('quantity', () => {
  it('round-trips milli-units', () => {
    expect(formatQuantity(1500)).toBe('1.5')
    expect(formatQuantity(2000)).toBe('2')
    expect(formatQuantity(250)).toBe('0.25')
    expect(parseQuantity('1,5')).toBe(1500)
    expect(parseQuantity('0.25')).toBe(250)
    expect(parseQuantity('1.2345')).toBeNull()
  })
})
