<script>
  /** #36/#37 accordion: статус + CTA Wallet/Push + текстовый чек. */
  import {
    toggleExpandedOrder,
    accordionRowView,
    receiptView,
    receiptScrollStyle,
    CHEVRON
  } from "../lib/activeOrdersAccordion.js"
  import { getDeviceOS } from "../lib/deviceDetect.js"
  import {
    notifyActionsView,
    openOrderReceipt,
    downloadWalletPass,
    subscribeOrderPush,
    resolveNotifyPrimaryInit
  } from "../lib/orderStatusNotifyActions.js"

  let {
    order,
    accordionState = $bindable(),
    onOpenDetail = undefined
  } = $props()

  let row = $derived(accordionRowView(order, accordionState?.activeExpandedOrderId))
  let receipt = $derived(row.expanded ? receiptView(order) : null)
  let scrollStyle = receiptScrollStyle()
  let deviceOs = $derived(getDeviceOS())
  let actions = $derived(notifyActionsView({ os: deviceOs }))
  let primaryLabelOverride = $state(null)
  let primaryLoading = $state(false)
  let toastMsg = $state("")
  let displayPrimary = $derived(primaryLabelOverride ?? actions.primaryLabel)

  $effect(() => {
    const id = order?.id || order?.order_id
    const init = resolveNotifyPrimaryInit({
      os: deviceOs,
      orderId: id
    })
    if (init.restored && init.primaryLabel) {
      primaryLabelOverride = init.primaryLabel
    }
  })

  function onToggle(e) {
    e.stopPropagation()
    const id = order.id || order.order_id
    toggleExpandedOrder(accordionState, id)
  }

  function onReceipt(e) {
    e.stopPropagation()
    const id = order.id || order.order_id
    openOrderReceipt(accordionState, id, { isLoading: false })
  }

  async function onPrimary(e) {
    e.stopPropagation()
    if (primaryLoading || primaryLabelOverride) return
    if (actions.primaryKind !== "wallet" && actions.primaryKind !== "push") return

    primaryLoading = true
    toastMsg = ""
    const id = order.id || order.order_id
    const onToast = (msg) => {
      toastMsg = msg
    }

    const result =
      actions.primaryKind === "wallet"
        ? await downloadWalletPass({ orderId: id, onToast })
        : await subscribeOrderPush({ onToast })

    primaryLoading = false
    if (result.ok) primaryLabelOverride = result.primaryLabel
  }

  function onDetail() {
    if (typeof onOpenDetail === "function") onOpenDetail(order)
  }
</script>

<div class="aoa" data-testid="active-order-accordion-row">
  <div class="aoa__head">
    <button type="button" class="aoa__meta-btn" onclick={onDetail}>
      <span class="aoa__meta">
        {#if row.eta}{row.eta} — {/if}{row.orderNumber}{#if row.salesPointName} — {row.salesPointName}{/if}
      </span>
      {#if row.showProgress}
        <div class="aoa__progress" aria-label="Прогресс заказа">
          <div class="aoa__track">
            <div class="aoa__fill" style="width: {row.fillPercent}%"></div>
          </div>
          <div class="aoa__steps">
            {#each row.steps as step (step.id)}
              <div
                class="aoa__step"
                class:done={step.state === "done"}
                class:current={step.state === "current"}
              >
                <span class="aoa__circle" title={step.label}>
                  {#if step.state === "done"}✓{:else}{step.icon}{/if}
                </span>
                <span class="aoa__label">{step.label}</span>
              </div>
            {/each}
          </div>
        </div>
      {/if}
    </button>
    <div class={actions.actionsClass} data-testid="active-order-notify-actions">
      <button
        type="button"
        class={actions.buttonClass}
        data-kind={actions.primaryKind}
        data-testid="active-order-notify-primary"
        disabled={primaryLoading || Boolean(primaryLabelOverride)}
        onclick={onPrimary}
      >{#if primaryLoading}…{:else}{displayPrimary}{/if}</button>
      <button
        type="button"
        class={actions.buttonClass}
        data-testid="active-order-notify-receipt"
        onclick={onReceipt}
      >{actions.secondaryLabel}</button>
    </div>
  </div>
  {#if toastMsg}
    <div class="aoa__toast" data-testid="active-order-notify-toast" role="status">{toastMsg}</div>
  {/if}
  <button
    type="button"
    class="aoa__chevron"
    aria-expanded={row.expanded}
    aria-label={row.expanded ? "Свернуть чек" : "Развернуть чек"}
    onclick={onToggle}
  >{row.expanded ? CHEVRON.expanded : CHEVRON.collapsed}</button>

  {#if receipt}
    <div
      class="aoa__receipt"
      data-testid="active-order-receipt"
      style="max-height: {scrollStyle.maxHeight}; overflow-y: {scrollStyle.overflowY}"
    >
      {#each receipt.lines as line, i (i)}
        <div class="aoa__line">
          <div class="aoa__line-name">{line.name}</div>
          {#each line.modifiers as mod (mod.name)}
            <div class="aoa__mod">+ {mod.name}{#if mod.price} · {mod.price}₽{/if}</div>
          {/each}
          <div class="aoa__line-meta">
            ×{line.quantity} · {line.price}₽
            {#if line.discount} · скидка {line.discount}₽{/if}
            · итог {line.lineTotal}₽
          </div>
        </div>
      {/each}
      <div class="aoa__totals">
        <div>Subtotal: {receipt.subtotal}₽</div>
        <div>Discount: {receipt.discount}₽</div>
        <div class="aoa__total">Total Amount: {receipt.totalAmount}₽</div>
      </div>
    </div>
  {/if}
</div>

<style>
  .aoa {
    padding: 0.3rem 0 0.45rem;
    border-bottom: 1px solid #333;
  }
  .aoa:last-child { border-bottom: 0; }
  .aoa__head {
    display: flex;
    gap: 0.4rem;
    align-items: flex-start;
  }
  .aoa__meta-btn {
    flex: 1;
    min-width: 0;
    text-align: left;
    background: transparent;
    border: 0;
    color: inherit;
    padding: 0;
    cursor: pointer;
  }
  .aoa__meta {
    display: block;
    font-size: 0.62rem;
    color: #b0b0b0;
    margin-bottom: 0.2rem;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .aoa__progress { position: relative; padding: 0 0.1rem; }
  .aoa__track {
    position: absolute;
    left: 1.1rem;
    right: 1.1rem;
    top: 0.7rem;
    height: 2px;
    background: #3a3a3a;
    border-radius: 999px;
    z-index: 0;
  }
  .aoa__fill {
    height: 100%;
    background: #4caf50;
    border-radius: 999px;
    transition: width 0.25s ease;
  }
  .aoa__steps {
    position: relative;
    z-index: 1;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 0.15rem;
  }
  .aoa__step {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.15rem;
    min-width: 0;
  }
  .aoa__circle {
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
  .aoa__step.done .aoa__circle,
  .aoa__step.current .aoa__circle {
    background: #4caf50;
    border-color: #4caf50;
    color: #fff;
  }
  .aoa__label {
    font-size: 0.52rem;
    line-height: 1.1;
    color: #888;
    text-align: center;
    white-space: nowrap;
  }
  .aoa__step.done .aoa__label,
  .aoa__step.current .aoa__label { color: #4caf50; }
  .aoa__step.current .aoa__label { font-weight: 600; }
  .aoa__actions {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    flex-shrink: 0;
    width: 11rem;
  }
  .aoa__cta {
    display: flex;
    align-items: center;
    justify-content: center;
    box-sizing: border-box;
    height: 36px;
    padding: 0 0.45rem;
    background: #ff8c42;
    color: #000000;
    font-size: 0.75rem;
    font-weight: 600;
    border: 0;
    border-radius: 0.5rem;
    cursor: pointer;
    text-align: center;
    line-height: 1.15;
    white-space: normal;
  }
  .aoa__cta:disabled {
    opacity: 0.85;
    cursor: default;
  }
  .aoa__toast {
    margin-top: 0.25rem;
    font-size: 0.62rem;
    color: #ffb74d;
  }
  .aoa__chevron {
    display: block;
    margin: 0.15rem auto 0;
    background: transparent;
    border: 0;
    color: #eee;
    font-size: 0.75rem;
    cursor: pointer;
    padding: 0.1rem 0.5rem;
  }
  .aoa__receipt {
    margin-top: 0.35rem;
    border: 1px solid #888;
    border-radius: 0.65rem;
    padding: 0.45rem 0.55rem;
    background: #1a1a1a;
    color: #ddd;
    font-size: 0.68rem;
    line-height: 1.35;
  }
  .aoa__line { margin-bottom: 0.4rem; }
  .aoa__line-name { color: #fff; font-weight: 500; }
  .aoa__mod { color: #aaa; padding-left: 0.35rem; }
  .aoa__line-meta { color: #b0b0b0; margin-top: 0.1rem; }
  .aoa__totals {
    border-top: 1px solid #444;
    margin-top: 0.35rem;
    padding-top: 0.35rem;
    color: #ccc;
  }
  .aoa__total { color: #ff8c42; font-weight: 600; margin-top: 0.15rem; }
</style>
