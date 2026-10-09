// TASK_103 — замер прокрутки списка активных заказов в статусной шторке.
// Вставляется в страницу витрины через CDP Runtime.evaluate (локальный стенд).
// window.__task103.install(n, { longReceipt }) — подменяет GET /orders/active на n заказов
//   и будит refreshActive через visibilitychange (без ожидания poll 8 с).
// window.__task103.measure() — снимок: высоты/scrollTop панели, списка, окна, CartSheet;
//   какие строки видны внутри клипа панели.
// Прокрутку делает реальный ввод (wheel/скролл браузера), а не запись scrollTop.
(() => {
  const realFetch = window.__task103?.realFetch || window.fetch.bind(window)

  function order(i, longReceipt) {
    const items = Array.from({ length: longReceipt ? 8 : 2 }, (_, k) => ({
      name: `Позиция ${i}.${k + 1}`,
      quantity: 1,
      price: 150,
      line_total: 150,
      modifiers: k === 0 ? [{ name: "Овсяное молоко", price: 40 }] : []
    }))
    return {
      id: `t103-${i}`,
      order_number: `202610-T${i}`,
      status: "preparing",
      can_cancel: false,
      payment_settled: true,
      sales_point: { name: "Витрина А" },
      items,
      subtotal: items.length * 150 + 40,
      discount: 0,
      total_amount: items.length * 150 + 40
    }
  }

  function install(n, opts = {}) {
    const orders = Array.from({ length: n }, (_, i) => order(i + 1, !!opts.longReceipt))
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

  function box(el) {
    if (!el) return null
    const r = el.getBoundingClientRect()
    const cs = getComputedStyle(el)
    return {
      top: Math.round(r.top),
      bottom: Math.round(r.bottom),
      height: Math.round(r.height),
      scrollTop: Math.round(el.scrollTop),
      scrollHeight: el.scrollHeight,
      clientHeight: el.clientHeight,
      overflowY: cs.overflowY,
      className: el.className
    }
  }

  function measure() {
    const panel = document.querySelector(".oss__panel")
    const list = document.querySelector("[data-oss-scroll-root]")
    const sheet = document.querySelector("[data-testid='shop-order-status-sheet']")
    const cart = sheet?.closest("[data-testid='shop-cart-sheet']") || sheet?.parentElement
    const clip = panel?.getBoundingClientRect()
    const rows = [...document.querySelectorAll("[data-testid='shop-order-status-sheet'] .aoa")]
      .map((row) => {
        const r = row.getBoundingClientRect()
        const visiblePx = clip
          ? Math.max(0, Math.min(r.bottom, clip.bottom) - Math.max(r.top, clip.top))
          : 0
        return { top: Math.round(r.top), bottom: Math.round(r.bottom), visiblePx: Math.round(visiblePx) }
      })
    const receipt = document.querySelector(".aoa__receipt")
    return {
      mode: sheet?.dataset.statusSheetMode || null,
      panel: box(panel),
      list: box(list),
      cart: box(cart),
      receipt: box(receipt),
      openReceipts: document.querySelectorAll(".aoa__receipt").length,
      windowScrollY: Math.round(window.scrollY),
      documentScrollTop: Math.round(document.scrollingElement?.scrollTop || 0),
      rows
    }
  }

  window.__task103 = { realFetch, install, measure }
  return "ok"
})()
