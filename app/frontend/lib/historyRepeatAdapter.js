/**
 * TASK_94: исторический Order ЛК → существующий Quick Repeat / widget one-click.
 * Не дублирует T-Bank stack; multi-item поверх addToCart + POST /orders.
 */
import { addToCart } from "./shopCartAdd.js"
import { loadGuestProfile } from "./shopGuestProfile.js"
import { createWidgetPayFsm } from "./shopWidgetPayFsm.js"
import {
  runRepeatWidgetPayFlow,
  resolveCardDeclineFallbackUi,
  resolveNetworkRetryUi
} from "./widgetRepeatPayFlow.js"
import {
  INLINE_ROTATION_LABELS,
  classifyInlinePayErrorLabel,
  INLINE_NETWORK_ERROR_LABEL
} from "./shopInlinePayFsm.js"
import {
  patchRepeatInlinePayUi,
  resetRepeatInlinePayUi
} from "./repeatInlinePayUiStore.js"
import {
  setTokenInvalid,
  isInvalidRebillPaymentError
} from "./repeatInvalidTokenStore.js"

/**
 * @param {object} order — GET /orders/:id JSON
 * @returns {Array<{ product_id: string, quantity: number, modifier_options: { selected_modifiers: array } }>}
 */
export function historyOrderItemsToRepeatItems(order) {
  const items = Array.isArray(order?.items) ? order.items : []
  return items
    .map((it) => ({
      product_id: it.product_id,
      quantity: Number(it.quantity) > 0 ? Number(it.quantity) : 1,
      modifier_options: {
        selected_modifiers: Array.isArray(it.selected_modifiers)
          ? it.selected_modifiers
          : it.modifier_options?.selected_modifiers || []
      }
    }))
    .filter((it) => it.product_id != null && String(it.product_id).length > 0)
}

/**
 * Новый Order из состава исторического (корзина очищается; historical не PATCH).
 * @param {object} order
 * @param {object} opts
 * @param {(path: string, opts?: object) => Promise<object>} opts.api
 * @param {() => { name?: string, email?: string } | null} [opts.loadProfile]
 * @param {(payload: object) => Promise<object>} [opts.addToCartFn]
 */
export async function createOrderFromHistoryOrder(
  order,
  { api, loadProfile = loadGuestProfile, addToCartFn = addToCart } = {}
) {
  const lines = historyOrderItemsToRepeatItems(order)
  if (!lines.length) {
    throw Object.assign(new Error("Нет позиций для повтора"), { httpStatus: 400 })
  }

  const profile = loadProfile()
  if (!profile?.email || !profile?.name) {
    const err = new Error("Укажите имя и email в профиле")
    err.httpStatus = 422
    err.code = "profile_required"
    throw err
  }

  await api("/cart", { method: "DELETE" })
  for (const line of lines) {
    await addToCartFn({
      product_id: line.product_id,
      quantity: line.quantity,
      selected_modifiers: line.modifier_options.selected_modifiers || []
    })
  }

  const res = await api("/orders", {
    method: "POST",
    body: JSON.stringify({
      name: profile.name,
      email: profile.email,
      payment_method: "card",
      defer_payment_init: true,
      client_order_uuid: crypto.randomUUID()
    })
  })

  const orderId = res?.order_id || res?.id
  if (!orderId) {
    throw Object.assign(new Error("Не удалось создать заказ"), { httpStatus: 500 })
  }
  return { orderId: String(orderId), order: res }
}

function markInvalidTokenFromPay(out) {
  const code = out?.error_code || out?.fsm?.error_code || ""
  const cardId = out?.cardId
  if (cardId && isInvalidRebillPaymentError({ error_code: code })) {
    setTokenInvalid(cardId)
  }
}

/**
 * Оркестрация как RepeatSection.onPayCardClick, источник состава — historical Order.
 * @param {object} opts
 * @param {object} opts.order — полный order JSON (с product_id в items)
 * @param {(path: string, opts?: object) => Promise<object>} opts.api
 * @returns {Promise<object>}
 */
export async function runHistoryRepeatPayFlow({ order, api }) {
  const activeKey = `history:${order?.id || "unknown"}`
  const fsm = createWidgetPayFsm()
  fsm.start()
  patchRepeatInlinePayUi({
    busy: true,
    activeKey,
    fsm,
    statusText: INLINE_ROTATION_LABELS[0],
    errorText: "",
    showFallbackMethods: false,
    showExpandedCards: false,
    showNewCardForm: false,
    savedCards: []
  })

  try {
    const { orderId } = await createOrderFromHistoryOrder(order, { api })
    fsm.orderId = orderId
    const out = await runRepeatWidgetPayFlow({
      orderId,
      api,
      fsm,
      onStatusText: (label) => patchRepeatInlinePayUi({ statusText: label })
    })
    markInvalidTokenFromPay(out)
    patchRepeatInlinePayUi({
      fsm: out.fsm,
      statusText: out.statusText,
      errorText: out.errorText,
      showFallbackMethods: out.showFallbackMethods,
      showRetry: !!out.showRetry,
      showExpandedCards: false,
      showNewCardForm: false,
      savedCards: out.savedCards || []
    })
    if (out.openPaymentSheet) {
      const first = historyOrderItemsToRepeatItems(order)[0]
      if (first) {
        const { openRepeatPaymentSheet } = await import("./openRepeatPaymentSheet.js")
        await openRepeatPaymentSheet(first, { preferNewCard: true })
      }
      return out
    }
    if (out.resetAfterMs) {
      setTimeout(() => resetRepeatInlinePayUi(), out.resetAfterMs)
    }
    return out
  } catch (e) {
    fsm.reject({ error_code: e?.error_code || "" })
    fsm.state = "ERROR"
    const msg = classifyInlinePayErrorLabel({
      error: e,
      error_code: e?.error_code,
      message: e?.message
    })
    const ui =
      msg === INLINE_NETWORK_ERROR_LABEL
        ? resolveNetworkRetryUi()
        : resolveCardDeclineFallbackUi()
    patchRepeatInlinePayUi({
      fsm,
      errorText: msg,
      statusText: msg,
      ...ui
    })
    throw e
  } finally {
    patchRepeatInlinePayUi({ busy: false })
  }
}

/**
 * Profile history row: fetch full order → pay flow.
 * @param {string|number} orderId
 * @param {{ api: Function }} opts
 */
export async function startHistoryRepeatFromOrderId(orderId, { api }) {
  const full = await api(`/orders/${orderId}`)
  return runHistoryRepeatPayFlow({ order: full, api })
}
