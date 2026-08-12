/** OTP-допривязка email/phone к текущему профилю (без reload). */
import { api } from "./api.js"

export async function linkEmailToProfile(email, code) {
  return api("profile/link_email", {
    method: "POST",
    body: JSON.stringify({ email: email.trim().toLowerCase(), code: code.trim() })
  })
}

export async function linkPhoneToProfile(phone, code) {
  return api("profile/link_phone", {
    method: "POST",
    body: JSON.stringify({ phone, code: code.trim() })
  })
}

export async function sendEmailOtp(email) {
  return api("/email_otp/send", {
    method: "POST",
    body: JSON.stringify({ email: email.trim().toLowerCase() })
  })
}

export async function sendPhoneOtp(phone, _channel = "sms") {
  return api("/phone_otp/send_sms", {
    method: "POST",
    body: JSON.stringify({ phone })
  })
}

export async function patchProfileNames({ first_name, last_name }) {
  return api("profile", {
    method: "PATCH",
    body: JSON.stringify({ first_name, last_name })
  })
}
