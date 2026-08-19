/**
 * Deep link utilities for opening external URLs.
 * Handles native client detection and fallback to web versions.
 */

/**
 * Open a deep link URL in browser.
 * Browser handles platform-specific behavior for https:// URLs:
 * - Mobile with app installed: browser can route to native app via intent handlers
 * - Mobile without app: opens web version in browser
 * - Desktop: opens in new tab with web version
 *
 * Note: This function uses https:// URLs (e.g., https://t.me/bot).
 * The browser's built-in URL handling and OS-level app routing determine
 * whether the native app opens or the web version is used.
 *
 * @param {string} url - URL to open (must be https://, e.g., https://t.me/bot_username)
 * @param {Object} options - Optional configuration
 * @param {string} options.target - Window target ('_blank' | '_self'), default '_blank'
 * @returns {void}
 */
export function openDeepLink(url, options = {}) {
  if (!url) return;

  const target = options.target || "_blank";
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
