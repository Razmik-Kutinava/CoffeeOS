import { api } from "./api.js"
import { loadGuestProfile, saveGuestProfile } from "./shopGuestProfile.js"
import { refreshFrequentProducts } from "./frequentRepeatStore.js"

/**
 * После F5: если email уже подтверждён в БД — восстановить сессию на сервере
 * (customer_id) и обновить «повторить». OTP заново не просим.
 * @returns {Promise<{ verified: boolean, email?: string }>}
 */
export async function restoreGuestSession() {
  const profile = loadGuestProfile()
  if (!profile?.email) {
    await refreshFrequentProducts()
    return { verified: false }
  }

  try {
    const q = encodeURIComponent(profile.email)
    const status = await api(`/email_otp/status?email=${q}`)
    if (status?.verified && status.email === profile.email) {
      saveGuestProfile({ ...profile, emailVerified: true })
      await refreshFrequentProducts(profile.email)
      return { verified: true, email: status.email }
    }

    if (profile.emailVerified) {
      saveGuestProfile({ ...profile, emailVerified: false })
    }
  } catch (_e) {
    /* сеть / CSRF — не валим витрину */
  }

  await refreshFrequentProducts(profile.email)
  return { verified: false }
}
