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
import { userCardsApiPath } from "./userCardsApiPath.js"

/**
 * @param {object} opts
 * @param {string} opts.orderId
 * @param {(path: string, opts?: object) => Promise<object>} opts.api
 * @param {ReturnType<typeof createWidgetPayFsm>} [opts.fsm] — уже в PROCESSING с UI
 * @param {(label: string) => void} [opts.onStatusText]
 * @param {string} [opts.cardId] — явный выбор сохранённой карты
 */
export async function runRepeatWidgetPayFlow({
  orderId,
  api,
  fsm: existingFsm,
  onStatusText,
  cardId: forcedCardId
}) {
  const fsm = existingFsm || createWidgetPayFsm({ orderId })
  fsm.orderId = orderId
  if (fsm.state !== WIDGET_FSM_STATES.PROCESSING) fsm.start()

  let statusText = INLINE_ROTATION_LABELS[0]
  let errorText = ""
  let showFallbackMethods = false
  let showExpandedCards = false
  let showNewCardForm = false
  let savedCards = []
  let resetAfterMs = null
  onStatusText?.(statusText)

  try {
    let cardId = forcedCardId
    let cardsData = null
    try {
      cardsData = await api(userCardsApiPath())
      if (!cardId) cardId = cardsData?.primary?.id || cardsData?.cards?.[0]?.id
      savedCards = Array.isArray(cardsData?.cards) ? cardsData.cards : []
    } catch (_e) {
      if (!cardId) cardId = undefined
    }

    // API ответил пустым списком и нет cardId → форма привязки (не Widget-poll вхолостую).
    // Если /user/cards упал — всё равно идём в widget_init: бэкенд возьмёт RebillId по order.customer_id.
    if (!cardId && cardsData && savedCards.length === 0) {
      fsm.reject({ error_code: "NO_CARD" })
      fsm.state = WIDGET_FSM_STATES.FALLBACK
      errorText = "Добавьте карту для оплаты"
      statusText = errorText
      onStatusText?.(statusText)
      return {
        fsm,
        statusText,
        errorText,
        showFallbackMethods: true,
        showExpandedCards: true,
        showNewCardForm: true,
        savedCards: [],
        resetAfterMs: null,
        state: fsm.state
      }
    }

    await widgetInitPayment(orderId, { cardId })
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
      fsm.state = WIDGET_FSM_STATES.ERROR
      errorText = result.errorLabel || INLINE_GENERIC_ERROR_LABEL
      statusText = errorText
      onStatusText?.(statusText)
      showFallbackMethods = true
      // fallback СБП/карта+ не сбрасываем — пользователь должен успеть нажать
    } else {
      fsm.reject({ error_code: result.errorCode || "" })
      errorText = result.errorLabel || WIDGET_STATUS_LABELS.ERROR
      statusText = errorText
      onStatusText?.(statusText)
      if (fsm.state !== WIDGET_FSM_STATES.FALLBACK) {
        fsm.state = WIDGET_FSM_STATES.ERROR
      }
      showFallbackMethods = true
    }
  } catch (e) {
    fsm.reject({ error_code: e?.error_code || "" })
    fsm.state = WIDGET_FSM_STATES.ERROR
    errorText =
      (typeof e?.message === "string" && e.message && e.message !== "Payment provider error"
        ? e.message
        : null) || INLINE_GENERIC_ERROR_LABEL
    statusText = errorText
    onStatusText?.(statusText)
    showFallbackMethods = true
    // при ошибке Charge / недоступности — дать выбрать карту или привязать новую
    showExpandedCards = true
    showNewCardForm = savedCards.length === 0
  }

  return {
    fsm,
    statusText,
    errorText,
    showFallbackMethods,
    showExpandedCards,
    showNewCardForm,
    savedCards,
    resetAfterMs,
    state: fsm.state
  }
}

export { WIDGET_FSM_STATES, INLINE_SUCCESS_LABEL, TBANK_INLINE_ERROR_RESET_MS }
