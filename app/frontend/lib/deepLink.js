/**
 * Deep link utilities for opening external URLs.
 * Handles native client detection and fallback to web versions.
 */

/**
 * Open a deep link URL, respecting platform-specific behavior.
 * On mobile with native app installed: opens native app
 * On mobile without native app: opens web version
 * On desktop: opens in new tab
 *
 * @param {string} url - URL to open (e.g., https://t.me/bot_username)
 * @param {Object} options - Optional configuration
 * @param {string} options.target - Window target ('_blank' | '_self'), default '_blank'
 * @returns {void}
 */
export function openDeepLink(url, options = {}) {
  if (!url) return;

  const target = options.target || "_blank";

  // Browser's standard window.open handles platform-specific behavior:
  // - On iOS with Telegram app: iOS recognizes tg:// and routes to native app
  // - On Android with Telegram app: Android recognizes tg:// and routes to native app
  // - Fallback: web.telegram.org opens in browser
  // - Desktop: opens new tab with web version
  window.open(url, target);
}

/**
 * Check if a URL is a valid deep link (has protocol/scheme).
 * @param {string} url - URL to validate
 * @returns {boolean}
 */
export function isValidDeepLink(url) {
  try {
    const parsedUrl = new URL(url);
    return Boolean(parsedUrl.protocol && parsedUrl.hostname);
  } catch {
    return false;
  }
}

/**
 * Remove all query parameters from a URL (keep only protocol, hostname, pathname).
 * Ensures no user data is passed through deep links.
 * @param {string} url - URL to clean
 * @returns {string} Cleaned URL without query params
 */
export function cleanDeepLinkUrl(url) {
  try {
    const parsed = new URL(url);
    // Remove all search params
    parsed.search = "";
    parsed.hash = "";
    return parsed.toString();
  } catch {
    return url;
  }
}
