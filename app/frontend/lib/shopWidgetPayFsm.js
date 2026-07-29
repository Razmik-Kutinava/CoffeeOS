/**
 * Widget T-Kassa One-Click + Fallback FSM (#33).
 *
 * States: IDLE → PROCESSING → SUCCESS | ERROR | FALLBACK
 * FALLBACK триггерится при ошибках карты (1051 и т.п.) — показывает кнопки «СБП» / «карта +».
 */

export const WIDGET_FSM_STATES = {
  IDLE: "IDLE",
  PROCESSING: "PROCESSING",
  SUCCESS: "SUCCESS",
  ERROR: "ERROR",
  FALLBACK: "FALLBACK"
}

const CARD_ERROR_CODES = new Set([
  "1051", // недостаточно средств
  "1005", // отказ эмитента
  "1006", // отклонено, попробуйте позже
  "1012", // недопустимая транзакция
  "1014", // карта недействительна
  "1030", // повторите попытку
  "1034", // подозрение в мошенничестве
  "1041", // утеряна
  "1043", // украдена
  "1054", // истёк срок
  "1057", // не разрешена
  "1058", // не разрешена
  "1059", // подозрение в мошенничестве
  "1062", // ограничение карты
  "1063", // нарушение безопасности
  "1065", // превышен лимит
  "1082", // неверный CVV
  "1089", // ошибка аутентификации
  "1091", // эмитент недоступен
  "1096"  // повторите позже
])

function isCardError(errorCode) {
  return CARD_ERROR_CODES.has(String(errorCode))
}

/**
 * @param {{ orderId?: string }} opts
 */
export function createWidgetPayFsm(opts = {}) {
  return {
    state: WIDGET_FSM_STATES.IDLE,
    orderId: opts.orderId || null,
    errorInfo: null,

    start() {
      this.state = WIDGET_FSM_STATES.PROCESSING
      this.errorInfo = null
    },

    confirm() {
      this.state = WIDGET_FSM_STATES.SUCCESS
    },

    reject(info = {}) {
      this.errorInfo = info
      if (isCardError(info.error_code)) {
        this.state = WIDGET_FSM_STATES.FALLBACK
      } else {
        this.state = WIDGET_FSM_STATES.ERROR
      }
    },

    reset() {
      this.state = WIDGET_FSM_STATES.IDLE
      this.errorInfo = null
    }
  }
}

export function widgetFallbackMethods() {
  return [
    { id: "sbp", label: "СБП" },
    { id: "card_plus", label: "карта +" }
  ]
}
