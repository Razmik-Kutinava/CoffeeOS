import { api } from "./api.js"
import { clearShopRefreshToken, loadShopRefreshToken } from "./shopLocalStorage.js"
import { clearGuestProfile } from "./shopGuestProfile.js"

export async function logoutShopSession() {
  const refresh_token = loadShopRefreshToken()
  try {
    await api("session", {
      method: "DELETE",
      body: JSON.stringify(refresh_token ? { refresh_token } : {})
    })
  } catch {
    /* cookie/session may already be cleared */
  }
  clearShopRefreshToken()
  clearGuestProfile()
}
