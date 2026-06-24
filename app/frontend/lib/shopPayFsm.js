/** B1.12-R3 — FSM кнопки оплаты (0–7). Фаза 1: State 0 + сброс при смене карты. */

import { PAY_BTN } from "./shopOneClickPay.js"

export const PAY_FSM = {
  DEFAULT: 0,
  CONNECTING: 1,
  PROCESSING: 2,
  THREE_DS: 3,
  SUCCESS: 4,
  CLIENT_ERROR: 5,
  BANK_ERROR: 6,
  NET_ERROR: 7
}

/** Сброс в State 0 (Default) — при смене сохранённой карты. */
export function createState0() {
  return { payState: PAY_BTN.idle, payError: null, fsmState: PAY_FSM.DEFAULT }
}

export function isPayBusy(payState) {
  return (
    payState === PAY_BTN.loading ||
    payState === PAY_BTN.ordering ||
    payState === PAY_BTN.paying ||
    payState === PAY_BTN.awaiting ||
    payState === PAY_BTN.success
  )
}
