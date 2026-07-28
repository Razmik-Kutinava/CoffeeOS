/** Каскад Flash Call #1 / #2 (тайминги 20с + 20с). */

export const FLASH_WAIT_SEC = 20

export const FLASH_HINT =
  "Введите последние 4 цифры номера, с которого вам звонят. На звонок отвечать не нужно."

export const RETRY_FLASH_LABEL = "Запросить звонок еще раз"

export function formatMmSs(totalSec) {
  const s = Math.max(0, Math.floor(Number(totalSec) || 0))
  const mm = String(Math.floor(s / 60)).padStart(2, "0")
  const ss = String(s % 60).padStart(2, "0")
  return `${mm}:${ss}`
}

export function waitingCallLabel(secondsLeft) {
  return `Ждем звонок... ${formatMmSs(secondsLeft)}`
}

/** Состояние после первого send на Экран 2. */
export function initialFlashCascade() {
  return { flashRound: 1, secondsLeft: FLASH_WAIT_SEC }
}

/**
 * Тик каскада Flash (раз в секунду).
 * @returns {{ flashRound: number, secondsLeft: number, autoResend: boolean }}
 */
export function tickFlashCascade({ flashRound, secondsLeft }) {
  const round = Number(flashRound) || 1
  const left = Math.max(0, Number(secondsLeft) || 0)

  if (left > 1) {
    return { flashRound: round, secondsLeft: left - 1, autoResend: false }
  }

  if (left === 1) {
    if (round === 1) {
      // конец Flash #1 → авто Flash #2 + новый таймер 20с
      return { flashRound: 2, secondsLeft: FLASH_WAIT_SEC, autoResend: true }
    }
    return { flashRound: round, secondsLeft: 0, autoResend: false }
  }

  return { flashRound: round, secondsLeft: 0, autoResend: false }
}

/** Кнопка retry с фазы Flash #2 (с ~20-й секунды). */
export function showRetryFlashButton(flashRound) {
  return Number(flashRound) >= 2
}

/** После ручного/авто retry — ждём ещё 20с на round ≥ 2. */
export function afterManualFlashResend(flashRound) {
  return {
    flashRound: Math.max(2, Number(flashRound) || 2),
    secondsLeft: FLASH_WAIT_SEC
  }
}
