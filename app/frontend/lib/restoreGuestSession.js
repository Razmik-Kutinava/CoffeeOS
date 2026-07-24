import { api } from "./api.js"
import { loadGuestProfile, saveGuestProfile } from "./shopGuestProfile.js"
import { refreshFrequentProducts } from "./frequentRepeatStore.js"
import { silentRefreshSession } from "./silentRefreshSession.js"

/**
 * После F5 / выгрузки PWA: Silent Refresh по refresh_token, иначе email_otp/status.
 * @returns {Promise<{ verified: boolean, email?: string }>}
 */
export async function restoreGuestSession() {
  const silent = await silentRefreshSession()
  if (silent.verified) {
    const profile = loadGuestProfile()
    const email = silent.email || profile?.email
    const name = silent.profile?.name || profile?.name || "Гость"
    if (email) {
      saveGuestProfile({ name, email, emailVerified: true })
      await refreshFrequentProducts(email)
      return { verified: true, email }
    }
    await refreshFrequentProducts()
    return { verified: true }
  }

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
