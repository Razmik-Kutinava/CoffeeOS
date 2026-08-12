/** Стейт-машина phone auth: Callcheck → SMS fallback (без FlashCall /code/call). */

export const CALLCHECK_POLL_MS = 3000
export const CALLCHECK_TIMEOUT_SEC = 40
export const SMS_COOLDOWN_SEC = 60

export const AUTH_PHASE = Object.freeze({
  CALLCHECK: "callcheck",
  SMS: "sms"
})

export const CALLCHECK_HINT =
  "Позвоните на номер ниже с вашего телефона. На звонок отвечать не нужно — сброс автоматический."

export const SMS_BTN_LABEL = "Отправить код в СМС"
export const SMS_SENT_HINT = "Отправили 4-значный код в СМС"

export function formatMmSs(totalSec) {
  const s = Math.max(0, Math.floor(Number(totalSec) || 0))
  const mm = String(Math.floor(s / 60)).padStart(2, "0")
  const ss = String(s % 60).padStart(2, "0")
  return `${mm}:${ss}`
}

export function waitingCallcheckLabel(secondsLeft) {
  return `Ждем ваш звонок... ${formatMmSs(secondsLeft)}`
}

export function smsSentHint(phoneDisplay) {
  return `Отправили 4-значный код в СМС на номер ${phoneDisplay || ""}`.trim()
}

export function initialCallcheckState(payload = {}) {
  return {
    phase: AUTH_PHASE.CALLCHECK,
    secondsLeft: CALLCHECK_TIMEOUT_SEC,
    checkId: payload.check_id || null,
    callPhone: payload.call_phone || null,
    callPhonePretty: payload.call_phone_pretty || null,
    callPhoneHtml: payload.call_phone_html || null,
    lastChannel: null,
    smsSent: false
  }
}

/** Тик 1с на Callcheck. По истечении 40с → SMS phase + autoSend sms. */
export function tickCallcheck(state) {
  const phase = state?.phase || AUTH_PHASE.CALLCHECK
  const left = Math.max(0, Number(state?.secondsLeft) || 0)

  if (phase !== AUTH_PHASE.CALLCHECK) {
    if (phase === AUTH_PHASE.SMS && left > 0) {
      return { ...state, secondsLeft: left - 1, autoSend: null, timedOut: false }
    }
    return { ...state, autoSend: null, timedOut: false }
  }

  if (left > 1) {
    return { ...state, phase, secondsLeft: left - 1, autoSend: null, timedOut: false }
  }

  return {
    ...state,
    phase: AUTH_PHASE.SMS,
    secondsLeft: 0,
    autoSend: "sms",
    timedOut: true
  }
}

export function afterSmsSend(state) {
  return {
    ...state,
    phase: AUTH_PHASE.SMS,
    secondsLeft: SMS_COOLDOWN_SEC,
    lastChannel: "sms",
    smsSent: true,
    autoSend: null
  }
}

export function showSmsPin(phase, smsSent) {
  return phase === AUTH_PHASE.SMS && !!smsSent
}

export function showSmsFallbackButton(phase) {
  return phase === AUTH_PHASE.CALLCHECK || phase === AUTH_PHASE.SMS
}

export function cascadeHint({ phase, lastChannel, phoneDisplay, smsSent }) {
  if (phase === AUTH_PHASE.SMS && (lastChannel === "sms" || smsSent)) {
    return smsSentHint(phoneDisplay)
  }
  return CALLCHECK_HINT
}

export function cascadeTimerLabel({ phase, secondsLeft }) {
  if (phase === AUTH_PHASE.CALLCHECK) return waitingCallcheckLabel(secondsLeft)
  if (phase === AUTH_PHASE.SMS && secondsLeft > 0) {
    return `Повтор SMS через ${formatMmSs(secondsLeft)}`
  }
  return ""
}

/** tel: href из call_phone digits. */
export function telHrefFromCallPhone(callPhone) {
  const digits = String(callPhone || "").replace(/\D/g, "")
  if (!digits) return null
  return `tel:+${digits}`
}
