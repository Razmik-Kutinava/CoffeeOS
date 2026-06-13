<script>
  import { onMount, onDestroy } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { reconnectGuestOrder, guestReconnectToken, lastGuestOrderId, saveGuestOrderSession } from "../lib/shopGuestSession.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import { orderProgressView } from "../lib/orderStatusProgress.js"
  import { firebaseClientConfigured, registerShopPush } from "../lib/firebasePush.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import PageSkeleton from "../components/PageSkeleton.svelte"

  let { params } = $props()

  let order = $state(null)
  let loading = $state(true)
  let err = $state(null)
  let cableState = $state("idle")
  let cancelErr = $state(null)
  let cancelling = $state(false)
  let pushAvailable = $state(false)
  let pushState = $state("idle")
  let pushErr = $state(null)
  let unsubscribeCable = null

  const progress = $derived(order ? orderProgressView(order) : null)
  const showCancelButton = $derived(Boolean(order?.can_cancel))

  const pickupLine = $derived(
    order?.tenant
      ? [order.tenant.address, order.tenant.city].filter(Boolean).join(", ")
      : ""
  )

  useTelegramBack(() => push("/orders"))

  function applyStatusPatch(patch) {
    if (!order || !patch?.status) return
    order = {
      ...order,
      status: patch.status,
      payment_settled: patch.payment_settled ?? order.payment_settled,
      can_cancel: patch.can_cancel ?? order.can_cancel,
      cancelled_by: patch.cancelled_by ?? order.cancelled_by,
      cancel_message: patch.cancel_message ?? order.cancel_message
    }
  }

  async function enablePushNotifications() {
    pushErr = null
    pushState = "requesting"
    try {
      const result = await registerShopPush()
      if (result.ok) {
        pushState = "registered"
      } else if (result.reason === "denied") {
        pushState = "denied"
        pushErr = "Уведомления отключены в браузере"
      } else {
        pushState = "error"
        pushErr = "Не удалось включить уведомления"
      }
    } catch (e) {
      pushState = "error"
      pushErr = e.message || "Ошибка подписки на push"
    }
  }

  async function cancelOrder() {
    if (!order?.can_cancel || cancelling) return
    if (!window.confirm("Отменить заказ?")) return

    cancelErr = null
    cancelling = true
    try {
      const updated = await api(`/orders/${order.id}/cancel`, { method: "POST" })
      order = updated
    } catch (e) {
      cancelErr = e.message
    } finally {
      cancelling = false
    }
  }

  onMount(async () => {
    const orderId = params?.id
    if (!orderId) {
      err = "Не указан заказ"
      loading = false
      return
    }

    try {
      order = await api(`/orders/${orderId}`)

      const token =
        order.reconnect_token ||
        (lastGuestOrderId() === orderId ? guestReconnectToken() : null)
      if (token) {
        saveGuestOrderSession(orderId, token)
        await reconnectGuestOrder(api)
      }

      unsubscribeCable = subscribeGuestOrderStatus({
        orderId,
        reconnectToken: token,
        onStatus: applyStatusPatch,
        onConnection: (state) => {
          cableState = state
        }
      })

      pushAvailable = firebaseClientConfigured()
      if (pushAvailable && typeof Notification !== "undefined" && Notification.permission === "granted") {
        enablePushNotifications()
      }
    } catch (e) {
      err = e.message || "Заказ не найден"
    } finally {
      loading = false
    }
  })

  onDestroy(() => {
    unsubscribeCable?.()
    unsubscribeCable = null
  })

  function formatMoney(value) {
    return `${Math.round(Number(value) || 0)} ₽`
  }

  function modifierLabel(mod) {
    if (!mod) return ""
    return mod.option_name || mod.name || mod.label || ""
  }
</script>

<div class="order-status-page">
  <div class="page-header">
    <button type="button" class="back-btn" onclick={() => push("/orders")} aria-label="Назад">‹</button>
    <span class="page-title">Заказ</span>
  </div>

  {#if loading}
    <PageSkeleton />
  {:else if err}
    <div class="message-block">
      <p class="error-text">{err}</p>
      <button type="button" class="primary-btn" onclick={() => push("/")}>В каталог</button>
    </div>
  {:else if order && progress}
    {#if cableState === "disconnected"}
      <p class="cable-banner" role="status">Обновление статуса...</p>
    {/if}

    <div class="status-hero">
      <h1 class="status-title">{progress.header}</h1>
      {#if progress.subtitle}
        <p class="status-subtitle">{progress.subtitle}</p>
      {/if}
    </div>

    {#if pushAvailable && !progress.cancelled && pushState !== "registered"}
      <div class="push-banner">
        <p class="push-banner-text">Получайте статус заказа в шторке уведомлений</p>
        {#if pushErr}
          <p class="push-banner-error">{pushErr}</p>
        {/if}
        <button
          type="button"
          class="push-banner-btn"
          disabled={pushState === "requesting"}
          onclick={enablePushNotifications}
        >
          {pushState === "requesting" ? "Подключаем…" : "Разрешить уведомления"}
        </button>
      </div>
    {:else if pushState === "registered"}
      <p class="push-ok" role="status">Уведомления включены</p>
    {/if}

    {#if progress.cancelled}
      <div class="message-block cancelled" class:staff-cancel={progress.cancelledByStaff}>
        <p>{progress.cancelMessage}</p>
      </div>
    {:else if progress.showProgress}
      <div class="progress-wrap" aria-label="Прогресс заказа">
        <div class="progress-track">
          <div class="progress-fill" style="width: {progress.fillPercent}%"></div>
        </div>
        <div class="progress-steps">
          {#each progress.steps as step (step.id)}
            <div class="step" class:step--done={step.state === "done"} class:step--current={step.state === "current"}>
              <div
                class="step-circle"
                class:step-circle--done={step.state === "done"}
                class:step-circle--current={step.state === "current"}
              >
                {#if step.state === "done"}
                  <span class="step-check" aria-hidden="true">✓</span>
                {:else}
                  <span class="step-icon" aria-hidden="true">{step.icon}</span>
                {/if}
              </div>
              <span class="step-label">{step.label}</span>
            </div>
          {/each}
        </div>
      </div>
    {/if}

    <section class="card">
      <h2 class="card-title">Состав заказа</h2>
      <ul class="items-list">
        {#each order.items || [] as item}
          <li class="item-row">
            <div class="item-main">
              <span class="item-name">{item.product_name}</span>
              {#if item.selected_modifiers?.length}
                <span class="item-mods">
                  {item.selected_modifiers.map(modifierLabel).filter(Boolean).join(", ")}
                </span>
              {/if}
            </div>
            <span class="item-qty">{item.quantity}x</span>
          </li>
        {/each}
      </ul>
    </section>

    <section class="card pickup-card">
      <div class="pickup-icon" aria-hidden="true">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 21s7-4.5 7-11a7 7 0 1 0-14 0c0 6.5 7 11 7 11z" />
          <circle cx="12" cy="10" r="2.5" />
        </svg>
      </div>
      <div>
        <h2 class="pickup-title">Самовывоз</h2>
        <p class="pickup-address">{pickupLine || order.tenant?.name || "Кофейня"}</p>
      </div>
    </section>

    <section class="card total-card">
      <div class="total-left">
        <span class="total-icon" aria-hidden="true">💳</span>
        <div class="total-row">
          <span class="total-label">Итого оплачено</span>
          <span class="total-value">{formatMoney(order.total)}</span>
        </div>
      </div>
      {#if progress.paymentSettled}
        <span class="paid-badge">Оплачен</span>
      {:else if !progress.cancelled}
        <span class="pending-badge">Ожидает оплаты</span>
      {/if}
    </section>

    {#if showCancelButton}
      {#if cancelErr}
        <p class="cancel-error" role="alert">{cancelErr}</p>
      {/if}
      <button
        type="button"
        class="cancel-btn"
        disabled={cancelling}
        onclick={cancelOrder}
      >
        {cancelling ? "Отменяем…" : "Отменить заказ"}
      </button>
    {/if}
  {/if}
</div>

<style>
  .order-status-page {
    padding-bottom: 96px;
  }

  .page-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin: -4px 0 20px;
  }

  .back-btn {
    background: none;
    border: none;
    color: #ff8c42;
    font-size: 28px;
    line-height: 1;
    cursor: pointer;
    padding: 0;
  }

  .page-title {
    font-size: 16px;
    color: #a0a0a0;
  }

  .cable-banner {
    margin: 0 0 12px;
    padding: 10px 14px;
    border-radius: 10px;
    background: rgba(255, 140, 66, 0.12);
    color: #ff8c42;
    font-size: 13px;
    text-align: center;
  }

  .status-hero {
    text-align: center;
    margin-bottom: 28px;
  }

  .status-title {
    font-size: 32px;
    font-weight: 800;
    margin: 0 0 8px;
    color: #fff;
  }

  .status-subtitle {
    margin: 0;
    font-size: 15px;
    color: #a0a0a0;
  }

  .progress-wrap {
    margin-bottom: 28px;
    padding: 0 4px;
  }

  .progress-track {
    position: relative;
    height: 4px;
    background: #3a3a3a;
    border-radius: 999px;
    margin: 0 28px 18px;
  }

  .progress-fill {
    position: absolute;
    left: 0;
    top: 0;
    height: 100%;
    background: #4caf50;
    border-radius: 999px;
    transition: width 0.3s ease;
  }

  .progress-steps {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 4px;
  }

  .step {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    min-width: 0;
  }

  .step-circle {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #2a2a2a;
    border: 2px solid #757575;
    color: #757575;
  }

  .step-circle--current {
    border-color: #ff8c42;
    background: rgba(255, 140, 66, 0.12);
    color: #ff8c42;
  }

  .step-circle--done {
    border-color: #4caf50;
    background: #4caf50;
    color: #fff;
  }

  .step-check {
    font-size: 18px;
    font-weight: 700;
  }

  .step-icon {
    font-size: 18px;
    line-height: 1;
  }

  .step-label {
    font-size: 11px;
    text-align: center;
    color: #a0a0a0;
    line-height: 1.2;
  }

  .step--current .step-label {
    color: #ff8c42;
    font-weight: 600;
  }

  .step--done .step-label {
    color: #4caf50;
  }

  .card {
    background: #2a2a2a;
    border-radius: 16px;
    padding: 16px;
    margin-bottom: 12px;
  }

  .card-title {
    margin: 0 0 12px;
    font-size: 15px;
    font-weight: 700;
    color: #fff;
  }

  .card-title.compact {
    margin-bottom: 4px;
  }

  .items-list {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .item-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 12px;
  }

  .item-main {
    min-width: 0;
  }

  .item-name {
    display: block;
    font-size: 15px;
    color: #fff;
  }

  .item-mods {
    display: block;
    font-size: 12px;
    color: #a0a0a0;
    margin-top: 2px;
  }

  .item-qty {
    flex-shrink: 0;
    font-size: 14px;
    color: #a0a0a0;
  }

  .push-banner {
    margin: 0 0 16px;
    padding: 14px 16px;
    border-radius: 12px;
    border: 1px solid #3a3a3a;
    background: #242424;
  }

  .push-banner-text {
    margin: 0 0 10px;
    font-size: 14px;
    color: #e8e8e8;
    line-height: 1.4;
  }

  .push-banner-error {
    margin: 0 0 8px;
    font-size: 13px;
    color: #ff8c42;
  }

  .push-banner-btn {
    width: 100%;
    border: none;
    border-radius: 10px;
    padding: 12px 16px;
    font-size: 15px;
    font-weight: 600;
    color: #1a1a1a;
    background: #ff8c42;
    cursor: pointer;
  }

  .push-banner-btn:disabled {
    opacity: 0.7;
    cursor: wait;
  }

  .push-ok {
    margin: 0 0 12px;
    font-size: 13px;
    color: #4caf50;
  }

  .pickup-card {
    display: flex;
    gap: 12px;
    align-items: flex-start;
    background: #e8f5e9;
    border: 1px solid #c8e6c9;
  }

  .pickup-icon {
    color: #4caf50;
    flex-shrink: 0;
    margin-top: 2px;
  }

  .pickup-title {
    margin: 0 0 4px;
    font-size: 14px;
    font-weight: 700;
    color: #2e7d32;
  }

  .pickup-address {
    margin: 0;
    font-size: 14px;
    color: #1b5e20;
    line-height: 1.4;
  }

  .total-card {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .total-left {
    display: flex;
    align-items: center;
    gap: 12px;
    min-width: 0;
  }

  .total-icon {
    font-size: 22px;
    line-height: 1;
    flex-shrink: 0;
  }

  .total-row {
    display: flex;
    flex-direction: column;
    gap: 2px;
    min-width: 0;
  }

  .total-label {
    font-size: 13px;
    color: #a0a0a0;
  }

  .total-value {
    font-size: 22px;
    font-weight: 800;
    color: #fff;
  }

  .paid-badge,
  .pending-badge {
    font-size: 12px;
    font-weight: 700;
    padding: 6px 12px;
    border-radius: 999px;
  }

  .paid-badge {
    background: rgba(76, 175, 80, 0.15);
    color: #4caf50;
  }

  .pending-badge {
    background: rgba(255, 140, 66, 0.15);
    color: #ff8c42;
  }

  .message-block {
    text-align: center;
    padding: 40px 16px;
    color: #a0a0a0;
  }

  .message-block.cancelled p {
    font-size: 16px;
    line-height: 1.45;
    color: #f44336;
    margin: 0;
  }

  .message-block.staff-cancel p {
    color: #ffb74d;
  }

  .cancel-btn {
    display: block;
    width: 100%;
    margin-top: 16px;
    padding: 12px;
    border: none;
    background: transparent;
    color: #a0a0a0;
    font-size: 15px;
    font-weight: 500;
    cursor: pointer;
    text-decoration: underline;
    text-underline-offset: 3px;
  }

  .cancel-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .cancel-error {
    margin: 12px 0 0;
    font-size: 13px;
    color: #f44336;
    text-align: center;
  }

  .error-text {
    color: #f44336;
    margin-bottom: 16px;
  }

  .primary-btn {
    background: #ff8c42;
    color: #000;
    border: none;
    border-radius: 12px;
    padding: 12px 24px;
    font-weight: 700;
    cursor: pointer;
  }
</style>
