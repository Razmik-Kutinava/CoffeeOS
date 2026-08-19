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

export async function submitOrderEmail(
  api,
  { orderId, email, marketing_consent }
) {
  if (!orderId) {
    throw new Error("Order ID is required")
  }

  const payload = {
    email: email && email.trim() ? email.trim().toLowerCase() : "",
    marketing_consent: !!marketing_consent
  }

  const response = await api(`/shop/api/orders/${orderId}/email`, {
    method: "POST",
    body: JSON.stringify(payload)
  })

  if (!response || !response.success) {
    throw new Error(response?.error || "Failed to submit email")
  }

  return response
}
