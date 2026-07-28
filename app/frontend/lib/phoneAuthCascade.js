/** Каскад OTP: Flash×2 → Messenger → SMS. */

export const FLASH_WAIT_SEC = 20
export const MESSENGER_WAIT_SEC = 30
export const SMS_COOLDOWN_SEC = 60

export const CASCADE_PHASE = Object.freeze({
  FLASH_1: "flash_1",
  FLASH_2: "flash_2",
  MESSENGER: "messenger",
  SMS: "sms"
})

export const FLASH_HINT =
  "Введите последние 4 цифры номера, с которого вам звонят. На звонок отвечать не нужно."

export const RETRY_FLASH_LABEL = "Запросить звонок еще раз"
export const MESSENGER_BTN_LABEL = "Получить код в WhatsApp / Telegram"
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

export function messengerSentHint(phoneDisplay) {
  return `Отправили 4-значный код в мессенджер на номер ${phoneDisplay || ""}`.trim()
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
 * @returns {{ phase: string, secondsLeft: number, lastChannel: string|null, autoSend: string|null }}
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
        phase: CASCADE_PHASE.MESSENGER,
        secondsLeft: 0,
        lastChannel,
        autoSend: "messenger"
      }
    }
    if (phase === CASCADE_PHASE.MESSENGER) {
      return { phase: CASCADE_PHASE.SMS, secondsLeft: 0, lastChannel, autoSend: null }
    }
    return { phase: CASCADE_PHASE.SMS, secondsLeft: 0, lastChannel, autoSend: null }
  }

  return { phase, secondsLeft: 0, lastChannel, autoSend: null }
}

export function showRetryFlashButton(phaseOrRound) {
  // совместимость: число round ≥ 2 или phase FLASH_2
  if (typeof phaseOrRound === "number") return phaseOrRound >= 2
  return phaseOrRound === CASCADE_PHASE.FLASH_2
}

export function showMessengerButton(phase, secondsLeft) {
  return phase === CASCADE_PHASE.MESSENGER && Number(secondsLeft) <= 0
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

export function afterMessengerSend() {
  return {
    phase: CASCADE_PHASE.MESSENGER,
    secondsLeft: MESSENGER_WAIT_SEC,
    lastChannel: "messenger"
  }
}

export function afterSmsSend() {
  return {
    phase: CASCADE_PHASE.SMS,
    secondsLeft: SMS_COOLDOWN_SEC,
    lastChannel: "sms"
  }
}

/** Ошибка доставки мессенджера → сразу SMS. */
export function afterMessengerDeliveryError() {
  return {
    phase: CASCADE_PHASE.SMS,
    secondsLeft: 0,
    lastChannel: null
  }
}

export function cascadeHint({ lastChannel, phoneDisplay }) {
  if (lastChannel === "messenger") return messengerSentHint(phoneDisplay)
  if (lastChannel === "sms") return SMS_SENT_HINT
  return FLASH_HINT
}

export function cascadeTimerLabel({ phase, secondsLeft, lastChannel }) {
  if (phase === CASCADE_PHASE.FLASH_1 || phase === CASCADE_PHASE.FLASH_2) {
    return waitingCallLabel(secondsLeft)
  }
  if (phase === CASCADE_PHASE.MESSENGER && lastChannel === "messenger" && secondsLeft > 0) {
    return `Ждем код в мессенджере... ${formatMmSs(secondsLeft)}`
  }
  if (phase === CASCADE_PHASE.SMS && lastChannel === "sms" && secondsLeft > 0) {
    return `Повтор SMS через ${formatMmSs(secondsLeft)}`
  }
  return ""
}
