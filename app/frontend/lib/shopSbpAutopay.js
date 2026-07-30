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

export function buildSbpInitBody({ orderId, saveSbpAccount = false }) {
  const body = { order_id: orderId }
  if (saveSbpAccount) body.save_sbp_account = true
  return body
}

export function buildSbpChargeBody({ orderId }) {
  return { order_id: orderId }
}
