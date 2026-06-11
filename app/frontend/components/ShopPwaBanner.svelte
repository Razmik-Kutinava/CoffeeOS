<script>
  import { onMount } from "svelte"
  import { shopOnline } from "../lib/shopNetwork.js"
  import { installPromptAvailable, promptPwaInstall } from "../lib/shopPwa.js"
  import { pendingOrderCount } from "../lib/shopOfflineQueue.js"

  let installable = $state(false)
  let queuedOrders = $state(0)

  async function refreshQueue() {
    try {
      queuedOrders = await pendingOrderCount()
    } catch {
      queuedOrders = 0
    }
  }

  onMount(() => {
    installable = installPromptAvailable()
    const onInstallable = () => {
      installable = true
    }
    const onQueue = () => refreshQueue()
    window.addEventListener("shop:pwa-installable", onInstallable)
    window.addEventListener("shop:offline-order-queued", onQueue)
    window.addEventListener("shop:offline-order-sent", onQueue)
    refreshQueue()
    return () => {
      window.removeEventListener("shop:pwa-installable", onInstallable)
      window.removeEventListener("shop:offline-order-queued", onQueue)
      window.removeEventListener("shop:offline-order-sent", onQueue)
    }
  })

  async function install() {
    const ok = await promptPwaInstall()
    if (ok) installable = false
  }
</script>

{#if !$shopOnline}
  <div class="shop-pwa-banner shop-pwa-banner--offline" role="status">
    Нет сети — показываем сохранённое меню. Оплата отправится при подключении.
  </div>
{/if}

{#if queuedOrders > 0}
  <div class="shop-pwa-banner shop-pwa-banner--queue" role="status">
    {queuedOrders === 1
      ? "Заказ сохранён и будет отправлен при появлении интернета"
      : `Заказов в очереди: ${queuedOrders}`}
  </div>
{/if}

{#if installable && $shopOnline}
  <div class="shop-pwa-banner shop-pwa-banner--install">
    <span>Установить CoffeeOS на главный экран</span>
    <button type="button" class="shop-pwa-install-btn" onclick={install}>Установить</button>
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
</style>
