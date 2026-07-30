/**
 * Inline T-Bank payment button FSM (#32).
 * IDLE → PROCESSING (ротация текстов) → SUCCESS | ERROR | TIMEOUT.
 * Poll 1500 мс · ротация 1800 мс · таймаут 15000 мс.
 */

export const TBANK_INLINE_POLL_MS = 1500
export const TBANK_INLINE_ROTATION_MS = 1800
export const TBANK_INLINE_TIMEOUT_MS = 15000
export const TBANK_INLINE_ERROR_RESET_MS = 3000

export const INLINE_FSM_STATES = {
  IDLE: "IDLE",
  PROCESSING: "PROCESSING",
  SUCCESS: "SUCCESS",
  ERROR: "ERROR"
}

/** Фазы PROCESSING (цикл до финального статуса). */
export const INLINE_ROTATION_LABELS = [
  "Ещё чуть-чуть...",
  "Связываемся с банком...",
  "Платеж принимается банком..."
]

export const INLINE_SUCCESS_LABEL = "Оплачено!"
export const INLINE_TIMEOUT_LABEL = "Время ожидания истекло"
export const INLINE_GENERIC_ERROR_LABEL = "Ошибка оплаты, попробуйте снова"
export const INLINE_INSUFFICIENT_FUNDS_LABEL = "Недостаточно средств"

function defaultSleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/**
 * @param {{ status?: string, error_code?: string }} data
 */
export function mapTbankInlineError(data = {}) {
  const code = String(data?.error_code || "").trim()
  if (code === "1051") return INLINE_INSUFFICIENT_FUNDS_LABEL
  return INLINE_GENERIC_ERROR_LABEL
}

/**
 * @param {{ idleLabel?: string }} [opts]
 */
export function createInlinePayFsm(opts = {}) {
  return {
    state: INLINE_FSM_STATES.IDLE,
    label: opts.idleLabel || "Оплатить",
    errorCode: null,

    start() {
      this.state = INLINE_FSM_STATES.PROCESSING
      this.label = INLINE_ROTATION_LABELS[0]
      this.errorCode = null
    },

    setProcessingLabel(text) {
      if (this.state !== INLINE_FSM_STATES.PROCESSING) return
      this.label = text
    },

    confirm() {
      this.state = INLINE_FSM_STATES.SUCCESS
      this.label = INLINE_SUCCESS_LABEL
      this.errorCode = null
    },

    fail(info = {}) {
      this.state = INLINE_FSM_STATES.ERROR
      this.errorCode = info.error_code || null
      this.label =
        info.label ||
        (info.timeout ? INLINE_TIMEOUT_LABEL : mapTbankInlineError(info))
    },

    reset(idleLabel) {
      this.state = INLINE_FSM_STATES.IDLE
      this.label = idleLabel || "Оплатить"
      this.errorCode = null
    }
  }
}

/**
 * Планировщик poll + ротация до CONFIRMED / REJECTED / CANCELED / TIMEOUT.
 *
 * @param {(ctx: { attempt: number, elapsedMs: number }) => Promise<{ status?: string, error_code?: string }>} pollStatusFn
 * @param {{ sleep?: (ms: number) => Promise<void>, onLabelChange?: (label: string) => void }} [opts]
 */
export async function runTbankInlineButtonCycle(pollStatusFn, opts = {}) {
  const sleep = opts.sleep || defaultSleep
  const onLabelChange = opts.onLabelChange

  const pollTimes = []
  const rotationTimes = []
  const rotationLabels = [...INLINE_ROTATION_LABELS]

  let elapsed = 0
  let nextPollAt = TBANK_INLINE_POLL_MS
  let nextRotateAt = TBANK_INLINE_ROTATION_MS
  let labelIndex = 0
  let attempt = 0

  onLabelChange?.(rotationLabels[labelIndex])

  while (true) {
    const upcoming = []
    if (nextPollAt <= TBANK_INLINE_TIMEOUT_MS) upcoming.push(nextPollAt)
    if (nextRotateAt <= TBANK_INLINE_TIMEOUT_MS) upcoming.push(nextRotateAt)

    if (upcoming.length === 0) {
      return {
        kind: "timeout",
        terminalStatus: "TIMEOUT",
        errorLabel: INLINE_TIMEOUT_LABEL,
        errorCode: null,
        pollTimes,
        rotationTimes,
        rotationLabels,
        labelAtTerminal: rotationLabels[labelIndex]
      }
    }

    const nextAt = Math.min(...upcoming)
    await sleep(nextAt - elapsed)
    elapsed = nextAt

    if (elapsed === nextPollAt) {
      attempt += 1
      pollTimes.push(elapsed)
      const data = (await pollStatusFn({ attempt, elapsedMs: elapsed })) || {}
      const status = String(data.status || "").toUpperCase()

      if (status === "CONFIRMED") {
        return {
          kind: "confirmed",
          terminalStatus: "CONFIRMED",
          errorLabel: null,
          errorCode: null,
          pollTimes,
          rotationTimes,
          rotationLabels,
          labelAtTerminal: rotationLabels[labelIndex]
        }
      }

      if (status === "REJECTED" || status === "CANCELED") {
        return {
          kind: status === "REJECTED" ? "rejected" : "canceled",
          terminalStatus: status,
          errorCode: data.error_code != null ? String(data.error_code) : null,
          errorLabel: mapTbankInlineError(data),
          pollTimes,
          rotationTimes,
          rotationLabels,
          labelAtTerminal: rotationLabels[labelIndex]
        }
      }

      nextPollAt += TBANK_INLINE_POLL_MS

      if (elapsed >= TBANK_INLINE_TIMEOUT_MS) {
        return {
          kind: "timeout",
          terminalStatus: "TIMEOUT",
          errorLabel: INLINE_TIMEOUT_LABEL,
          errorCode: null,
          pollTimes,
          rotationTimes,
          rotationLabels,
          labelAtTerminal: rotationLabels[labelIndex]
        }
      }
    }

    if (elapsed === nextRotateAt) {
      rotationTimes.push(elapsed)
      labelIndex = (labelIndex + 1) % rotationLabels.length
      onLabelChange?.(rotationLabels[labelIndex])
      nextRotateAt += TBANK_INLINE_ROTATION_MS
    }
  }
}
