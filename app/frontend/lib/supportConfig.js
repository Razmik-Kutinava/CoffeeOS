/**
 * Support contact channels — single source of truth for Telegram URL (#70).
 * Do not hardcode t.me links in Svelte markup.
 */

export const SUPPORT_TELEGRAM_URL = "https://t.me/code_black_support_bot"

export const SUPPORT_CHANNELS = {
  TELEGRAM: {
    name: "Telegram",
    id: "telegram",
    url: SUPPORT_TELEGRAM_URL
  },
  EMAIL: {
    name: "Email",
    id: "email",
    url: null // Email flow not implemented yet; reserved for future
  }
}

export const DEFAULT_SUPPORT_CHANNEL = SUPPORT_CHANNELS.TELEGRAM

/**
 * Get support channel by ID.
 * @param {string} channelId - Channel identifier (telegram | email)
 * @returns {Object | null} Channel config or null if not found
 */
export function getSupportChannel(channelId) {
  if (channelId === SUPPORT_CHANNELS.TELEGRAM.id) return SUPPORT_CHANNELS.TELEGRAM;
  if (channelId === SUPPORT_CHANNELS.EMAIL.id) return SUPPORT_CHANNELS.EMAIL;
  return null;
}

/**
 * Get all available support channels.
 * @returns {Array} Array of channel objects
 */
export function getAvailableSupportChannels() {
  return [SUPPORT_CHANNELS.TELEGRAM, SUPPORT_CHANNELS.EMAIL];
}
