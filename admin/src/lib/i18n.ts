import { createContext, useContext } from 'react'

export type Lang = 'ru' | 'kk' | 'en'
const dict: Record<string, Record<Lang, string>> = {
  dashboard: { ru: 'Обзор', kk: 'Шолу', en: 'Dashboard' },
  orders: { ru: 'Заказы', kk: 'Тапсырыстар', en: 'Orders' },
  products: { ru: 'Товары', kk: 'Тауарлар', en: 'Products' },
  categories: { ru: 'Категории', kk: 'Санаттар', en: 'Categories' },
  delivery: { ru: 'Доставка', kk: 'Жеткізу', en: 'Delivery' },
  promotions: { ru: 'Промокоды', kk: 'Промокодтар', en: 'Promotions' },
  customers: { ru: 'Клиенты', kk: 'Клиенттер', en: 'Customers' },
  staff: { ru: 'Сотрудники', kk: 'Қызметкерлер', en: 'Staff' },
  settings: { ru: 'Настройки', kk: 'Баптаулар', en: 'Settings' },
  audit: { ru: 'Журнал аудита', kk: 'Аудит журналы', en: 'Audit log' },
  logout: { ru: 'Выйти', kk: 'Шығу', en: 'Log out' },
  login: { ru: 'Войти', kk: 'Кіру', en: 'Sign in' },
  save: { ru: 'Сохранить', kk: 'Сақтау', en: 'Save' },
  cancel: { ru: 'Отмена', kk: 'Бас тарту', en: 'Cancel' },
  search: { ru: 'Поиск', kk: 'Іздеу', en: 'Search' },
  loading: { ru: 'Загрузка…', kk: 'Жүктелуде…', en: 'Loading…' },
  retry: { ru: 'Повторить', kk: 'Қайталау', en: 'Retry' },
  empty: { ru: 'Ничего не найдено', kk: 'Ештеңе табылмады', en: 'Nothing found' },
  ordersToday: { ru: 'Заказов сегодня', kk: 'Бүгінгі тапсырыстар', en: 'Orders today' },
  paidRevenue: { ru: 'Оплаченная выручка сегодня', kk: 'Бүгінгі төленген түсім', en: 'Paid revenue today' },
  awaiting: { ru: 'Ожидают обработки', kk: 'Өңдеуді күтуде', en: 'Awaiting processing' },
  inDelivery: { ru: 'В доставке', kk: 'Жеткізілуде', en: 'In delivery' },
  lowStock: { ru: 'Заканчиваются', kk: 'Таусылуда', en: 'Low stock' },
  recent: { ru: 'Последние заказы', kk: 'Соңғы тапсырыстар', en: 'Recent orders' },
}
export const LangContext = createContext<{ lang: Lang; setLang: (l: Lang) => void }>({ lang: 'ru', setLang: () => {} })
export function useT() {
  const { lang } = useContext(LangContext)
  return (key: string) => dict[key]?.[lang] ?? key
}
