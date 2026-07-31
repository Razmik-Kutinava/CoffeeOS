<script>
  /** #35 sticky peek + #36 accordion/чек; pointer-events: каталог не блокируется. */
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    createOrderStatusSheetState,
    shouldScrollStatusList,
    applyCableEvent,
    applyReconnectOrders,
    mapReconnectError,
    ORDER_STATUS_SHEET_MODES
  } from "../lib/orderStatusSheet.js"
  import {
    createActiveOrdersAccordionState
  } from "../lib/activeOrdersAccordion.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import { guestReconnectToken } from "../lib/shopGuestSession.js"
  import ActiveOrdersAccordion from "./ActiveOrdersAccordion.svelte"

  const sheet = createOrderStatusSheetState()
  let orders = $state([])
  let mode = $state(ORDER_STATUS_SHEET_MODES.HIDDEN)
  let connection = $state("idle")
  let accordionState = $state(createActiveOrdersAccordionState([]))
  let unsubs = []
  let connectionLost = false

  function sync() {
    orders = sheet.orders
    mode = sheet.mode
    connection = sheet.connection
    const prev = accordionState.activeExpandedOrderId
    accordionState = createActiveOrdersAccordionState(orders)
    const stillThere = orders.some(
      (o) => String(o.id || o.order_id) === String(prev || "")
    )
    if (stillThere) accordionState.activeExpandedOrderId = prev
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
  let panelExpanded = $derived(!!accordionState.activeExpandedOrderId)
</script>

{#if mode === ORDER_STATUS_SHEET_MODES.PEEK && orders.length}
  <div class="oss" data-testid="shop-order-status-sheet" style="pointer-events:none">
    <div
      class="oss__panel"
      class:scrollable
      class:expanded={panelExpanded}
      style="pointer-events:auto"
      role="status"
      aria-live="polite"
    >
      {#if connection === "lost"}
        <p class="oss__conn">Потеряно соединение…</p>
      {/if}
      {#each orders as order (order.id || order.order_id)}
        <ActiveOrdersAccordion
          {order}
          bind:accordionState
          onOpenDetail={(o) => push(`/order/${o.id || o.order_id}`)}
        />
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
  .oss__panel.expanded {
    max-height: min(70vh, 32rem);
    overflow-y: auto;
  }
  .oss__conn { margin: 0 0 0.25rem; font-size: 0.65rem; color: #f0c070; }
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
