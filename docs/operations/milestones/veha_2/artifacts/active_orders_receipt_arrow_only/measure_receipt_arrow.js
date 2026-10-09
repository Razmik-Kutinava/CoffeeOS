// TASK_104 — замер переключателя состава заказа (только стрелка) в статусной шторке.
// Вставляется в страницу витрины через CDP Runtime.evaluate (локальный стенд).
// window.__task104.install(n) — подменяет GET /orders/active на n заказов `preparing`
//   и будит refreshActive через visibilitychange (без ожидания poll 8 с).
// window.__task104.measure() — снимок первой строки: вид кнопки (текст, фон, рамка,
//   размеры), её место относительно блока статуса и строки, aria-expanded, чек,
//   scrollTop экрана / панели / списка.
// Клики и клавиатуру делает реальный ввод браузера, а не вызов .click() из скрипта.
(() => {
  const realFetch = window.__task104?.realFetch || window.fetch.bind(window)

  function order(i) {
    const items = Array.from({ length: 5 }, (_, k) => ({
      name: `Позиция ${i}.${k + 1}`,
      quantity: 1,
      price: 150,
      line_total: 150,
      modifiers: []
    }))
    return {
      id: `t104-${i}`,
      order_number: `202610-U${i}`,
      status: "preparing",
      can_cancel: false,
      payment_settled: true,
      sales_point: { name: "Витрина А" },
      items,
      subtotal: items.length * 150,
      discount: 0,
      total_amount: items.length * 150
    }
  }

  function install(n = 1) {
    const orders = Array.from({ length: n }, (_, i) => order(i + 1))
    window.fetch = (input, init) => {
      const url = typeof input === "string" ? input : input?.url || ""
      if (/\/orders\/active(\?|$)/.test(url)) {
        return Promise.resolve(new Response(JSON.stringify({ orders }), {
          status: 200,
          headers: { "Content-Type": "application/json" }
        }))
      }
      return realFetch(input, init)
    }
    document.dispatchEvent(new Event("visibilitychange"))
    return orders.length
  }

  function rect(el) {
    if (!el) return null
    const r = el.getBoundingClientRect()
    return {
      top: Math.round(r.top),
      bottom: Math.round(r.bottom),
      left: Math.round(r.left),
      right: Math.round(r.right),
      width: Math.round(r.width),
      height: Math.round(r.height)
    }
  }

  function measure(index = 0) {
    const row = document.querySelectorAll("[data-testid='shop-order-status-sheet'] .aoa")[index]
    const cta = row?.querySelector("[data-testid='active-order-receipt-cta']")
    const head = row?.querySelector(".aoa__head")
    const cs = cta ? getComputedStyle(cta) : null
    const list = document.querySelector("[data-oss-scroll-root]")
    const panel = document.querySelector(".oss__panel")
    const receipt = row?.querySelector(".aoa__receipt")
    return {
      cta: cta && {
        text: cta.textContent.replace(/\s+/g, " ").trim(),
        ariaLabel: cta.getAttribute("aria-label"),
        ariaExpanded: cta.getAttribute("aria-expanded"),
        background: cs.backgroundColor,
        borderRadius: cs.borderTopLeftRadius,
        color: cs.color,
        focused: document.activeElement === cta,
        outline: `${cs.outlineStyle} ${cs.outlineWidth}`,
        rect: rect(cta)
      },
      head: rect(head),
      row: rect(row),
      belowHead: Boolean(cta && head && cta.getBoundingClientRect().top >= head.getBoundingClientRect().bottom - 1),
      rightGapPx: cta && row ? Math.round(row.getBoundingClientRect().right - cta.getBoundingClientRect().right) : null,
      receipt: rect(receipt),
      receiptScrollHeight: receipt?.scrollHeight ?? null,
      openReceipts: document.querySelectorAll(".aoa__receipt").length,
      panel: panel && { height: Math.round(panel.getBoundingClientRect().height), scrollTop: panel.scrollTop },
      list: list && { height: Math.round(list.getBoundingClientRect().height), scrollTop: Math.round(list.scrollTop) },
      windowScrollY: Math.round(window.scrollY)
    }
  }

  window.__task104 = { realFetch, install, measure }
  return "ok"
})()
