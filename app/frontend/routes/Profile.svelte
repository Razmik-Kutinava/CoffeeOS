<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import {
    fetchAccountOrderHistory,
    formatOrderHistoryDate,
    orderHistoryLabel,
    orderHistoryTitle
  } from "../lib/shopAccountOrders.js"
  import PlgBlockSection from "../components/PlgBlockSection.svelte"
  import ContactSupportSheet from "../components/ContactSupportSheet.svelte"
  import PageSkeleton from "../components/PageSkeleton.svelte"
  import { MessageCircle, Settings } from "lucide-svelte"

  useTelegramBack(() => push("/"))

  let user = $state(null)
  let loadingProfile = $state(true)
  let orders = $state([])
  let historyLoading = $state(true)
  let historyError = $state(null)
  let supportSheetOpen = $state(false)

  onMount(async () => {
    try {
      user = await api("profile")
    } catch {
      user = null
    } finally {
      loadingProfile = false
    }

    const result = await fetchAccountOrderHistory()
    orders = result.orders
    historyError = result.errorKind
    historyLoading = false
  })

  function displayName() {
    return user?.name || user?.first_name || "╨У╨╛╤Б╤В╤М"
  }

  function avatarLetter() {
    const n = displayName()
    return (n[0] || "G").toUpperCase()
  }

  function openReceipt(orderId) {
    push(`/order/${orderId}/receipt`)
  }
</script>

<div class="lk-page" data-testid="shop-lk-home">
  <div class="lk-header">
    <button type="button" class="back-btn" onclick={() => push("/")} aria-label="╨Э╨░╨╖╨░╨┤">тА╣</button>
    <div class="lk-user">
      <div class="avatar">{avatarLetter()}</div>
      <div class="name">{displayName()}</div>
    </div>
    <div class="lk-actions">
      <button type="button" class="icon-btn" aria-label="╨Э╨░╨┐╨╕╤Б╨░╤В╤М ╨╜╨░╨╝" onclick={() => (supportSheetOpen = true)}>
        <MessageCircle size={22} />
      </button>
      <button type="button" class="icon-btn" aria-label="╨Э╨░╤Б╤В╤А╨╛╨╣╨║╨╕" onclick={() => push("/profile/settings")}>
        <Settings size={22} />
      </button>
    </div>
  </div>

  <PlgBlockSection />

  <section class="history" data-testid="shop-lk-order-history">
    <h2>╨Ш╤Б╤В╨╛╤А╨╕╤П ╨╖╨░╨║╨░╨╖╨╛╨▓</h2>

    {#if historyLoading}
      <PageSkeleton />
    {:else if historyError}
      <div class="state-error" data-testid="shop-lk-history-error">
        {#if historyError === "network"}
          ╨Э╨╡╤В ╤Б╨▓╤П╨╖╨╕. ╨Я╤А╨╛╨▓╨╡╤А╤М╤В╨╡ ╨╕╨╜╤В╨╡╤А╨╜╨╡╤В ╨╕ ╨┐╨╛╨┐╤А╨╛╨▒╤Г╨╣╤В╨╡ ╨┐╨╛╨╖╨╢╨╡.
        {:else if historyError === "auth"}
          ╨Т╨╛╨╣╨┤╨╕╤В╨╡, ╤З╤В╨╛╨▒╤Л ╨▓╨╕╨┤╨╡╤В╤М ╨╕╤Б╤В╨╛╤А╨╕╤О ╨╖╨░╨║╨░╨╖╨╛╨▓.
        {:else}
          ╨Э╨╡ ╤Г╨┤╨░╨╗╨╛╤Б╤М ╨╖╨░╨│╤А╤Г╨╖╨╕╤В╤М ╨╕╤Б╤В╨╛╤А╨╕╤О. ╨Я╨╛╨┐╤А╨╛╨▒╤Г╨╣╤В╨╡ ╨┐╨╛╨╖╨╢╨╡.
        {/if}
      </div>
    {:else if orders.length === 0}
      <div class="state-empty" data-testid="shop-lk-history-empty">
        <p>╨Ч╨┤╨╡╤Б╤М ╨▒╤Г╨┤╤Г╤В ╨▓╨░╤И╨╕ ╨╖╨░╨║╨░╨╖╤Л</p>
        <button type="button" class="btn" onclick={() => push("/")}>╨б╨┤╨╡╨╗╨░╤В╤М ╨╖╨░╨║╨░╨╖</button>
      </div>
    {:else}
      <div class="history-list">
        {#each orders as order (order.id)}
          <div class="history-row" data-testid="shop-lk-order-row">
            <button type="button" class="history-main" onclick={() => openReceipt(order.id)}>
              <div class="history-top">
                <span class="order-no">тДЦ{orderHistoryLabel(order)}</span>
                <span class="order-date">{formatOrderHistoryDate(order.created_at)}</span>
              </div>
              <div class="order-title">{orderHistoryTitle(order)}</div>
            </button>
            <button type="button" class="repeat-btn" data-testid="shop-lk-repeat-btn" onclick={() => openReceipt(order.id)}>
              ╨┐╨╛╨▓╤В╨╛╤А╨╕╤В╤М
            </button>
          </div>
        {/each}
      </div>
    {/if}
  </section>
</div>

<ContactSupportSheet bind:open={supportSheetOpen} />

<style>
  .lk-page { min-height: 100vh; background: #1a1a1a; color: #fff; padding-bottom: 80px; }
  .lk-header { display: flex; align-items: center; gap: 12px; padding: 16px; background: #2a2a2a; position: sticky; top: 0; z-index: 10; }
  .back-btn { background: none; border: none; color: #ff8c42; font-size: 28px; cursor: pointer; padding: 0; line-height: 1; }
  .lk-user { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
  .avatar { width: 40px; height: 40px; border-radius: 50%; background: #ff8c42; display: flex; align-items: center; justify-content: center; font-weight: 700; flex-shrink: 0; }
  .name { font-size: 18px; font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .lk-actions { display: flex; gap: 4px; }
  .icon-btn { background: none; border: none; color: #fff; padding: 8px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
  .history { padding: 8px 16px 16px; }
  h2 { margin: 0 0 12px; font-size: 16px; font-weight: 700; }
  .history-list { display: flex; flex-direction: column; gap: 8px; }
  .history-row { display: flex; align-items: stretch; gap: 8px; background: #2a2a2a; border-radius: 12px; overflow: hidden; }
  .history-main { flex: 1; background: none; border: none; color: inherit; text-align: left; padding: 14px 12px; cursor: pointer; }
  .history-top { display: flex; justify-content: space-between; gap: 8px; margin-bottom: 4px; }
  .order-no { font-weight: 600; font-size: 14px; }
  .order-date { color: #a0a0a0; font-size: 13px; }
  .order-title { color: #ddd; font-size: 14px; }
  .repeat-btn { align-self: center; margin-right: 10px; padding: 8px 12px; border-radius: 999px; border: 1px solid #ff8c42; background: transparent; color: #ff8c42; font-size: 13px; cursor: pointer; white-space: nowrap; }
  .state-empty, .state-error { text-align: center; padding: 32px 16px; color: #a0a0a0; }
  .btn { margin-top: 12px; background: #ff8c42; color: #fff; border: none; border-radius: 12px; padding: 10px 20px; font-weight: 600; cursor: pointer; }
</style>
