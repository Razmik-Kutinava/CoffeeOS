/**
 * One-click → widget init → inline status cycle (#32 + #33 RepeatSection).
 */
import { createWidgetPayFsm, WIDGET_FSM_STATES } from "./shopWidgetPayFsm.js"
import { widgetInitPayment, WIDGET_STATUS_LABELS } from "./widgetInlinePay.js"
import {
  INLINE_ROTATION_LABELS,
  INLINE_SUCCESS_LABEL,
  runTbankInlineButtonCycle
} from "./shopInlinePayFsm.js"

/**
 * @param {object} opts
 * @param {string} opts.orderId
 * @param {(path: string, opts?: object) => Promise<object>} opts.api
 * @param {(label: string) => void} opts.onStatusText
 * @returns {Promise<{
 *   fsm: ReturnType<typeof createWidgetPayFsm>,
 *   statusText: string,
 *   errorText: string,
 *   showFallbackMethods: boolean
 * }>}
 */
export async function runRepeatWidgetPayFlow({ orderId, api, onStatusText }) {
  const fsm = createWidgetPayFsm({ orderId })
  fsm.start()
  let statusText = INLINE_ROTATION_LABELS[0]
  let errorText = ""
  let showFallbackMethods = false
  onStatusText?.(statusText)

  try {
    await widgetInitPayment(orderId)
    const result = await runTbankInlineButtonCycle(
      async () => {
        const data = await api(`/payments/status/${orderId}`)
        return {
          status: data?.status,
          error_code: data?.error_code,
          error_message: data?.error_message
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
    } else {
      fsm.reject({ error_code: result.errorCode || "" })
      errorText = result.errorLabel || WIDGET_STATUS_LABELS.ERROR
      showFallbackMethods = true
    }
  } catch (_e) {
    fsm.reject({ error_code: "" })
    errorText = WIDGET_STATUS_LABELS.ERROR
    showFallbackMethods = true
  }

  return { fsm, statusText, errorText, showFallbackMethods, state: fsm.state }
}

export { WIDGET_FSM_STATES, INLINE_SUCCESS_LABEL }
