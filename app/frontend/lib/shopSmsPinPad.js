/**
 * SMS-пинпад для inline-оплаты (скрин #32): код + таймер 00:59.
 */

export const SMS_PIN_LENGTH = 4
export const SMS_PIN_TIMER_SEC = 59

export function createSmsPinPadState(opts = {}) {
  return {
    code: "",
    secondsLeft: opts.secondsLeft ?? SMS_PIN_TIMER_SEC
  }
}

/** @param {number} sec */
export function formatSmsTimer(sec) {
  const s = Math.max(0, Math.floor(Number(sec) || 0))
  const mm = String(Math.floor(s / 60)).padStart(2, "0")
  const ss = String(s % 60).padStart(2, "0")
  return `${mm}:${ss}`
}

export function appendSmsDigit(state, digit) {
  const d = String(digit).replace(/\D/g, "")
  if (!d || state.code.length >= SMS_PIN_LENGTH) return state
  return { ...state, code: (state.code + d).slice(0, SMS_PIN_LENGTH) }
}

export function backspaceSmsDigit(state) {
  if (!state.code) return state
  return { ...state, code: state.code.slice(0, -1) }
}

export function tickSmsTimer(state) {
  if (state.secondsLeft <= 0) return state
  return { ...state, secondsLeft: state.secondsLeft - 1 }
}

export function resetSmsTimer(state, seconds = SMS_PIN_TIMER_SEC) {
  return { ...state, secondsLeft: seconds, code: "" }
}

export function isSmsCodeComplete(state) {
  return String(state.code || "").length === SMS_PIN_LENGTH
}
