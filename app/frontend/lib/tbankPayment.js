const SESSION_KEY = "shop_payment_session"
const INTEGRATION_NAME = "shop-payment"

export const PAYMENT_METHOD_LABELS = {
  card: "Картой",
  sbp: "СБП",
  cash: "Наличные"
}

const SUCCESS_STATUSES = new Set(["CONFIRMED", "AUTHORIZED"])
const FAIL_STATUSES = new Set(["REJECTED", "REVERSED", "CANCELED", "REFUNDED", "PARTIAL_REFUNDED"])

const DEFAULT_SCRIPT_URL = "https://integrationjs.tbank.ru/integration.js"

let initPromise = null
let initTerminalKey = null

export function savePaymentSession(data) {
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(data))
}

export function loadPaymentSession() {
  try {
    const raw = sessionStorage.getItem(SESSION_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export function clearPaymentSession() {
  sessionStorage.removeItem(SESSION_KEY)
}

function loadScript(url) {
  return new Promise((resolve, reject) => {
    if (window.PaymentIntegration) {
      resolve(window.PaymentIntegration)
      return
    }

    const existing = document.querySelector(`script[data-tbank-integration="1"]`)
    if (existing) {
      existing.addEventListener("load", () => resolve(window.PaymentIntegration))
      existing.addEventListener("error", () => reject(new Error("Не удалось загрузить integration.js")))
      return
    }

    const script = document.createElement("script")
    script.src = url || DEFAULT_SCRIPT_URL
    script.async = true
    script.dataset.tbankIntegration = "1"
    script.onload = () => {
      if (window.PaymentIntegration) resolve(window.PaymentIntegration)
      else reject(new Error("PaymentIntegration не найден после загрузки скрипта"))
    }
    script.onerror = () => reject(new Error("Не удалось загрузить integration.js"))
    document.head.appendChild(script)
  })
}

function normalizeStatus(status) {
  return String(status || "").toUpperCase()
}

export function mapTbankStatus(status) {
  const s = normalizeStatus(status)
  if (SUCCESS_STATUSES.has(s)) return "success"
  if (FAIL_STATUSES.has(s)) return "fail"
  if (s === "FORM_SHOWED" || s === "NEW" || s === "AUTHORIZING" || s === "3DS_CHECKING") return "paying"
  return "paying"
}

async function getIntegration(terminalKey, scriptUrl) {
  await loadScript(scriptUrl)

  if (initPromise && initTerminalKey !== terminalKey) {
    initPromise = null
  }

  if (!initPromise) {
    initTerminalKey = terminalKey
    initPromise = window.PaymentIntegration.init({
      terminalKey,
      product: "eacq",
      features: { iframe: {} }
    })
  }

  return initPromise
}

function applyDarkContainer(container) {
  container.classList.add("shop-payment-host")
  container.style.backgroundColor = "#1a1a1a"
  container.style.colorScheme = "dark"
}

/**
 * Официальный API T-Bank: iframe.create + mount(container, PaymentURL).
 * @see https://developer.tbank.ru/eacq/intro/developer/setup_js/setup_iframe
 */
export async function openTbankIframe({ container, terminalKey, paymentUrl, scriptUrl, onStatusChange }) {
  if (!container || !paymentUrl || !terminalKey) {
    throw new Error("Нет контейнера, PaymentURL или terminalKey")
  }

  applyDarkContainer(container)

  const integration = await getIntegration(terminalKey, scriptUrl)

  try {
    await integration.iframe.remove(INTEGRATION_NAME)
  } catch {
    // первая оплата — интеграции ещё нет
  }

  const iframeConfig = {
    status: {
      changedCallback: (status) => {
        onStatusChange?.(mapTbankStatus(status), status)
      }
    },
    deepLinkRedirectCallback: (url) => {
      // 3DS/SBP: полный переход в банк; возврат в PWA — sessionStorage + awaiting_settlement в Payment.svelte
      window.location.href = url
    }
  }

  const iframeIntegration = await integration.iframe.create(INTEGRATION_NAME, iframeConfig)

  if (typeof iframeIntegration.setTheme === "function") {
    try {
      await iframeIntegration.setTheme("dark")
    } catch {
      // SDK без тёмной темы — оболочка CoffeeOS перекрывает
    }
  }

  await iframeIntegration.mount(container, paymentUrl)
  styleMountedIframe(container)

  return iframeIntegration
}

function styleMountedIframe(container) {
  for (const iframe of container.querySelectorAll("iframe")) {
    iframe.classList.add("shop-payment-iframe")
    iframe.style.backgroundColor = "#1a1a1a"
    iframe.style.border = "0"
    iframe.style.width = "100%"
    iframe.style.minHeight = "360px"
    iframe.style.colorScheme = "dark"
  }
}

export function redirectToPaymentUrl(paymentUrl) {
  if (!paymentUrl) return
  window.location.href = paymentUrl
}

/** Запасной путь без integration.js */
export function embedPaymentUrlIframe(container, paymentUrl) {
  if (!container || !paymentUrl) throw new Error("Нет контейнера или URL оплаты")

  applyDarkContainer(container)
  container.replaceChildren()

  const iframe = document.createElement("iframe")
  iframe.src = paymentUrl
  iframe.title = "Безопасная оплата"
  iframe.className = "shop-payment-iframe h-[360px] w-full border-0"
  iframe.style.backgroundColor = "#1a1a1a"
  iframe.style.colorScheme = "dark"
  iframe.setAttribute("allow", "payment")
  container.appendChild(iframe)
  return iframe
}
