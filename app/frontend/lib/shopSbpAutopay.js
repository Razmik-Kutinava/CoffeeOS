/**
 * #34 SBP Autopay AccountToken — FSM + helpers (Zero-Click / fallback).
 */
export const SBP_AUTOPAY_STATES = Object.freeze({
  IDLE: "idle",
  LOADING: "loading",
  SUCCESS: "success",
  DECLINED: "declined",
  MANUAL_PAYMENT_REDIRECT: "manual_payment_redirect",
  ERROR: "error"
})

export const SBP_AUTOPAY_TOASTS = Object.freeze({
  SERVICE_UNAVAILABLE: "Сервис временно недоступен",
  CHARGE_DECLINED:
    "Не удалось выполнить быстрый платеж. Пожалуйста, подтвердите оплату вручную",
  CONNECTION_ERROR: "Ошибка соединения, попробуйте еще раз"
})

export function createSbpAutopayFsm({ orderId = null, cartSnapshot = null } = {}) {
  return {
    state: SBP_AUTOPAY_STATES.IDLE,
    orderId,
    cartSnapshot,
    lastError: null,

    startCharge() {
      this.state = SBP_AUTOPAY_STATES.LOADING
      this.lastError = null
    },

    confirm() {
      this.state = SBP_AUTOPAY_STATES.SUCCESS
    },

    decline(payload = {}) {
      this.state = SBP_AUTOPAY_STATES.DECLINED
      this.lastError = payload
    },

    redirectToManual() {
      this.state = SBP_AUTOPAY_STATES.MANUAL_PAYMENT_REDIRECT
    },

    failNetwork(payload = {}) {
      this.state = SBP_AUTOPAY_STATES.ERROR
      this.lastError = payload
    }
  }
}

export function mapSbpAutopayError(status, body = {}) {
  const code = String(body?.error_code || "")
  if (code === "CHARGE_DECLINED") return SBP_AUTOPAY_TOASTS.CHARGE_DECLINED
  if (code === "NETWORK") return SBP_AUTOPAY_TOASTS.CONNECTION_ERROR
  if (status >= 400) return SBP_AUTOPAY_TOASTS.SERVICE_UNAVAILABLE
  return SBP_AUTOPAY_TOASTS.CONNECTION_ERROR
}

/** #62: default for «Привязать счет…» checkbox. */
export const DEFAULT_SAVE_SBP_ACCOUNT = true

/**
 * Resolve checkbox when entering/showing SBP mode in checkout.
 * Untouched → default checked; after user toggle → keep current.
 * @param {{ userTouched?: boolean, current?: boolean }} opts
 */
export function resolveSaveSbpAccountForSbpMode({
  userTouched = false,
  current = DEFAULT_SAVE_SBP_ACCOUNT
} = {}) {
  if (userTouched) return !!current
  return DEFAULT_SAVE_SBP_ACCOUNT
}

export function buildSbpInitBody({ orderId, saveSbpAccount = false }) {
  const body = { order_id: orderId }
  if (saveSbpAccount) body.save_sbp_account = true
  return body
}

export function buildSbpChargeBody({ orderId }) {
  return { order_id: orderId }
}

/**
 * Zero-Click charge. Throws Error with status/body/error_code.
 * @param {(path: string, opts?: object) => Promise<object>} api
 */
export async function chargeSbpAutopay(api, { orderId }) {
  try {
    return await api("/payments/sbp/charge", {
      method: "POST",
      body: buildSbpChargeBody({ orderId })
    })
  } catch (e) {
    const status = e.status ?? e.httpStatus ?? 500
    const body = e.body && typeof e.body === "object"
      ? e.body
      : { error: e.message, error_code: e.error_code }
    if (!body.error_code && e.error_code) body.error_code = e.error_code
    const err = new Error(mapSbpAutopayError(status, body))
    err.status = status
    err.body = body
    err.error_code = body?.error_code || e.error_code
    throw err
  }
}

/**
 * Дефолт выбора метода: при наличии AccountToken — «Ваш счет СБП».
 */
export function pickDefaultPaymentSelection({
  sbpAccounts = [],
  cards = [],
  primary = null,
  persisted = null
} = {}) {
  const hasSbp = Array.isArray(sbpAccounts) && sbpAccounts.length > 0
  if (hasSbp) {
    return { selectionMode: "sbp_account", selectedCardId: null }
  }
  if (persisted?.selectedCardId && cards.some((c) => c.id === persisted.selectedCardId)) {
    return {
      selectionMode: persisted.selectionMode === "new_card" ? "saved_card" : (persisted.selectionMode || "saved_card"),
      selectedCardId: persisted.selectedCardId
    }
  }
  if (primary?.id) return { selectionMode: "saved_card", selectedCardId: primary.id }
  if (cards[0]?.id) return { selectionMode: "saved_card", selectedCardId: cards[0].id }
  return { selectionMode: "sbp", selectedCardId: null }
}
