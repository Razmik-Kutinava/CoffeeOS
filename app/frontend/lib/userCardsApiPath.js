/**
 * Путь GET /user/cards с ?email= из guest profile (fallback когда Rails session пуста).
 */
import { loadGuestProfile, isValidEmail } from "./shopGuestProfile.js"

export function userCardsApiPath() {
  const profile = loadGuestProfile()
  const email = profile?.email?.trim().toLowerCase()
  if (email && isValidEmail(email)) {
    return `/user/cards?email=${encodeURIComponent(email)}`
  }
  return "/user/cards"
}
