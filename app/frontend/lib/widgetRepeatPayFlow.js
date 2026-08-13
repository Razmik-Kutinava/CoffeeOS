/**
 * One-click → widget init → inline status cycle (#32 + #33 RepeatSection).
 */
import { createWidgetPayFsm, WIDGET_FSM_STATES } from "./shopWidgetPayFsm.js"
import { widgetInitPayment, WIDGET_STATUS_LABELS } from "./widgetInlinePay.js"
import {
  INLINE_ROTATION_LABELS,
  INLINE_SUCCESS_LABEL,
  INLINE_GENERIC_ERROR_LABEL,
  INLINE_NETWORK_ERROR_LABEL,
  TBANK_INLINE_ERROR_RESET_MS,
  runTbankInlineButtonCycle,
  classifyInlinePayErrorLabel
} from "./shopInlinePayFsm.js"
import { userCardsApiPath } from "./userCardsApiPath.js"

/**
 * S1: отказ карты → только СБП / «карта +» (без expanded / формы).
 * @returns {{ showFallbackMethods: boolean, showExpandedCards: boolean, showNewCardForm: boolean, showRetry: boolean }}
 */
export function resolveCardDeclineFallbackUi() {
  return {
    showFallbackMethods: true,
    showExpandedCards: false,
    showNewCardForm: false,
    showRetry: false
  }
}

/**
 * Сеть / нет связи → CTA «Повторить» (тот же pay flow), без дубля в шторке.
 * @returns {{ showFallbackMethods: boolean, showExpandedCards: boolean, showNewCardForm: boolean, showRetry: boolean, openPaymentSheet: boolean }}
 */
export function resolveNetworkRetryUi() {
  return {
    showFallbackMethods: false,
    showExpandedCards: false,
    showNewCardForm: false,
    showRetry: true,
    openPaymentSheet: false
  }
}

/**
 * S2: тап «карта +» → открыть канон PaymentMethodsSheet (checkout pay-stack),
 * не expanded cards/form внутри peek (клип формы).
 * @returns {{ showFallbackMethods: boolean, showExpandedCards: boolean, showNewCardForm: boolean, openPaymentSheet: boolean, showRetry: boolean }}
 */
export function resolveCardPlusExpandedUi() {
  return {
    showFallbackMethods: true,
    showExpandedCards: false,
    showNewCardForm: false,
    openPaymentSheet: true,
    showRetry: false
  }
}

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
  let showRetry = false
  let openPaymentSheet = false
  let savedCards = []
  let resetAfterMs = null
  let lastErrorCode = ""
  let cardId = forcedCardId
  onStatusText?.(statusText)

  try {
    let cardsData = null
    try {
      cardsData = await api(userCardsApiPath())
      if (!cardId) cardId = cardsData?.primary?.id || cardsData?.cards?.[0]?.id
      savedCards = Array.isArray(cardsData?.cards) ? cardsData.cards : []
    } catch (_e) {
      if (!cardId) cardId = undefined
    }

    // API ответил пустым списком и нет cardId → канон PaymentMethodsSheet (не форма в peek).
    // Если /user/cards упал — всё равно идём в widget_init: бэкенд возьмёт RebillId по order.customer_id.
    if (!cardId && cardsData && savedCards.length === 0) {
      fsm.reject({ error_code: "NO_CARD" })
      fsm.state = WIDGET_FSM_STATES.FALLBACK
      errorText = "Добавьте карту для оплаты"
      statusText = errorText
      onStatusText?.(statusText)
      lastErrorCode = "NO_CARD"
      return {
        fsm,
        statusText,
        errorText,
        ...resolveCardPlusExpandedUi(),
        savedCards: [],
        resetAfterMs: null,
        state: fsm.state,
        cardId: null,
        error_code: lastErrorCode
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
    } else if (result.kind === "timeout") {
      lastErrorCode = result.errorCode || ""
      fsm.reject({ error_code: lastErrorCode })
      fsm.state = WIDGET_FSM_STATES.ERROR
      errorText = INLINE_NETWORK_ERROR_LABEL
      statusText = errorText
      onStatusText?.(statusText)
      ;({ showFallbackMethods, showExpandedCards, showNewCardForm, showRetry } =
        resolveNetworkRetryUi())
    } else if (result.kind === "http_error") {
      lastErrorCode = result.errorCode || ""
      fsm.reject({ error_code: lastErrorCode })
      fsm.state = WIDGET_FSM_STATES.ERROR
      errorText = result.errorLabel || INLINE_GENERIC_ERROR_LABEL
      statusText = errorText
      onStatusText?.(statusText)
      ;({ showFallbackMethods, showExpandedCards, showNewCardForm, showRetry } =
        resolveCardDeclineFallbackUi())
    } else {
      lastErrorCode = result.errorCode || ""
      fsm.reject({ error_code: lastErrorCode })
      errorText =
        classifyInlinePayErrorLabel({ error_code: lastErrorCode }) ||
        result.errorLabel ||
        WIDGET_STATUS_LABELS.ERROR
      statusText = errorText
      onStatusText?.(statusText)
      if (fsm.state !== WIDGET_FSM_STATES.FALLBACK) {
        fsm.state = WIDGET_FSM_STATES.ERROR
      }
      ;({ showFallbackMethods, showExpandedCards, showNewCardForm, showRetry } =
        resolveCardDeclineFallbackUi())
    }
  } catch (e) {
    lastErrorCode = e?.error_code || ""
    fsm.reject({ error_code: lastErrorCode })
    fsm.state = WIDGET_FSM_STATES.ERROR
    errorText = classifyInlinePayErrorLabel({
      error: e,
      error_code: lastErrorCode,
      message: e?.message
    })
    statusText = errorText
    onStatusText?.(statusText)
    if (errorText === INLINE_NETWORK_ERROR_LABEL) {
      ;({ showFallbackMethods, showExpandedCards, showNewCardForm, showRetry } =
        resolveNetworkRetryUi())
    } else {
      // S1: ошибка на основном экране + СБП/«карта +»; S2 → PaymentMethodsSheet.
      ;({ showFallbackMethods, showExpandedCards, showNewCardForm, showRetry } =
        resolveCardDeclineFallbackUi())
    }
  }

  return {
    fsm,
    statusText,
    errorText,
    showFallbackMethods,
    showExpandedCards,
    showNewCardForm,
    showRetry,
    openPaymentSheet,
    savedCards,
    resetAfterMs,
    state: fsm.state,
    cardId: cardId || null,
    error_code: lastErrorCode
  }
}

export { WIDGET_FSM_STATES, INLINE_SUCCESS_LABEL, TBANK_INLINE_ERROR_RESET_MS }
