<script>
  import { onMount, onDestroy, tick } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    clearPaymentSession,
    loadPaymentSession,
    openTbankIframe,
    redirectToPaymentUrl
  } from "../lib/tbankPayment.js"
  import { reconnectGuestOrder, saveGuestOrderSession } from "../lib/shopGuestSession.js"

  let phase = $state("loading")
  let err = $state(null)
  let session = $state(null)
  let iframeHost = $state(null)
  let cancelling = $state(false)
  let finished = $state(false)
  let iframeStarted = $state(false)

  async function finishSuccess() {
    if (finished) return
    finished = true
    clearPaymentSession()
    push(`/payment-result?status=success&order_id=${session.order_id}`)
  }

  async function finishFail(reason = "fail") {
    if (finished) return
    finished = true
    clearPaymentSession()
    push(`/payment-result?status=${reason}&order_id=${session.order_id}`)
  }

  async function cancelPayment() {
    if (cancelling || finished || !session?.order_id) return
    cancelling = true
    try {
      await reconnectGuestOrder(api)
      await api(`/orders/${session.order_id}/abandon`, { method: "POST" })
    } catch (e) {
      err = e.message
      cancelling = false
      return
    }
    await finishFail("cancel")
  }

  async function startIframe() {
    if (iframeStarted || !iframeHost || !session?.provider_payment_id || !session?.terminal_key) return
    iframeStarted = true

    await openTbankIframe({
      container: iframeHost,
      terminalKey: session.terminal_key,
      paymentId: session.provider_payment_id,
      scriptUrl: session.integration_script_url,
      onStatusChange: (mapped) => {
        if (mapped === "success") finishSuccess()
        else if (mapped === "fail") finishFail("fail")
      }
    })
    phase = "paying"
  }

  $effect(() => {
    if (session?.payment_iframe && iframeHost && phase === "loading" && !iframeStarted) {
      startIframe().catch((e) => {
        if (session.payment_url) {
          redirectToPaymentUrl(session.payment_url)
          return
        }
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
        reconnect_token: params.get("reconnect_token")
      }
    }

    if (!data?.order_id) {
      err = "Сессия оплаты не найдена"
      phase = "error"
      return
    }

    session = data
    saveGuestOrderSession(data.order_id, data.reconnect_token)
    await reconnectGuestOrder(api)

    if (data.payment_iframe && data.provider_payment_id && data.terminal_key) {
      await tick()
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
    finished = true
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
{:else}
  <div class="mb-4 flex items-center justify-between gap-3">
    <div>
      <h1 class="text-xl font-bold">{phase === "loading" ? "Идёт оплата…" : "Оплата"}</h1>
      <p class="text-xs text-[#888]">Корзина → Оформление → Оплата → Результат</p>
    </div>
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
    <p class="mb-3 text-sm text-[#a0a0a0]">К оплате: {Math.round(session.total)}₽</p>
  {/if}

  {#if phase === "loading"}
    <p class="mb-4 text-center text-sm text-[#a0a0a0]">Подключаем защищённую форму Т‑Банка…</p>
  {/if}

  <div
    bind:this={iframeHost}
    class="min-h-[420px] overflow-hidden rounded-xl border border-[#3a3a3a] bg-[#111]"
    aria-label="Форма оплаты Т-Банк"
  ></div>

  <p class="mt-3 text-center text-xs text-[#666]">Оплата через Т‑Банк. Не закрывайте страницу до завершения.</p>
{/if}
