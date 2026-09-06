export function isValidEmailFormat(email) {
  if (!email || typeof email !== "string") return false
  const trimmed = email.trim()
  if (trimmed === "") return true // empty is valid (optional)
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(trimmed)
}

export function getEmailValidationError(email) {
  if (!email || email.trim() === "") {
    return "" // empty is OK (optional field)
  }
  if (!isValidEmailFormat(email)) {
    return "Некорректный email"
  }
  return ""
}

/** true = показать блок «Куда прислать чек»; false = email уже запомнен. */
export function shouldAskReceiptEmail(savedEmail) {
  return !String(savedEmail || "").trim()
}

export async function submitOrderEmail(
  api,
  { orderId, email, marketing_consent, reconnect_token }
) {
  if (!orderId) {
    throw new Error("Order ID is required")
  }

  const payload = {
    email: email && email.trim() ? email.trim().toLowerCase() : "",
    marketing_consent: !!marketing_consent
  }
  if (reconnect_token) {
    payload.reconnect_token = reconnect_token
  }

  const response = await api(`/orders/${orderId}/email`, {
    method: "POST",
    body: JSON.stringify(payload)
  })

  if (!response || !response.success) {
    throw new Error(response?.error || "Failed to submit email")
  }

  return response
}
