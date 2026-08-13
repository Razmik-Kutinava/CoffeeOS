<script>
  /** #35 sticky peek + #36 accordion + #41 cancel Confirm Sheet. */
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    createOrderStatusSheetState,
    shouldScrollStatusList,
    applyCableEvent,
    applyReconnectOrders,
    mapReconnectError,
    activeOrderIdsKey,
    ORDER_STATUS_SHEET_MODES,
    ACTIVE_ORDERS_POLL_MS,
    startActiveOrdersPolling,
    stopActiveOrdersPolling
  } from "../lib/orderStatusSheet.js"
  import {
    createActiveOrdersAccordionState
  } from "../lib/activeOrdersAccordion.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import { guestReconnectToken } from "../lib/shopGuestSession.js"
  import ActiveOrdersAccordion from "./ActiveOrdersAccordion.svelte"
  import OrderCancelModal from "./OrderCancelModal.svelte"
  import { refreshFrequentProducts } from "../lib/frequentRepeatStore.js"
  import {
    buildAcceptedCancelModalCopy,
    shouldShowAcceptedCancelModal
  } from "../lib/orderCancelFlow.js"
  import {
    applyStickyCancelSuccess,
    applyStickyCancelError
  } from "../lib/stickyOrderCancel.js"

  /** true — секция внутри CartSheet (не fixed overlay поверх шторки) */
  /** sheetContext: peek (скрин 01) | cart_expanded (скрин 06 — meta = позиция) */
  let { embedded = true, sheetContext = "peek" } = $props()

  const sheet = createOrderStatusSheetState()
  let orders = $state([])
  let mode = $state(ORDER_STATUS_SHEET_MODES.HIDDEN)
  let connection = $state("idle")
  let accordionState = $state(createActiveOrdersAccordionState([]))
  let unsubs = []
  let connectionLost = false
  /** Стабильный ключ подписок — poll не reconnect Cable при том же наборе id */
  let subscribedIdsKey = ""

  let cancelModalOpen = $state(false)
  let cancelLoading = $state(false)
  let cancelTarget = $state(null)
  let cancelToast = $state("")
  let cancelModalCopy = $state({
    title: "",
    body: "",
    confirmLabel: "",
    dismissLabel: "Оставить заказ"
  })

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
    subscribedIdsKey = ""
  }

  function resubscribe(list) {
    const nextKey = activeOrderIdsKey(list)
    if (nextKey === subscribedIdsKey && (nextKey === "" || unsubs.length > 0)) return

    clearSubs()
    subscribedIdsKey = nextKey
    if (!nextKey) return

    const token = guestReconnectToken()
    for (const order of list) {
      const orderId = order.id || order.order_id
      if (!orderId) continue
      unsubs.push(subscribeGuestOrderStatus({
        orderId,
        reconnectToken: token,
        onStatus: (payload) => {
          applyCableEvent(sheet, payload, {
            onTerminal: () => { refreshFrequentProducts() }
          })
          sync()
        },
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
      // #47 G3: после poll/reconnect — повторы без F5
      refreshFrequentProducts()
    } catch (err) {
      const status = err?.status || err?.response?.status || 500
      if (mapReconnectError(status) === "hide") {
        applyReconnectOrders(sheet, [])
        resubscribe([])
      } else sheet.setConnection("lost")
      sync()
      refreshFrequentProducts()
    }
  }

  function onCancelRequest(order) {
    if (cancelLoading || !order?.can_cancel) return
    cancelTarget = order
    cancelToast = ""
    if (shouldShowAcceptedCancelModal(order.status)) {
      cancelModalCopy = buildAcceptedCancelModalCopy({
        orderNumber: order.order_number || order.orderNumber,
        amount: order.total_amount ?? order.totalAmount
      })
      cancelModalOpen = true
      return
    }
    performStickyCancel(order)
  }

  async function performStickyCancel(order) {
    const target = order || cancelTarget
    const orderId = target?.id || target?.order_id
    if (!orderId || cancelLoading) return
    if (!target?.can_cancel) return

    cancelLoading = true
    cancelToast = ""
    try {
      const updated = await api(`/orders/${orderId}/cancel`, { method: "POST" })
      const outcome = applyStickyCancelSuccess(sheet, updated)
      cancelToast = outcome.toast
      cancelModalOpen = false
      cancelTarget = null
      try { localStorage.removeItem("coffeeos_shop_frequent_v1") } catch (_e) {}
      refreshFrequentProducts()
      sync()
    } catch (e) {
      const outcome = applyStickyCancelError(sheet, orderId, e)
      cancelToast = outcome.toast
      cancelModalOpen = false
      cancelTarget = null
      sync()
    } finally {
      cancelLoading = false
    }
  }

  onMount(() => {
    refreshActive()
    const onOnline = () => refreshActive()
    // #47 G2: возврат на вкладку / PWA — sync без reload (Cable мог умереть в фоне)
    const onVisibility = () => {
      if (document.visibilityState === "visible") refreshActive()
    }
    window.addEventListener("online", onOnline)
    document.addEventListener("visibilitychange", onVisibility)
    // #47 G1: ACTIVE_ORDERS_POLL_MS страховка; Cable остаётся fast-path
    startActiveOrdersPolling(() => { refreshActive() })
    return () => {
      window.removeEventListener("online", onOnline)
      document.removeEventListener("visibilitychange", onVisibility)
      stopActiveOrdersPolling()
      clearSubs()
    }
  })

  let scrollable = $derived(shouldScrollStatusList(orders))
  let panelExpanded = $derived(!!accordionState.activeExpandedOrderId)
  let statusSheetMode = $derived(
    orders.length === 0
      ? ORDER_STATUS_SHEET_MODES.HIDDEN
      : panelExpanded
        ? ORDER_STATUS_SHEET_MODES.EXPANDED
        : ORDER_STATUS_SHEET_MODES.PEEK
  )
</script>

{#if statusSheetMode !== ORDER_STATUS_SHEET_MODES.HIDDEN}
  <div
    class="oss"
    class:embedded
    data-testid="shop-order-status-sheet"
    data-status-sheet-mode={statusSheetMode}
    data-status-embedded={embedded ? "true" : "false"}
    style={embedded ? undefined : "pointer-events:none"}
  >
    <div
      class="oss__panel"
      class:scrollable
      class:expanded={panelExpanded}
      class:embedded
      style={embedded ? undefined : "pointer-events:auto"}
      role="status"
      aria-live="polite"
    >
      {#if connection === "lost"}
        <p class="oss__conn">Потеряно соединение…</p>
      {/if}
      {#if cancelToast}
        <p class="oss__toast" data-testid="sticky-cancel-toast" role="status">{cancelToast}</p>
      {/if}
      {#each orders as order (order.id || order.order_id)}
        <ActiveOrdersAccordion
          {order}
          {sheetContext}
          bind:accordionState
          onOpenDetail={(o) => push(`/order/${o.id || o.order_id}`)}
          onCancelRequest={onCancelRequest}
        />
      {/each}
      {#if scrollable}
        <div class="oss__scroll-hint" aria-hidden="true">↕</div>
      {/if}
    </div>
  </div>
{/if}

<OrderCancelModal
  open={cancelModalOpen}
  title={cancelModalCopy.title}
  body={cancelModalCopy.body}
  confirmLabel={cancelModalCopy.confirmLabel}
  dismissLabel={cancelModalCopy.dismissLabel}
  confirming={cancelLoading}
  onConfirm={() => performStickyCancel(cancelTarget)}
  onDismiss={() => {
    if (cancelLoading) return
    cancelModalOpen = false
    cancelTarget = null
  }}
/>

<style>
  /* Legacy overlay (embedded=false) — не использовать на витрине */
  .oss {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 60;
    display: flex;
    justify-content: center;
    padding-bottom: env(safe-area-inset-bottom, 0);
  }
  /* Внутри CartSheet: flow-секция, не второй слой */
  .oss.embedded {
    position: relative;
    left: auto;
    right: auto;
    bottom: auto;
    z-index: auto;
    display: block;
    width: 100%;
    flex-shrink: 0;
    padding-bottom: 0;
  }
  .oss__panel {
    position: relative;
    width: 100%;
    background: #2a2a2a;
    border-top: 1px solid #3a3a3a;
    border-radius: 1rem 1rem 0 0;
    box-shadow: 0 -0.5rem 1.5rem rgb(0 0 0 / 35%);
    padding: 0.35rem 0.55rem 0.45rem;
    max-height: 8.75rem;
    transition: max-height 0.3s ease;
  }
  .oss__panel.embedded {
    border-radius: 0;
    box-shadow: none;
    border-top: none;
    border-bottom: 1px solid #3a3a3a;
    background: transparent;
    /* #42: не перекрывать оплату / каталог при multi-order */
    max-height: min(22vh, 8.5rem);
  }
  .oss__panel.scrollable { overflow-y: auto; }
  .oss__panel.expanded {
    max-height: min(70vh, 32rem);
    overflow-y: auto;
  }
  .oss__panel.embedded.expanded {
    max-height: min(36vh, 14rem);
  }
  .oss__conn { margin: 0 0 0.25rem; font-size: 0.65rem; color: #f0c070; }
  .oss__toast {
    margin: 0 0 0.35rem;
    font-size: 0.68rem;
    color: #a5d6a7;
    line-height: 1.3;
  }
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
  .oss__panel.embedded .oss__scroll-hint {
    background: transparent;
  }
</style>
