/** B1.1 — 4 шага ТЗ ↔ Order.status (см. customer_tasks/B1_1_order_status_progress.md) */

export const PROGRESS_STEPS = [
  { id: 1, label: "Принят", icon: "📋" },
  { id: 2, label: "Оплачен", icon: "💳" },
  { id: 3, label: "Готовится", icon: "🍽" },
  { id: 4, label: "Готов", icon: "🔔" }
]

export const ETA_SUBTITLE = "Примерно 8–12 минут"

const CURRENT_INDEX = {
  pending_payment: 0,
  accepted: 1,
  preparing: 2,
  ready: 3,
  issued: 4,
  closed: 4
}

export function orderProgressView(orderOrStatus) {
  const order = typeof orderOrStatus === "object" && orderOrStatus !== null ? orderOrStatus : null
  const status = order?.status ?? orderOrStatus

  if (status === "cancelled") {
    const staff = order?.cancelled_by === "staff"
    const cancelMessage =
      order?.cancel_message ||
      (staff
        ? "Заказ отменён исполнителем. Средства будут возвращены в течение 3 рабочих дней"
        : "Заказ отменён")

    return {
      cancelled: true,
      cancelledByStaff: staff,
      header: "Заказ отменён",
      cancelMessage,
      showProgress: false,
      showEta: false,
      steps: [],
      fillPercent: 0,
      paymentSettled: order?.payment_settled ?? false
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
  const showEta = !terminal && status !== "ready"
  const fillPercent = terminal ? 100 : (activeIndex / (PROGRESS_STEPS.length - 1)) * 100

  return {
    cancelled: false,
    header,
    subtitle: showEta ? ETA_SUBTITLE : null,
    showProgress: true,
    showEta,
    steps,
    fillPercent,
    paymentSettled: status !== "pending_payment"
  }
}
