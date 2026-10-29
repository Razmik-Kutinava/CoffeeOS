<script>
  import { onMount } from "svelte"
  import IosInstallSheet from "./IosInstallSheet.svelte"
  import { shopOnline } from "../lib/shopNetwork.js"
  import { installPromptAvailable, promptPwaInstall, reportStandaloneLaunch } from "../lib/shopPwa.js"
  import {
    INSTALL_BANNER_CLOSE_LABEL,
    INSTALL_BANNER_HOW,
    INSTALL_BANNER_INSTALL,
    INSTALL_BANNER_TEXT,
    decideBannerVariant,
    dismissBanner,
    reportBannerShownOnce,
    reportInstallEvent
  } from "../lib/shopInstallBanner.js"
  import { pendingOrderCount } from "../lib/shopOfflineQueue.js"
  import { pendingCartAddCount } from "../lib/shopOfflineCart.js"

  /** TASK_111: "ios" | "android" | null */
  let variant = $state(null)
  let howOpen = $state(false)
  let decideSeq = 0
  let queuedOrders = $state(0)
  let queuedCartAdds = $state(0)

  async function refreshQueue() {
    try {
      queuedOrders = await pendingOrderCount()
      queuedCartAdds = await pendingCartAddCount()
    } catch {
      queuedOrders = 0
      queuedCartAdds = 0
    }
  }

  async function refreshVariant() {
    const seq = ++decideSeq
    let next = null
    try {
      next = await decideBannerVariant({ installable: installPromptAvailable() })
    } catch {
      next = null
    }
    if (seq === decideSeq) variant = next
  }

  $effect(() => {
    if (variant && $shopOnline) reportBannerShownOnce()
  })

  onMount(() => {
    refreshVariant()
    reportStandaloneLaunch()
    const onInstallable = () => {
      refreshVariant()
    }
    const onQueue = () => refreshQueue()
    window.addEventListener("shop:pwa-installable", onInstallable)
    window.addEventListener("shop:offline-order-queued", onQueue)
    window.addEventListener("shop:offline-order-sent", onQueue)
    window.addEventListener("shop:offline-cart-queued", onQueue)
    window.addEventListener("shop:offline-cart-sent", onQueue)
    refreshQueue()
    return () => {
      window.removeEventListener("shop:pwa-installable", onInstallable)
      window.removeEventListener("shop:offline-order-queued", onQueue)
      window.removeEventListener("shop:offline-order-sent", onQueue)
      window.removeEventListener("shop:offline-cart-queued", onQueue)
      window.removeEventListener("shop:offline-cart-sent", onQueue)
    }
  })

  async function install() {
    const pending = promptPwaInstall()
    reportInstallEvent("install_banner_tap")
    let ok = false
    try {
      ok = await pending
    } catch {
      ok = false
    }
    if (!ok) dismissBanner()
    howOpen = false
    variant = null
  }

  function showHow() {
    reportInstallEvent("install_banner_tap")
    howOpen = true
  }

  function closeBanner() {
    reportInstallEvent("install_banner_dismiss")
    dismissBanner()
    howOpen = false
    variant = null
  }
</script>

{#if !$shopOnline}
  <div class="shop-pwa-banner shop-pwa-banner--offline" role="status">
    Нет сети — меню и корзина из кэша. Добавления и заказ отправятся при подключении.
  </div>
{/if}

{#if queuedCartAdds > 0 && $shopOnline}
  <div class="shop-pwa-banner shop-pwa-banner--queue" role="status">
    Синхронизируем корзину ({queuedCartAdds})…
  </div>
{/if}

{#if queuedOrders > 0}
  <div class="shop-pwa-banner shop-pwa-banner--queue" role="status">
    {queuedOrders === 1
      ? "Заказ сохранён и будет отправлен при появлении интернета"
      : `Заказов в очереди: ${queuedOrders}`}
  </div>
{/if}

{#if variant && $shopOnline}
  <div class="shop-pwa-banner shop-pwa-banner--install" data-testid="install-banner" data-variant={variant}>
    <span class="shop-pwa-install-text">{INSTALL_BANNER_TEXT}</span>
    {#if variant === "ios"}
      <button type="button" class="shop-pwa-install-btn" aria-expanded={howOpen} onclick={showHow}>
        {INSTALL_BANNER_HOW}
      </button>
    {:else}
      <button type="button" class="shop-pwa-install-btn" onclick={install}>{INSTALL_BANNER_INSTALL}</button>
    {/if}
    <button type="button" class="shop-pwa-close-btn" aria-label={INSTALL_BANNER_CLOSE_LABEL} onclick={closeBanner}>
      ×
    </button>
    {#if variant === "ios" && howOpen}
      <IosInstallSheet onclose={() => (howOpen = false)} />
    {/if}
  </div>
{/if}

<style>
  .shop-pwa-banner {
    position: fixed;
    top: 3.25rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 40;
    width: min(24rem, calc(100% - 1.5rem));
    padding: 0.5rem 0.75rem;
    border-radius: 10px;
    font-size: 0.8rem;
    line-height: 1.35;
    text-align: center;
    font-family: system-ui, sans-serif;
  }
  .shop-pwa-banner--offline {
    background: #3a2a1a;
    color: #ffcc99;
    border: 1px solid #ff8c42;
  }
  .shop-pwa-banner--queue {
    background: #1f2a3a;
    color: #b8d4ff;
    border: 1px solid #5a8fd4;
  }
  .shop-pwa-banner--install {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.5rem;
    background: #2a2218;
    color: #fff;
    border: 1px solid #ff8c42;
    text-align: left;
  }
  .shop-pwa-install-btn {
    flex-shrink: 0;
    border: none;
    border-radius: 8px;
    padding: 0.35rem 0.65rem;
    background: #ff8c42;
    color: #1a1a1a;
    font-weight: 600;
    font-size: 0.75rem;
    cursor: pointer;
  }
  .shop-pwa-install-text {
    flex: 1;
  }
  .shop-pwa-close-btn {
    flex-shrink: 0;
    border: none;
    background: transparent;
    color: #fff;
    font-size: 1.1rem;
    line-height: 1;
    padding: 0.2rem 0.35rem;
    cursor: pointer;
  }
</style>
