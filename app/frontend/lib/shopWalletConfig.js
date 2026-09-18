/** Apple Wallet CTA: meta from Shop::AppleWallet::Config.available? */
export function shopWalletAvailable() {
  if (typeof document === "undefined") return false
  const el = document.querySelector('meta[name="shop-wallet-available"]')
  return el?.getAttribute("content") === "true"
}
