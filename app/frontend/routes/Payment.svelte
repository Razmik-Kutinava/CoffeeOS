<script>
  import { onMount, onDestroy, tick } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    clearPaymentSession,
    loadPaymentSession,
    savePaymentSession,
    embedPaymentUrlIframe,
    openTbankIframe,
    PAYMENT_METHOD_LABELS,
    redirectToPaymentUrl
  } from "../lib/tbankPayment.js"
  import { reconnectGuestOrder, saveGuestOrderSession, guestReconnectToken } from "../lib/shopGuestSession.js"
  import { subscribeGuestOrderStatus } from "../lib/shopOrderCable.js"

  const SETTLE_POLL_MS = 1500

  let phase = $state("intro")
  let err = $state(null)
  let session = $state(null)
  let iframeHost = $state(null)
  let cancelling = $state(false)
  let finished = $state(false)
  let destroyed = $state(false)
  let iframeStarted = $state(false)
  let stopSettlementWatch = () => {}

  const methodLabel = $derived(
    PAYMENT_METHOD_LABELS[session?.payment_method] || PAYMENT_METHOD_LABELS.card
  )

  async function finishSuccess() {
    if (finished || destroyed) return
    finished = true
    const orderId = session?.order_id
    const bound = session?.card_binding ? "&bound=1" : ""
    clearPaymentSession()
    push(`/payment-result?status=success&order_id=${orderId}${bound}`)
  }

  async function finishFail(reason = "fail") {
    if (finished || destroyed) return
    finished = true
    const orderId = session?.order_id
    clearPaymentSession()
    push(`/payment-result?status=${reason}&order_id=${orderId}`)
  }

  async function cancelPayment() {
    const orderId = session?.order_id
    if (cancelling || finished || destroyed || !orderId) return

    cancelling = true
    err = null
    const reconnectToken = session?.reconnect_token || guestReconnectToken()

    try {
      await reconnectGuestOrder(api)
      await api(`/orders/${orderId}/abandon`, {
        method: "POST",
        body: JSON.stringify({ reconnect_token: reconnectToken })
      })
      finished = true
      clearPaymentSession()
      push(`/payment-result?status=cancel&order_id=${orderId}`)
    } catch (e) {
      err = e.message || "Не удалось отменить заказ"
    } finally {
      cancelling = false
    }
  }

  function continueToPay() {
    if (phase !== "intro") return
    phase = "loading"
  }

  function markPaymentStarted() {
    if (!session) return
    const next = { ...session, payment_started: true }
    session = next
    savePaymentSession(next)
  }

  async function tryImmediateSettle(orderId, reconnectToken) {
    const q = reconnectToken ? `?reconnect_token=${encodeURIComponent(reconnectToken)}` : ""
    const res = await api(`/orders/${orderId}/finalize${q}`, { method: "POST" })
    if (res.payment_settled || res.status === "accepted") {
      finishSuccess()
      return true
    }
    return false
  }

  /** Webhook → accepted: polling finalize + cable, если iframe не шлёт success (fallback embed / 3DS). */
  function beginSettlementWatch() {
    stopSettlementWatch()
    const orderId = session?.order_id
    const reconnectToken = session?.reconnect_token || guestReconnectToken()
    if (!orderId) return

    let active = true
    const unsubCable = subscribeGuestOrderStatus({
      orderId,
      reconnectToken,
      onStatus: (payload) => {
        if (destroyed || finished || !active) return
        if (payload?.payment_settled || payload?.status === "accepted") {
          finishSuccess()
        }
      }
    })

    const timer = setInterval(async () => {
      if (destroyed || finished || !active) return
      if (phase !== "paying" && phase !== "awaiting_settlement") return
      try {
        const q = reconnectToken ? `?reconnect_token=${encodeURIComponent(reconnectToken)}` : ""
        const res = await api(`/orders/${orderId}/finalize${q}`, { method: "POST" })
        if (res.payment_settled || res.status === "accepted") {
          finishSuccess()
        }
      } catch {
        /* webhook ещё не пришёл */
      }
    }, SETTLE_POLL_MS)

    stopSettlementWatch = () => {
      active = false
      clearInterval(timer)
      unsubCable()
    }
  }

  async function startIframe() {
    if (iframeStarted || !iframeHost) return
    if (!session?.payment_url) throw new Error("Нет данных для оплаты")

    iframeStarted = true

    if (session?.terminal_key) {
      try {
        await openTbankIframe({
          container: iframeHost,
          terminalKey: session.terminal_key,
          paymentUrl: session.payment_url,
          scriptUrl: session.integration_script_url,
          onStatusChange: (mapped) => {
            if (destroyed) return
            if (mapped === "success") finishSuccess()
            else if (mapped === "fail") finishFail("fail")
          }
        })
        phase = "paying"
        markPaymentStarted()
        beginSettlementWatch()
        return
      } catch (e) {
        console.warn("[Payment] integration.js mount failed, fallback to PaymentURL embed", e)
      }
    }

    embedPaymentUrlIframe(iframeHost, session.payment_url)
    phase = "paying"
    markPaymentStarted()
    beginSettlementWatch()
  }

  $effect(() => {
    if (session && iframeHost && phase === "loading" && !iframeStarted) {
      startIframe().catch((e) => {
        err = e.message
        phase = "error"
      })
    }
  })

  onMount(async () => {
    const query = window.location.hash.split("?")[1] || ""
    const params = new URLSearchParams(query)
    let data = loadPaymentSession()

    if (!data && params.get("order_id")) {
      data = {
        order_id: params.get("order_id"),
        provider_payment_id: params.get("provider_payment_id"),
        terminal_key: params.get("terminal_key"),
        payment_url: params.get("payment_url"),
        reconnect_token: params.get("reconnect_token"),
        payment_method: params.get("payment_method") || "card"
      }
    }

    if (!data?.order_id) {
      err = "Сессия оплаты не найдена"
      phase = "error"
      return
    }

    session = { payment_method: "card", ...data }
    saveGuestOrderSession(data.order_id, data.reconnect_token)
    await reconnectGuestOrder(api)

    if (data.payment_iframe && data.payment_url) {
      if (data.payment_started) {
        phase = "awaiting_settlement"
        beginSettlementWatch()
        try {
          await tryImmediateSettle(data.order_id, data.reconnect_token || guestReconnectToken())
        } catch {
          /* webhook ещё не пришёл после 3DS return */
        }
      }
      return
    }

    if (data.payment_url) {
      redirectToPaymentUrl(data.payment_url)
      return
    }

    err = "Оплата недоступна"
    phase = "error"
  })

  onDestroy(() => {
    destroyed = true
    stopSettlementWatch()
  })
</script>

{#if phase === "error"}
  <div class="py-8 text-center">
    <p class="mb-4 text-red-400">{err || "Ошибка оплаты"}</p>
    <div class="flex flex-col gap-3">
      <button type="button" class="rounded-xl bg-[#ff8c42] py-3 font-semibold text-black" onclick={() => push("/cart")}>
        В корзину
      </button>
      <button type="button" class="rounded-xl border border-[#3a3a3a] py-3 text-[#a0a0a0]" onclick={() => push("/checkout")}>
        Оформление
      </button>
    </div>
  </div>
{:else if phase === "intro"}
  <div class="mb-4 flex items-center gap-3">
    <button type="button" class="text-2xl text-[#ff8c42]" onclick={() => push("/checkout")} aria-label="Назад">
      ‹
    </button>
    <h1 class="text-xl font-bold">Оплата</h1>
  </div>

  <div class="mb-4 rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-4">
    <p class="mb-1 text-sm text-[#a0a0a0]">Заказ #{session?.order_id}</p>
    {#if session?.total}
      <p class="mb-3 text-2xl font-bold text-white">{Math.round(session.total)}₽</p>
    {/if}
    <span class="inline-block rounded-lg border border-[#ff8c42] bg-[#ff8c42]/10 px-3 py-1 text-sm text-[#ff8c42]">
      {methodLabel}
    </span>
  </div>

  <p class="mb-4 text-sm text-[#a0a0a0]">
    {#if session?.payment_method === "sbp"}
      Нажмите кнопку — откроется оплата через СБП. Данные карты вводятся в защищённой форме банка.
    {:else if session?.card_binding}
      Нажмите кнопку — откроется защищённая форма CoffeeOS. После успешной оплаты карта сохранится для следующих заказов.
    {:else}
      Нажмите кнопку — откроется защищённая форма. Брендинг банка скрыт, интерфейс CoffeeOS.
    {/if}
  </p>

  {#if err}
    <p class="mb-4 rounded-lg border border-red-500/40 bg-red-500/10 px-3 py-2 text-sm text-red-400" role="alert">
      {err}
    </p>
  {/if}

  <button
    type="button"
    class="mb-3 w-full rounded-xl bg-[#ff8c42] py-4 text-lg font-semibold text-black"
    onclick={continueToPay}
  >
    Оплатить {session?.total ? `${Math.round(session.total)}₽` : ""}
  </button>

  <button
    type="button"
    class="w-full rounded-xl border border-[#3a3a3a] py-3 text-[#a0a0a0]"
    onclick={cancelPayment}
    disabled={cancelling}
  >
    {cancelling ? "Отмена…" : "Отменить заказ"}
  </button>
{:else}
  <div class="mb-4 flex items-center justify-between gap-3">
    <h1 class="text-xl font-bold">
      {phase === "loading" ? "Подключаем оплату…" : phase === "awaiting_settlement" ? "Проверяем оплату…" : "Оплата"}
    </h1>
    {#if phase === "paying"}
      <button
        type="button"
        class="rounded-lg border border-[#3a3a3a] px-3 py-2 text-sm text-[#a0a0a0] disabled:opacity-50"
        disabled={cancelling}
        onclick={cancelPayment}
      >
        {cancelling ? "Отмена…" : "Отмена"}
      </button>
    {/if}
  </div>

  {#if session?.total}
    <div class="mb-3 flex items-center justify-between rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] px-4 py-3">
      <span class="text-sm text-[#a0a0a0]">К оплате</span>
      <span class="text-lg font-bold text-[#ff8c42]">{Math.round(session.total)}₽</span>
    </div>
  {/if}

  {#if phase === "loading" || phase === "awaiting_settlement"}
    <div class="mb-4 flex flex-col items-center gap-3 py-8">
      <div class="payment-spinner" aria-hidden="true"></div>
      <p class="text-sm text-[#a0a0a0]">
        {phase === "awaiting_settlement" ? "Проверяем оплату…" : "Подключаем защищённую форму…"}
      </p>
      <button
        type="button"
        class="mt-2 rounded-xl border border-[#3a3a3a] px-4 py-2 text-sm text-[#a0a0a0] disabled:opacity-50"
        disabled={cancelling}
        onclick={cancelPayment}
      >
        {cancelling ? "Отмена…" : "Отменить заказ"}
      </button>
    </div>
  {/if}

  {#if err}
    <p class="mb-4 rounded-lg border border-red-500/40 bg-red-500/10 px-3 py-2 text-sm text-red-400" role="alert">
      {err}
    </p>
  {/if}

  <div
    class="payment-shell"
    class:payment-shell--visible={phase === "paying"}
    class:payment-shell--card={phase === "paying" && session?.payment_method !== "sbp"}
  >
    {#if phase === "paying" && session?.payment_method !== "sbp"}
      <div class="payment-shell__chrome">
        <p class="payment-shell__title">Введите данные карты</p>
        <p class="payment-shell__hint">Защищённое соединение · CoffeeOS</p>
      </div>
    {:else if phase === "paying" && session?.payment_method === "sbp"}
      <div class="payment-shell__chrome">
        <p class="payment-shell__title">Оплата через СБП</p>
        <p class="payment-shell__hint">Выберите банк в форме ниже</p>
      </div>
    {/if}

    <div
      bind:this={iframeHost}
      class="payment-shell__host"
      class:payment-shell__host--hidden={phase === "loading"}
      aria-label="Защищённая форма оплаты"
    ></div>
  </div>

  <p class="mt-3 text-center text-xs text-[#666]">Не закрывайте страницу до завершения оплаты.</p>
{/if}

<style>
  .payment-spinner {
    width: 2rem;
    height: 2rem;
    border: 3px solid #3a3a3a;
    border-top-color: #ff8c42;
    border-radius: 50%;
    animation: payment-spin 0.8s linear infinite;
  }

  @keyframes payment-spin {
    to {
      transform: rotate(360deg);
    }
  }

  .payment-shell {
    position: relative;
    overflow: hidden;
    border-radius: 0.75rem;
    border: 1px solid #3a3a3a;
    background: #1a1a1a;
    opacity: 0;
    pointer-events: none;
    min-height: 0;
  }

  .payment-shell--visible {
    opacity: 1;
    pointer-events: auto;
    min-height: 420px;
  }

  .payment-shell__chrome {
    position: relative;
    z-index: 3;
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

  .payment-shell__host--hidden {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    opacity: 0;
    pointer-events: none;
  }

  /* Маска: перекрываем жёлтые T-Pay / SberPay (оплата картой) */
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

  .payment-shell--visible:not(.payment-shell--card) .payment-shell__host :global(.shop-payment-iframe),
  .payment-shell--visible:not(.payment-shell--card) .payment-shell__host :global(iframe) {
    display: block;
    width: 100%;
    min-height: 360px;
    border: 0;
    background: #1a1a1a !important;
    color-scheme: dark;
  }
</style>
