/** B1.1 — 4 шага ТЗ ↔ Order.status (см. customer_tasks/B1_1_order_status_progress.md) */

export const PROGRESS_STEPS = [
  { id: 1, label: "Принят", icon: "📋" },
  { id: 2, label: "Оплачен", icon: "💳" },
  { id: 3, label: "Готовится", icon: "☕" },
  { id: 4, label: "Готов", icon: "🛍️" }
]

const CURRENT_INDEX = {
  pending_payment: 0,
  accepted: 1,
  preparing: 2,
  ready: 3,
  issued: 4,
  closed: 4
}

export function orderProgressView(status) {
  if (status === "cancelled") {
    return {
      cancelled: true,
      header: "Заказ отменён",
      showProgress: false,
      showEta: false,
      steps: [],
      fillPercent: 0
    }
  }

  const terminal = status === "issued" || status === "closed"
  const currentIndex = CURRENT_INDEX[status] ?? 0
  const activeIndex = terminal ? 3 : currentIndex

  const steps = PROGRESS_STEPS.map((step, index) => {
    let state = "upcoming"
    if (terminal || index < activeIndex) state = "done"
    else if (index === activeIndex) state = "current"
    return { ...step, state }
  })

  const header = terminal ? "Готов" : PROGRESS_STEPS[activeIndex].label
  const fillPercent = terminal ? 100 : (activeIndex / (PROGRESS_STEPS.length - 1)) * 100

  return {
    cancelled: false,
    header,
    showProgress: true,
    showEta: !terminal && status !== "ready",
    steps,
    fillPercent,
    paymentSettled: status !== "pending_payment"
  }
}
