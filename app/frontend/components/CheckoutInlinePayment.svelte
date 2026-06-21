<script>
  import { onDestroy } from "svelte"
  import { api } from "../lib/api.js"
  import { embedPaymentUrlIframe, openTbankIframe } from "../lib/tbankPayment.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"
  import { createSettlementWatch, persistInlineSession } from "../lib/shopCheckoutInlinePay.js"

  let {
    session = null,
    awaitingOnly = false,
    onSettled = () => {},
    onFail = () => {}
  } = $props()

  let iframeHost = $state(null)
  let iframeStarted = $state(false)
  let destroyed = $state(false)
  let settled = $state(false)
  let stopWatch = () => {}

  function handleSettled() {
    if (settled || destroyed) return
    settled = true
    stopWatch()
    onSettled()
  }

  function beginWatch() {
    stopWatch()
    if (!session?.order_id) return
    stopWatch = createSettlementWatch(api, {
      orderId: session.order_id,
      reconnectToken: session.reconnect_token,
      subscribe: subscribeGuestOrderStatus,
      shouldRun: () => !destroyed && !settled,
      onSettled: handleSettled
    })
  }

  async function mountIframe() {
    if (iframeStarted || !iframeHost || !session?.payment_url || awaitingOnly) return
    iframeStarted = true

    if (session.terminal_key) {
      try {
        await openTbankIframe({
          container: iframeHost,
          terminalKey:         session.terminal_key,
          paymentUrl: session.payment_url,
          scriptUrl: session.integration_script_url,
          onStatusChange: (mapped) => {
            if (destroyed) return
            if (mapped === "success") handleSettled()
            else if (mapped === "fail") onFail("Оплата отклонена")
          }
        })
        persistInlineSession(session, { started: true })
        beginWatch()
        return
      } catch (e) {
        console.warn("[CheckoutInline] integration.js failed, embed fallback", e)
      }
    }

    embedPaymentUrlIframe(iframeHost, session.payment_url)
    persistInlineSession(session, { started: true })
    beginWatch()
  }

  $effect(() => {
    if (!session?.order_id) return
    beginWatch()
    if (!awaitingOnly && iframeHost && !iframeStarted) {
      mountIframe().catch((e) => onFail(e.message || "Не удалось открыть оплату"))
    }
  })

  onDestroy(() => {
    destroyed = true
    stopWatch()
  })
</script>

{#if session && !awaitingOnly}
  <div class="payment-shell payment-shell--visible payment-shell--card" data-testid="checkout-inline-payment">
    <div class="payment-shell__chrome">
      <p class="payment-shell__title">Введите данные карты</p>
      <p class="payment-shell__hint">Защищённое соединение · CoffeeOS</p>
    </div>
    <div bind:this={iframeHost} class="payment-shell__host" aria-label="Защищённая форма оплаты"></div>
  </div>
{/if}

<style>
  .payment-shell {
    position: relative;
    overflow: hidden;
    border-radius: 0.75rem;
    border: 1px solid #3a3a3a;
    background: #1a1a1a;
    margin-top: 1rem;
    min-height: 420px;
  }

  .payment-shell__chrome {
    border-bottom: 1px solid #3a3a3a;
    background: #1a1a1a;
    padding: 0.875rem 1rem;
  }

  .payment-shell__title {
    margin: 0;
    font-size: 0.9375rem;
    font-weight: 600;
    color: #fff;
  }

  .payment-shell__hint {
    margin: 0.25rem 0 0;
    font-size: 0.75rem;
    color: #888;
  }

  .payment-shell__host {
    position: relative;
    min-height: 360px;
    background: #1a1a1a;
  }

  .payment-shell--card .payment-shell__host::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 9.5rem;
    z-index: 2;
    pointer-events: auto;
    background: linear-gradient(#1a1a1a 85%, rgb(26 26 26 / 0));
  }

  .payment-shell--card .payment-shell__host :global(.shop-payment-iframe),
  .payment-shell--card .payment-shell__host :global(iframe) {
    display: block;
    width: 100%;
    min-height: 360px;
    margin-top: -9rem;
    padding-top: 9rem;
    border: 0;
    background: #1a1a1a !important;
    color-scheme: dark;
  }
</style>
