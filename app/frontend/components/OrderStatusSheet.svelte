<script>
  /** #35 sticky peek статуса; pointer-events: каталог не блокируется. */
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { orderProgressView } from "../lib/orderStatusProgress.js"
  import {
    createOrderStatusSheetState,
    shouldScrollStatusList,
    applyCableEvent,
    applyReconnectOrders,
    mapReconnectError,
    ORDER_STATUS_SHEET_MODES
  } from "../lib/orderStatusSheet.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import { guestReconnectToken } from "../lib/shopGuestSession.js"

  const sheet = createOrderStatusSheetState()
  let orders = $state([])
  let mode = $state(ORDER_STATUS_SHEET_MODES.HIDDEN)
  let connection = $state("idle")
  let unsubs = []

  function sync() {
    orders = sheet.orders
    mode = sheet.mode
    connection = sheet.connection
  }

  function clearSubs() {
    unsubs.forEach((fn) => { try { fn() } catch { /* */ } })
    unsubs = []
  }

  function resubscribe(list) {
    clearSubs()
    const token = guestReconnectToken()
    for (const order of list) {
      const orderId = order.id || order.order_id
      if (!orderId) continue
      unsubs.push(subscribeGuestOrderStatus({
        orderId,
        reconnectToken: token,
        onStatus: (payload) => { applyCableEvent(sheet, payload); sync() },
        onConnection: (status) => {
          const online = status === "connected"
          sheet.setConnection(online ? "online" : "lost")
          if (online) refreshActive()
          else sync()
        }
      }))
    }
  }

  async function refreshActive() {
    try {
      const data = await api("/orders/active")
      const list = Array.isArray(data) ? data : data?.orders || []
      applyReconnectOrders(sheet, list)
      sheet.setConnection("online")
      sync()
      resubscribe(list)
    } catch (err) {
      const status = err?.status || err?.response?.status || 500
      if (mapReconnectError(status) === "hide") applyReconnectOrders(sheet, [])
      else sheet.setConnection("lost")
      sync()
    }
  }

  onMount(() => {
    refreshActive()
    const onOnline = () => refreshActive()
    window.addEventListener("online", onOnline)
    return () => { window.removeEventListener("online", onOnline); clearSubs() }
  })

  let scrollable = $derived(shouldScrollStatusList(orders))
</script>

{#if mode === ORDER_STATUS_SHEET_MODES.PEEK && orders.length}
  <div class="oss" data-testid="shop-order-status-sheet" style="pointer-events:none">
    <div class="oss__panel" class:scrollable style="pointer-events:auto" role="status" aria-live="polite">
      {#if connection === "lost"}
        <p class="oss__conn">Потеряно соединение…</p>
      {/if}
      {#each orders as order (order.id || order.order_id)}
        {@const view = orderProgressView(order)}
        <button type="button" class="oss__row" onclick={() => push(`/order/${order.id || order.order_id}`)}>
          <span class="oss__meta">{#if view.subtitle}{view.subtitle} — {/if}{order.order_number || ""}</span>
          {#if view.showProgress}
            <div class="oss__steps">
              {#each view.steps as step}
                <span class="step" class:done={step.state === "done"} class:current={step.state === "current"} title={step.label}>
                  {step.state === "done" ? "✓" : step.icon}
                </span>
              {/each}
            </div>
          {:else}
            <span class="oss__meta">{view.header}</span>
          {/if}
        </button>
      {/each}
    </div>
  </div>
{/if}

<style>
  .oss { position: fixed; left: 0; right: 0; bottom: 0; z-index: 40; display: flex; justify-content: center; padding-bottom: env(safe-area-inset-bottom, 0); }
  .oss__panel { width: 100%; max-width: 32rem; background: #2a2a2a; border-top: 1px solid #3a3a3a; padding: 0.5rem 0.75rem 0.65rem; max-height: 28vh; }
  .oss__panel.scrollable { overflow-y: auto; }
  .oss__conn { margin: 0 0 0.35rem; font-size: 0.7rem; color: #f0c070; }
  .oss__row { display: block; width: 100%; text-align: left; background: transparent; border: 0; color: inherit; padding: 0.35rem 0; cursor: pointer; }
  .oss__meta { display: block; font-size: 0.7rem; color: #b0b0b0; margin-bottom: 0.25rem; }
  .oss__steps { display: flex; gap: 0.5rem; align-items: center; }
  .step { width: 1.5rem; height: 1.5rem; border-radius: 999px; display: inline-flex; align-items: center; justify-content: center; font-size: 0.65rem; background: #555; color: #ddd; }
  .step.done { background: #4caf50; color: #fff; }
  .step.current { background: #c8e6c9; color: #1a1a1a; }
</style>
