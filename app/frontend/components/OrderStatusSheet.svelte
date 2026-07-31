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
  let connectionLost = false

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
          if (!online) {
            connectionLost = true
            sync()
          } else if (connectionLost) {
            connectionLost = false
            refreshActive()
          } else {
            sync()
          }
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
        <button
          type="button"
          class="oss__row"
          onclick={() => push(`/order/${order.id || order.order_id}`)}
        >
          <span class="oss__meta">
            {#if view.subtitle}{view.subtitle} — {/if}{order.order_number || ""}
          </span>
          {#if view.showProgress}
            <div class="oss__progress" aria-label="Прогресс заказа">
              <div class="oss__track">
                <div class="oss__fill" style="width: {view.fillPercent}%"></div>
              </div>
              <div class="oss__steps">
                {#each view.steps as step (step.id)}
                  <div
                    class="oss__step"
                    class:done={step.state === "done"}
                    class:current={step.state === "current"}
                  >
                    <span class="oss__circle" title={step.label}>
                      {#if step.state === "done"}✓{:else}{step.icon}{/if}
                    </span>
                    <span class="oss__label">{step.label}</span>
                  </div>
                {/each}
              </div>
            </div>
          {:else}
            <span class="oss__meta">{view.header}</span>
          {/if}
        </button>
      {/each}
      {#if scrollable}
        <div class="oss__scroll-hint" aria-hidden="true">↕</div>
      {/if}
    </div>
  </div>
{/if}

<style>
  .oss {
    position: fixed;
    left: 0;
    right: 7.5rem;
    bottom: 0;
    z-index: 60;
    display: flex;
    justify-content: flex-end;
    padding-bottom: env(safe-area-inset-bottom, 0);
  }
  .oss__panel {
    position: relative;
    width: 100%;
    max-width: 24.5rem;
    background: #2a2a2a;
    border-top: 1px solid #3a3a3a;
    border-right: 3px solid #ff8c42;
    padding: 0.35rem 0.55rem 0.45rem;
    max-height: 8.75rem;
  }
  .oss__panel.scrollable { overflow-y: auto; }
  .oss__conn { margin: 0 0 0.25rem; font-size: 0.65rem; color: #f0c070; }
  .oss__row {
    display: block;
    width: 100%;
    text-align: left;
    background: transparent;
    border: 0;
    color: inherit;
    padding: 0.3rem 0;
    cursor: pointer;
  }
  .oss__meta {
    display: block;
    font-size: 0.62rem;
    color: #b0b0b0;
    margin-bottom: 0.2rem;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .oss__progress { position: relative; padding: 0 0.1rem; }
  .oss__track {
    position: absolute;
    left: 1.1rem;
    right: 1.1rem;
    top: 0.7rem;
    height: 2px;
    background: #3a3a3a;
    border-radius: 999px;
    z-index: 0;
  }
  .oss__fill {
    height: 100%;
    background: #4caf50;
    border-radius: 999px;
    transition: width 0.25s ease;
  }
  .oss__steps {
    position: relative;
    z-index: 1;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 0.15rem;
  }
  .oss__step {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.15rem;
    min-width: 0;
  }
  .oss__circle {
    width: 1.45rem;
    height: 1.45rem;
    border-radius: 999px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 0.62rem;
    background: #3a3a3a;
    border: 1.5px solid #757575;
    color: #ddd;
  }
  .oss__step.done .oss__circle {
    background: #4caf50;
    border-color: #4caf50;
    color: #fff;
  }
  .oss__step.current .oss__circle {
    background: #4caf50;
    border-color: #4caf50;
    color: #fff;
  }
  .oss__label {
    font-size: 0.52rem;
    line-height: 1.1;
    color: #888;
    text-align: center;
    white-space: nowrap;
  }
  .oss__step.done .oss__label { color: #4caf50; }
  .oss__step.current .oss__label { color: #4caf50; font-weight: 600; }
  .oss__scroll-hint {
    position: sticky;
    bottom: 0;
    float: right;
    margin-top: -1.2rem;
    color: #888;
    font-size: 0.75rem;
    background: #2a2a2a;
    padding: 0 0.15rem;
  }
</style>
