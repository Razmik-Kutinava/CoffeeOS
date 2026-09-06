<script>
  /** #35/#37/#41 accordion: статус + OrderActionButtons (без состава чека в статусной модели). */
  import { accordionRowView } from "../lib/activeOrdersAccordion.js"
  import { getDeviceOS } from "../lib/deviceDetect.js"
  import {
    downloadWalletPass,
    subscribeOrderPush,
    resolveNotifyPrimaryInit
  } from "../lib/orderStatusNotifyActions.js"
  import { openSupportChat } from "../lib/supportChatAdapter.js"
  import { openTipsService } from "../lib/tipsAdapter.js"
  import OrderActionButtons from "./OrderActionButtons.svelte"

  let {
    order,
    sheetContext = "peek",
    accordionState = $bindable(),
    onOpenDetail = undefined,
    onCancelRequest = undefined,
    onDismiss = undefined
  } = $props()

  let row = $derived(
    accordionRowView(order, accordionState?.activeExpandedOrderId, { sheetContext })
  )
  let deviceOs = $derived(getDeviceOS())
  let actionLoading = $state(false)
  let toastMsg = $state("")
  let pushSubscribed = $state(false)

  let orderId = $derived(order?.id || order?.order_id)
  let hasPushSubscription = $derived(
    pushSubscribed ||
      resolveNotifyPrimaryInit({ os: deviceOs, orderId }).restored
  )
  let canCancel = $derived(Boolean(order?.can_cancel))
  let status = $derived(String(order?.status || ""))

  $effect(() => {
    const init = resolveNotifyPrimaryInit({
      os: deviceOs,
      orderId
    })
    if (init.restored) pushSubscribed = true
  })

  function onDetail() {
    if (typeof onOpenDetail === "function") onOpenDetail(order)
  }

  /**
   * @param {string} kind
   */
  async function onAction(kind) {
    if (actionLoading) return
    toastMsg = ""

    if (kind === "cancel") {
      if (typeof onCancelRequest === "function") {
        onCancelRequest(order)
        return
      }
      return
    }

    if (kind === "chat") {
      openSupportChat(orderId)
      return
    }

    if (kind === "tips") {
      const tenantId = order?.tenant_id || order?.sales_point?.tenant_id || ""
      openTipsService(orderId, tenantId)
      return
    }

    // #77: subscription purchase UI out of scope — ЛК as landing until billing ships
    if (kind === "subscription") {
      window.location.hash = "#/profile"
      return
    }

    if (kind === "wallet" || kind === "push") {
      actionLoading = true
      const onToast = (msg) => {
        toastMsg = msg
      }
      const result =
        kind === "wallet"
          ? await downloadWalletPass({ orderId, onToast })
          : await subscribeOrderPush({ onToast })
      actionLoading = false
      if (result.ok) pushSubscribed = true
    }
  }
</script>

<div class="aoa" data-testid="active-order-accordion-row">
  <div class="aoa__head">
    <button type="button" class="aoa__meta-btn" onclick={onDetail}>
      <span class="aoa__meta">
        {#if row.eta}{row.eta} — {/if}{row.orderNumber}{#if row.metaThird} — {row.metaThird}{/if}
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
    <OrderActionButtons
      status={status}
      os={deviceOs}
      canCancel={canCancel}
      hasPushSubscription={hasPushSubscription}
      isLoading={actionLoading}
      onAction={onAction}
    />
    {#if typeof onDismiss === "function"}
      <button
        type="button"
        class="aoa__dismiss"
        data-testid="status-widget-dismiss"
        aria-label="Скрыть статус заказа"
        title="Скрыть"
        onclick={(e) => {
          e.stopPropagation()
          onDismiss(order)
        }}
      >×</button>
    {/if}
  </div>
  {#if toastMsg}
    <div class="aoa__toast" data-testid="active-order-notify-toast" role="status">{toastMsg}</div>
  {/if}
</div>

<style>
  .aoa {
    padding: 0.3rem 0 0.45rem;
    border-bottom: 1px solid #333;
  }
  .aoa:last-child { border-bottom: 0; }
  .aoa__dismiss {
    flex-shrink: 0;
    width: 1.75rem;
    height: 1.75rem;
    margin: 0;
    padding: 0;
    border: 0;
    border-radius: 999px;
    background: #3a3a3a;
    color: #ddd;
    font-size: 1.15rem;
    line-height: 1;
    cursor: pointer;
  }
  .aoa__dismiss:active { background: #4a4a4a; }
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
  .aoa__toast {
    margin-top: 0.25rem;
    font-size: 0.62rem;
    color: #ffb74d;
  }
</style>
