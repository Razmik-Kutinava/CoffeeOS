/**
 * TASK_110: предварительный экран перед системным запросом уведомлений.
 * Тексты, правило автопоказа, «Не сейчас» на устройстве, одна карточка на экран,
 * события воронки согласия (таблица снимков окружения TASK_112).
 *
 * Здесь нет ничего, что вызывается до `requestPermission`: «Включить» в компонентах
 * синхронно запускает `subscribeOrderPush`, а отсюда — только то, что идёт после (TASK_99).
 */
import { collectPushEnvironment, sendEnvironmentEvent } from "./pushEnvironment.js"
import { orderStatusCtas } from "./orderStatusCtaMachine.js"

export const PUSH_PREPROMPT_TITLE = "Уведомим, когда заказ будет готов"
export const PUSH_PREPROMPT_TEXT = "Пришлём уведомление, как только бариста его соберёт"
export const PUSH_PREPROMPT_ACCEPT = "Включить"
export const PUSH_PREPROMPT_LATER = "Не сейчас"
export const PUSH_PREPROMPT_PENDING = "Подключаем…"

/** Автопоказ прекращается после стольких «Не сейчас»; по нажатию на 🔔 карточка открывается всегда. */
export const PUSH_PREPROMPT_MAX_DISMISSALS = 3
export const PUSH_PREPROMPT_STORAGE_KEY = "coffeeos_shop_push_preprompt_v1"

/** «Готов» и «Ожидает оплаты» — без карточки (решение владельца 2026-10-29). */
const PREPROMPT_STATUSES = Object.freeze(["accepted", "paid", "preparing"])
const PERMISSIONS = Object.freeze(["default", "granted", "denied"])

export const PUSH_CONSENT_EVENT_KINDS = Object.freeze([
  "push_preprompt_shown",
  "push_preprompt_accept",
  "push_preprompt_later",
  "push_permission_granted",
  "push_permission_denied",
  "push_permission_default"
])

const EMPTY_STATE = Object.freeze({ dismissals: 0, lastDismissedOrderId: null })

/** Если хранилище недоступно — состояние живёт до перезагрузки страницы. */
let memoryState = EMPTY_STATE
let autoClaimOrderId = null

export function __resetPrePromptForTests() {
  memoryState = EMPTY_STATE
  autoClaimOrderId = null
}

function defaultStorage() {
  try {
    return globalThis.localStorage || null
  } catch {
    return null
  }
}

function normalizeState(raw) {
  if (!raw || typeof raw !== "object") return null
  const dismissals = Number.isInteger(raw.dismissals) && raw.dismissals > 0 ? raw.dismissals : 0
  const last = raw.lastDismissedOrderId == null ? null : String(raw.lastDismissedOrderId)
  return { dismissals, lastDismissedOrderId: last }
}

export function isPrePromptStatus(status) {
  return PREPROMPT_STATUSES.includes(String(status || ""))
}

/** Есть ли у заказа push-CTA — тот же расчёт, что у кнопок (машина CTA, параметры те же). */
export function pushCtaVisible(ctaOpts = {}) {
  return orderStatusCtas(ctaOpts).buttons.some((b) => b.kind === "push")
}

/** @returns {{ dismissals: number, lastDismissedOrderId: string|null }} */
export function readPrePromptState(storage = defaultStorage()) {
  try {
    const raw = storage?.getItem(PUSH_PREPROMPT_STORAGE_KEY)
    if (raw) {
      const parsed = normalizeState(JSON.parse(raw))
      if (parsed) return parsed
    }
  } catch {
    /* недоступное или испорченное хранилище — память страницы */
  }
  return { ...memoryState }
}

export function recordPrePromptDismissal(orderId, storage = defaultStorage()) {
  const prev = readPrePromptState(storage)
  const next = {
    dismissals: prev.dismissals + 1,
    lastDismissedOrderId: orderId == null ? null : String(orderId)
  }
  memoryState = next
  try {
    storage?.setItem(PUSH_PREPROMPT_STORAGE_KEY, JSON.stringify(next))
  } catch {
    /* private mode / WebView — остаётся в памяти */
  }
  return { ...next }
}

/**
 * @param {{
 *   status?: string,
 *   pushCtaShown?: boolean,
 *   permission?: string,
 *   subscribed?: boolean,
 *   recovery?: boolean,
 *   orderId?: string|number|null,
 *   state?: { dismissals?: number, lastDismissedOrderId?: string|null }
 * }} opts — `pushCtaShown`: машина показала CTA вида push (учитывает pushPossible, Wallet и подписку)
 */
export function shouldAutoShowPrePrompt(opts = {}) {
  if (!isPrePromptStatus(opts.status)) return false
  if (!opts.pushCtaShown || opts.subscribed || opts.recovery) return false
  if (opts.permission !== "default") return false
  const state = normalizeState(opts.state) || EMPTY_STATE
  if (state.dismissals >= PUSH_PREPROMPT_MAX_DISMISSALS) return false
  return opts.orderId == null || state.lastDismissedOrderId !== String(opts.orderId)
}

/** Стейт у каждой строки панели свой — автопоказ «занимает» одна строка, пока смонтирована. */
export function claimAutoPrePrompt(orderId) {
  const id = orderId == null ? null : String(orderId)
  if (autoClaimOrderId !== null && autoClaimOrderId !== id) return false
  autoClaimOrderId = id
  return true
}

export function releaseAutoPrePrompt(orderId) {
  const id = orderId == null ? null : String(orderId)
  if (autoClaimOrderId === id) autoClaimOrderId = null
}

export function currentNotificationPermission(env = globalThis) {
  try {
    const permission = env.Notification?.permission
    return PERMISSIONS.includes(permission) ? permission : "unavailable"
  } catch {
    return "unavailable"
  }
}

export function permissionEventKind(permission) {
  return PERMISSIONS.includes(permission) ? `push_permission_${permission}` : null
}

/**
 * Событие воронки в таблицу снимков окружения: тот же снимок, без данных гостя.
 * @param {string} kind
 * @param {{ env?: object, beacon?: Function|null, fetchFn?: Function|null, resolveUrl?: (u: string) => string }} [opts]
 * @returns {boolean} true — отправка запущена
 */
export function reportPushConsentEvent(kind, opts = {}) {
  if (!PUSH_CONSENT_EVENT_KINDS.includes(kind)) return false
  try {
    const env = opts.env || globalThis
    const body = JSON.stringify({ ...collectPushEnvironment(env), event_kind: kind })
    sendEnvironmentEvent(body, opts, env)
    return true
  } catch {
    return false
  }
}

/**
 * После ответа системного запроса на «Включить»: событие по итоговому разрешению;
 * закрытое без выбора окно (`dismissed`) считается «Не сейчас».
 */
export function finishPrePromptAccept(result, opts = {}) {
  const { orderId, storage, ...eventOpts } = opts
  const kind = permissionEventKind(currentNotificationPermission(eventOpts.env || globalThis))
  if (kind) reportPushConsentEvent(kind, eventOpts)
  if (result?.error === "dismissed") recordPrePromptDismissal(orderId, storage)
}
