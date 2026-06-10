<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { reconnectGuestOrder } from "../lib/shopGuestSession.js"
  import { orderProgressView } from "../lib/orderStatusProgress.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import PageSkeleton from "../components/PageSkeleton.svelte"

  let { params } = $props()

  let order = $state(null)
  let loading = $state(true)
  let err = $state(null)

  const progress = $derived(order ? orderProgressView(order.status) : null)

  const pickupLine = $derived(
    order?.tenant
      ? [order.tenant.address, order.tenant.city].filter(Boolean).join(", ")
      : ""
  )

  useTelegramBack(() => push("/orders"))

  onMount(async () => {
    const orderId = params?.id
    if (!orderId) {
      err = "Не указан заказ"
      loading = false
      return
    }

    try {
      await reconnectGuestOrder(api)
      order = await api(`/orders/${orderId}`)
    } catch (e) {
      err = e.message || "Заказ не найден"
    } finally {
      loading = false
    }
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
    <div class="status-hero">
      <p class="order-number">Заказ #{order.order_number || order.id}</p>
      <h1 class="status-title">{progress.header}</h1>
      {#if progress.showEta}
        <p class="eta">Примерно 8–12 минут</p>
      {/if}
    </div>

    {#if progress.cancelled}
      <div class="message-block cancelled">
        <p>Заказ отменён</p>
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
            <div class="item-side">
              <span class="item-qty">×{item.quantity}</span>
              <span class="item-price">{formatMoney(item.line_total ?? item.price * item.quantity)}</span>
            </div>
          </li>
        {/each}
      </ul>
    </section>

    <section class="card pickup-card">
      <div class="pickup-icon" aria-hidden="true">📍</div>
      <div>
        <h2 class="card-title compact">Самовывоз</h2>
        <p class="pickup-name">{order.tenant?.name || "Кофейня"}</p>
        {#if pickupLine}
          <p class="pickup-address">{pickupLine}</p>
        {/if}
      </div>
    </section>

    <section class="card total-card">
      <div class="total-row">
        <span class="total-label">Итого оплачено</span>
        <span class="total-value">{formatMoney(order.total)}</span>
      </div>
      {#if progress.paymentSettled}
        <span class="paid-badge">Оплачен</span>
      {:else}
        <span class="pending-badge">Ожидает оплаты</span>
      {/if}
    </section>
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

  .status-hero {
    text-align: center;
    margin-bottom: 28px;
  }

  .order-number {
    font-size: 13px;
    color: #a0a0a0;
    margin: 0 0 8px;
  }

  .status-title {
    font-size: 32px;
    font-weight: 800;
    margin: 0 0 8px;
    color: #fff;
  }

  .eta {
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

  .item-side {
    text-align: right;
    flex-shrink: 0;
  }

  .item-qty {
    display: block;
    font-size: 12px;
    color: #a0a0a0;
  }

  .item-price {
    font-size: 15px;
    font-weight: 600;
    color: #ff8c42;
  }

  .pickup-card {
    display: flex;
    gap: 12px;
    align-items: flex-start;
  }

  .pickup-icon {
    font-size: 22px;
    line-height: 1;
  }

  .pickup-name {
    margin: 0;
    font-size: 15px;
    color: #fff;
  }

  .pickup-address {
    margin: 4px 0 0;
    font-size: 13px;
    color: #a0a0a0;
    line-height: 1.4;
  }

  .total-card {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
  }

  .total-row {
    display: flex;
    flex-direction: column;
    gap: 4px;
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
    font-size: 18px;
    color: #f44336;
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
