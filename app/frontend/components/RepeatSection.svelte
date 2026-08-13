<script>
  import { onMount } from "svelte"
  import {
    frequentItems,
    frequentQuantities,
    frequentCardKey,
    setFrequentQty,
    repeatFeedback
  } from "../lib/frequentRepeatStore.js"
  import { repeatBumpEmbeddedToCart } from "../lib/repeatEmbeddedCart.js"
  import { createWidgetPayFsm } from "../lib/shopWidgetPayFsm.js"
  import {
    runRepeatWidgetPayFlow,
    resolveCardDeclineFallbackUi,
    resolveNetworkRetryUi
  } from "../lib/widgetRepeatPayFlow.js"
  import { createRepeatInlineOrder } from "../lib/createRepeatInlineOrder.js"
  import {
    INLINE_ROTATION_LABELS,
    classifyInlinePayErrorLabel,
    INLINE_NETWORK_ERROR_LABEL
  } from "../lib/shopInlinePayFsm.js"
  import {
    repeatInlinePayUi,
    patchRepeatInlinePayUi,
    resetRepeatInlinePayUi
  } from "../lib/repeatInlinePayUiStore.js"
  import { initSbpPayment, redirectToSbp } from "../lib/shopSbpPay.js"
  import { api } from "../lib/api.js"
  import {
    setTokenInvalid,
    isInvalidRebillPaymentError
  } from "../lib/repeatInvalidTokenStore.js"
  import { openRepeatPaymentSheet } from "../lib/openRepeatPaymentSheet.js"
  import InlinePayFallback from "./InlinePayFallback.svelte"

  /** full — empty; embedded — peek с заказом */
  let { layout = "full" } = $props()

  let items = $state([])
  let storeQty = $state({})
  let brokenUrls = $state(/** @type {Set<string>} */ (new Set()))
  let feedback = $state(null)
  let toastTimer = null
  let payUi = $state(/** @type {any} */ ({}))

  let topItems = $derived(items.slice(0, 3))
  let embedded = $derived(layout === "embedded")
  let repeatBusy = $derived(!!payUi.busy)

  onMount(() => {
    const unsubItems = frequentItems.subscribe((v) => { items = Array.isArray(v) ? v : [] })
    const unsubQty = frequentQuantities.subscribe((v) => { storeQty = v || {} })
    const unsubPay = repeatInlinePayUi.subscribe((v) => { payUi = v || {} })
    const unsubFeedback = repeatFeedback.subscribe((v) => {
      feedback = v
      if (toastTimer) clearTimeout(toastTimer)
      if (v) toastTimer = setTimeout(() => repeatFeedback.set(null), 2500)
    })
    return () => {
      unsubItems(); unsubQty(); unsubPay(); unsubFeedback()
      if (toastTimer) clearTimeout(toastTimer)
    }
  })

  function qtyOf(key) {
    return storeQty[key] || 1
  }

  async function bump(item, delta) {
    const key = frequentCardKey(item)
    if (embedded) {
      if (repeatBusy) return
      patchRepeatInlinePayUi({ busy: true })
      try {
        await repeatBumpEmbeddedToCart(item, delta)
      } finally {
        patchRepeatInlinePayUi({ busy: false })
      }
      return
    }
    setFrequentQty(key, qtyOf(key) + delta)
  }

  function itemByActiveKey() {
    return items.find((i) => frequentCardKey(i) === payUi.activeKey) || items[0] || null
  }

  function markInvalidTokenFromPay(out) {
    const code = out?.error_code || out?.fsm?.error_code || ""
    const cardId = out?.cardId
    if (cardId && isInvalidRebillPaymentError({ error_code: code })) {
      setTokenInvalid(cardId)
    }
  }

  async function onPayCardClick(item) {
    if (payUi.busy) return
    const key = frequentCardKey(item)
    const fsm = createWidgetPayFsm()
    fsm.start()
    patchRepeatInlinePayUi({
      busy: true,
      activeKey: key,
      fsm,
      statusText: INLINE_ROTATION_LABELS[0],
      errorText: "",
      showFallbackMethods: false,
      showExpandedCards: false,
      showNewCardForm: false,
      savedCards: []
    })

    try {
      const { orderId } = await createRepeatInlineOrder(item, {
        api,
        quantities: storeQty
      })
      fsm.orderId = orderId
      const out = await runRepeatWidgetPayFlow({
        orderId,
        api,
        fsm,
        onStatusText: (label) => patchRepeatInlinePayUi({ statusText: label })
      })
      markInvalidTokenFromPay(out)
      patchRepeatInlinePayUi({
        fsm: out.fsm,
        statusText: out.statusText,
        errorText: out.errorText,
        showFallbackMethods: out.showFallbackMethods,
        showRetry: !!out.showRetry,
        showExpandedCards: false,
        showNewCardForm: false,
        savedCards: out.savedCards || []
      })
      if (out.openPaymentSheet) {
        await openRepeatPaymentSheet(item, { preferNewCard: true })
        return
      }
      if (out.resetAfterMs) {
        setTimeout(() => resetRepeatInlinePayUi(), out.resetAfterMs)
      }
    } catch (e) {
      fsm.reject({ error_code: e?.error_code || "" })
      fsm.state = "ERROR"
      const msg = classifyInlinePayErrorLabel({
        error: e,
        error_code: e?.error_code,
        message: e?.message
      })
      const ui =
        msg === INLINE_NETWORK_ERROR_LABEL
          ? resolveNetworkRetryUi()
          : resolveCardDeclineFallbackUi()
      // S1: ошибка на экране + СБП/«карта +» или «Повторить»; S2 → PaymentMethodsSheet.
      patchRepeatInlinePayUi({
        fsm,
        errorText: msg,
        statusText: msg,
        ...ui
      })
    } finally {
      patchRepeatInlinePayUi({ busy: false })
    }
  }

  /** Сеть: тот же One-Click flow на активной карточке (без нового payment path). */
  async function onRetryPay() {
    const item = itemByActiveKey()
    if (!item) return
    await onPayCardClick(item)
  }

  async function onFallbackSbp() {
    if (!payUi.fsm?.orderId) return
    try {
      const result = await initSbpPayment(api, { orderId: payUi.fsm.orderId })
      if (result?.payment_url) redirectToSbp(result.payment_url)
    } catch (_e) {
      patchRepeatInlinePayUi({ errorText: "Ошибка инициализации СБП" })
    }
  }

  async function onFallbackCardPlus() {
    // UX: полная PaymentMethodsSheet (скрин 09), не NewCardForm в peek.
    patchRepeatInlinePayUi({
      showExpandedCards: false,
      showNewCardForm: false,
      showFallbackMethods: true
    })
    await openRepeatPaymentSheet(itemByActiveKey(), { preferNewCard: true })
  }

  /** Тап по сохранённой карте в inline — тоже в канон-шторку (не Charge в peek). */
  async function onSelectSavedCard(_card) {
    await openRepeatPaymentSheet(itemByActiveKey(), { preferNewCard: false })
  }

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }
</script>

{#if topItems.length}
  <div
    data-testid="shop-repeat-section"
    data-repeat-layout={layout}
    class="shrink-0 px-1 {embedded ? 'pt-1' : 'pt-1.5'}"
  >
    <p class="mb-1 px-1 text-[11px] italic text-[#888]">повторить</p>
    {#if feedback}
      <div
        data-testid="shop-repeat-toast"
        role="status"
        class="mb-1 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-2 py-1 text-[11px] {feedback.type === 'error' ? 'text-red-400' : 'text-[#ff8c42]'}"
      >{feedback.message}</div>
    {/if}
    <div class="flex gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      {#each topItems as item (frequentCardKey(item))}
        {@const key = frequentCardKey(item)}
        {@const url = item.image_url || ""}
        <div
          data-testid="shop-repeat-card"
          class="flex shrink-0 flex-col gap-1 {embedded ? 'w-[4.5rem]' : 'w-[min(28vw,110px)] rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-1.5'}"
        >
          {#if url && !brokenUrls.has(url)}
            <img
              data-testid="shop-repeat-thumb"
              src={url}
              alt=""
              class="{embedded ? 'h-12 w-12' : 'h-12 w-full'} rounded-lg object-cover object-top"
              decoding="async"
              onerror={() => {
                const next = new Set(brokenUrls)
                next.add(url)
                brokenUrls = next
              }}
            />
          {:else}
            <div
              data-testid="shop-repeat-thumb-empty"
              class="flex {embedded ? 'h-12 w-12' : 'h-12 w-full'} items-center justify-center rounded-lg bg-[#333] text-[9px] text-[#888]"
            >Нет фото</div>
          {/if}
          {#if !embedded}
            <p class="line-clamp-1 text-[11px] font-medium leading-tight">{item.name}</p>
            <p class="text-[10px] text-[#ff8c42]">{roundPrice(item.price)}₽</p>
          {/if}
          <div class="mt-0.5 flex items-center justify-between gap-0.5 {embedded ? 'w-12' : ''}">
            <button
              type="button"
              data-testid="shop-repeat-minus"
              class="min-h-6 min-w-6 rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[12px] leading-none disabled:opacity-40"
              disabled={qtyOf(key) <= 1 || repeatBusy}
              onclick={() => bump(item, -1)}
            >−</button>
            <span data-testid="shop-repeat-qty" class="min-w-[1rem] text-center text-[11px] font-medium">{qtyOf(key)}</span>
            <button
              type="button"
              data-testid="shop-repeat-plus"
              class="min-h-6 min-w-6 rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[12px] leading-none disabled:opacity-40"
              disabled={repeatBusy}
              onclick={() => bump(item, 1)}
            >+</button>
          </div>
          {#if !embedded}
            <button
              type="button"
              data-testid="shop-repeat-card-pay"
              class="mt-0.5 min-h-7 w-full rounded-lg bg-[#ff8c42] px-2 py-1 text-[10px] font-semibold text-black disabled:opacity-40"
              disabled={repeatBusy}
              onclick={() => onPayCardClick(item)}
            >оплатить в 1 клик</button>
          {/if}
        </div>
      {/each}
    </div>
    {#if payUi.activeKey}
      <!-- Полная ширина: внутри карточки (embedded 4.5rem) плашка обрезалась -->
      <div class="mt-1.5 w-full min-w-0 px-0.5" data-testid="shop-repeat-inline-pay-slot">
        <InlinePayFallback
          fsmState={payUi.fsm?.state}
          statusText={payUi.statusText || ""}
          errorText={payUi.errorText || ""}
          savedCards={payUi.savedCards || []}
          showFallbackMethods={!!payUi.showFallbackMethods}
          showExpandedCards={!!payUi.showExpandedCards}
          showNewCardForm={!!payUi.showNewCardForm}
          showRetry={!!payUi.showRetry}
          onSelectSbp={onFallbackSbp}
          onSelectCardPlus={onFallbackCardPlus}
          onSelectSavedCard={onSelectSavedCard}
          onRetry={onRetryPay}
        />
      </div>
    {/if}
  </div>
{/if}
