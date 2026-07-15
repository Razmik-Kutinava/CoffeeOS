/** RSA-2048 PKCS#1 шифрование CardData (Т-Банк nonPCI). Шаг 2. */

import JSEncrypt from "jsencrypt"
import { buildCardDataString, expDateForCardData, digitsOnly } from "./tbankCardFormat.js"

export function encryptCardDataString(plain, publicKeyPem) {
  const key = String(publicKeyPem || "").trim()
  if (!key) throw new Error("Ключ шифрования карты не настроен")

  const enc = new JSEncrypt()
  enc.setPublicKey(key)
  const encrypted = enc.encrypt(plain)
  if (!encrypted) throw new Error("Не удалось зашифровать данные карты")
  return encrypted
}

/**
 * Собирает и шифрует CardData. В сеть уходит только ciphertext —
 * открытый PAN/CVV в возвращаемом значении отсутствуют.
 */
export function encryptCardPayload({ pan, expDate, cvv, cardHolder }, publicKeyPem) {
  const exp = expDate.length === 4 && /^\d{4}$/.test(expDate)
    ? expDate
    : expDateForCardData(expDate)
  if (!exp) throw new Error("Некорректный срок карты")

  const plain = buildCardDataString({
    pan: digitsOnly(pan),
    expDate: exp,
    cvv,
    cardHolder
  })
  return encryptCardDataString(plain, publicKeyPem)
}

/** 3DS: POST на ACS банка (PaReq + MD) — в iframe overlay. */
export const THREE_DS_FRAME_NAME = "coffeeos-three-ds-frame"

export function submitThreeDsChallenge(threeDs, { target = THREE_DS_FRAME_NAME } = {}) {
  const acsUrl = threeDs?.acs_url
  const paReq = threeDs?.pa_req
  const md = threeDs?.md
  if (!acsUrl || !paReq) throw new Error("Неполные данные 3-D Secure")

  const form = document.createElement("form")
  form.method = "POST"
  form.action = acsUrl
  form.target = target
  form.style.display = "none"

  const add = (name, value) => {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    form.appendChild(input)
  }

  add("PaReq", paReq)
  if (md) add("MD", md)
  add("TermUrl", window.location.href)

  document.body.appendChild(form)
  form.submit()
  form.remove()
}
