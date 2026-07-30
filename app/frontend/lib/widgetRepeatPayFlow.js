/**
 * One-click → widget init → inline status cycle (#32 + #33 RepeatSection).
 */
import { createWidgetPayFsm, WIDGET_FSM_STATES } from "./shopWidgetPayFsm.js"
import { widgetInitPayment, WIDGET_STATUS_LABELS } from "./widgetInlinePay.js"
import {
  INLINE_ROTATION_LABELS,
  INLINE_SUCCESS_LABEL,
  INLINE_GENERIC_ERROR_LABEL,
  TBANK_INLINE_ERROR_RESET_MS,
  runTbankInlineButtonCycle
} from "./shopInlinePayFsm.js"

/**
 * @param {object} opts
 * @param {string} opts.orderId
 * @param {(path: string, opts?: object) => Promise<object>} opts.api
 * @param {(label: string) => void} [opts.onStatusText]
 */
export async function runRepeatWidgetPayFlow({ orderId, api, onStatusText }) {
  const fsm = createWidgetPayFsm({ orderId })
  fsm.start()
  let statusText = INLINE_ROTATION_LABELS[0]
  let errorText = ""
  let showFallbackMethods = false
  let resetAfterMs = null
  onStatusText?.(statusText)

  try {
    await widgetInitPayment(orderId)
    const result = await runTbankInlineButtonCycle(
      async () => {
        try {
          const data = await api(`/payments/status/${orderId}`)
          return {
            status: data?.status,
            error_code: data?.error_code,
            error_message: data?.error_message
          }
        } catch (err) {
          const http = Number(err?.httpStatus || 0)
          if (http >= 400) {
            return { status: "HTTP_ERROR", error_code: String(http) }
          }
          throw err
        }
      },
      {
        onLabelChange: (label) => {
          statusText = label
          onStatusText?.(label)
        }
      }
    )

    if (result.kind === "confirmed") {
      fsm.confirm()
      statusText = INLINE_SUCCESS_LABEL
      onStatusText?.(statusText)
      resetAfterMs = TBANK_INLINE_ERROR_RESET_MS
    } else if (result.kind === "http_error" || result.kind === "timeout") {
      fsm.reject({ error_code: result.errorCode || "" })
      // ТЗ: ERROR — красная плашка, без fallback; reset IDLE через 3 с
      fsm.state = WIDGET_FSM_STATES.ERROR
      errorText = result.errorLabel || INLINE_GENERIC_ERROR_LABEL
      statusText = errorText
      onStatusText?.(statusText)
      showFallbackMethods = false
      resetAfterMs = TBANK_INLINE_ERROR_RESET_MS
    } else {
      // REJECTED/CANCELED: error + fallback СБП/карта+; reset через 3 с
      fsm.reject({ error_code: result.errorCode || "" })
      errorText = result.errorLabel || WIDGET_STATUS_LABELS.ERROR
      statusText = errorText
      onStatusText?.(statusText)
      if (fsm.state !== WIDGET_FSM_STATES.FALLBACK) {
        fsm.state = WIDGET_FSM_STATES.ERROR
      }
      showFallbackMethods = true
      resetAfterMs = TBANK_INLINE_ERROR_RESET_MS
    }
  } catch (_e) {
    fsm.reject({ error_code: "" })
    fsm.state = WIDGET_FSM_STATES.ERROR
    errorText = INLINE_GENERIC_ERROR_LABEL
    statusText = errorText
    onStatusText?.(statusText)
    showFallbackMethods = false
    resetAfterMs = TBANK_INLINE_ERROR_RESET_MS
  }

  return {
    fsm,
    statusText,
    errorText,
    showFallbackMethods,
    resetAfterMs,
    state: fsm.state
  }
}

export { WIDGET_FSM_STATES, INLINE_SUCCESS_LABEL, TBANK_INLINE_ERROR_RESET_MS }
