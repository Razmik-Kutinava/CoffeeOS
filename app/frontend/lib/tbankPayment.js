const SESSION_KEY = "shop_payment_session"

const SUCCESS_STATUSES = new Set(["CONFIRMED", "AUTHORIZED"])
const FAIL_STATUSES = new Set(["REJECTED", "REVERSED", "CANCELED", "REFUNDED", "PARTIAL_REFUNDED"])

const DEFAULT_SCRIPT_URL = "https://integrationjs.t-static.ru/integration.js"

let integrationPromise = null

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

export async function openTbankIframe({ container, terminalKey, paymentId, scriptUrl, onStatusChange }) {
  const PaymentIntegration = await loadScript(scriptUrl)

  if (!integrationPromise) {
    integrationPromise = PaymentIntegration.init({
      terminalKey,
      product: "eacq",
      features: {
        iframe: {
          config: {
            status: {
              changedCallback: (status) => {
                onStatusChange?.(mapTbankStatus(status), status)
              }
            },
            deepLinkRedirectCallback: (url) => {
              window.location.href = url
            }
          }
        }
      }
    })
  }

  const integration = await integrationPromise
  const iframeIntegration = await integration.iframe.get("main-integration")
  await iframeIntegration.connect(container, { paymentId: String(paymentId) })
  return iframeIntegration
}

export function redirectToPaymentUrl(paymentUrl) {
  if (!paymentUrl) return
  window.location.href = paymentUrl
}
