/** Каскад OTP: Flash×2 → SMS (без Messenger). */

export const FLASH_WAIT_SEC = 20
export const SMS_COOLDOWN_SEC = 60

export const CASCADE_PHASE = Object.freeze({
  FLASH_1: "flash_1",
  FLASH_2: "flash_2",
  SMS: "sms"
})

export const FLASH_HINT =
  "Введите последние 4 цифры номера, с которого вам звонят. На звонок отвечать не нужно."

export const RETRY_FLASH_LABEL = "Запросить звонок еще раз"
export const SMS_BTN_LABEL = "Отправить код в СМС"
export const SMS_SENT_HINT = "Отправили 4-значный код в СМС"

export function formatMmSs(totalSec) {
  const s = Math.max(0, Math.floor(Number(totalSec) || 0))
  const mm = String(Math.floor(s / 60)).padStart(2, "0")
  const ss = String(s % 60).padStart(2, "0")
  return `${mm}:${ss}`
}

export function waitingCallLabel(secondsLeft) {
  return `Ждем звонок... ${formatMmSs(secondsLeft)}`
}

export function smsSentHint(phoneDisplay) {
  return `Отправили 4-значный код в СМС на номер ${phoneDisplay || ""}`.trim()
}

export function initialFlashCascade() {
  return {
    phase: CASCADE_PHASE.FLASH_1,
    secondsLeft: FLASH_WAIT_SEC,
    lastChannel: null
  }
}

/**
 * Тик каскада (1с).
 * Flash #1 (20с) → Flash #2 (20с) → SMS
 */
export function tickFlashCascade(state) {
  const phase = state?.phase || CASCADE_PHASE.FLASH_1
  const left = Math.max(0, Number(state?.secondsLeft) || 0)
  const lastChannel = state?.lastChannel ?? null

  if (left > 1) {
    return { phase, secondsLeft: left - 1, lastChannel, autoSend: null }
  }

  if (left === 1) {
    if (phase === CASCADE_PHASE.FLASH_1) {
      return {
        phase: CASCADE_PHASE.FLASH_2,
        secondsLeft: FLASH_WAIT_SEC,
        lastChannel,
        autoSend: "flash_call"
      }
    }
    if (phase === CASCADE_PHASE.FLASH_2) {
      return {
        phase: CASCADE_PHASE.SMS,
        secondsLeft: 0,
        lastChannel,
        autoSend: "sms"
      }
    }
    return { phase: CASCADE_PHASE.SMS, secondsLeft: 0, lastChannel, autoSend: null }
  }

  return { phase, secondsLeft: 0, lastChannel, autoSend: null }
}

export function showRetryFlashButton(phaseOrRound) {
  if (typeof phaseOrRound === "number") return phaseOrRound >= 2
  return phaseOrRound === CASCADE_PHASE.FLASH_2
}

export function showSmsButton(phase) {
  return phase === CASCADE_PHASE.SMS
}

export function afterManualFlashResend(_flashRound) {
  return {
    phase: CASCADE_PHASE.FLASH_2,
    secondsLeft: FLASH_WAIT_SEC,
    lastChannel: "flash_call"
  }
}

export function afterSmsSend() {
  return {
    phase: CASCADE_PHASE.SMS,
    secondsLeft: SMS_COOLDOWN_SEC,
    lastChannel: "sms"
  }
}

export function cascadeHint({ lastChannel, phoneDisplay }) {
  if (lastChannel === "sms") return smsSentHint(phoneDisplay)
  return FLASH_HINT
}

export function cascadeTimerLabel({ phase, secondsLeft, lastChannel }) {
  if (phase === CASCADE_PHASE.FLASH_1 || phase === CASCADE_PHASE.FLASH_2) {
    return waitingCallLabel(secondsLeft)
  }
  if (phase === CASCADE_PHASE.SMS && lastChannel === "sms" && secondsLeft > 0) {
    return `Повтор SMS через ${formatMmSs(secondsLeft)}`
  }
  return ""
}
