<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    checkoutPaymentMode,
    checkoutPaymentItems,
    checkoutPaymentTotal,
    checkoutPaymentLimitError,
    bindCheckoutPaymentCart,
    expandSheet,
    collapseToPeek,
    openPaymentList,
    closePaymentList,
    assertCanAddCard
  } from "../lib/checkoutPaymentSheetStore.js"
  import {
    MODE_PEEK,
    MODE_EXPANDED,
    MODE_EXPANDED_PLUS,
    SHEET_TRANSITION_MS,
    SWIPE_UP_PX,
    sheetHeightVh
  } from "../lib/checkoutPaymentSheetThresholds.js"
  import {
    bumpCartLine,
    removeCartLine,
    openEditCard,
    atMinQty,
    atMaxQty
  } from "../lib/cartSheetStore.js"
  import { formatCardListLabel } from "../lib/paymentMethodLabels.js"

  let {
    emailVerified = false,
    savedCards = [],
    hasSavedCard = false,
    cardLabel = null,
    selectedCardId = null,
    canPay = false,
    onPay = () => {},
    onSelectCard = () => {},
    onSelectNewCard = () => {},
    onAddCard = () => {}
  } = $props()

  let mode = $state(MODE_PEEK)
  let items = $state([])
  let total = $state(0)
  let limitError = $state(null)
  let gestureStartY = 0

  const count = $derived(items.length)
  const heightVh = $derived(sheetHeightVh(mode, count))
  const footerLocked = $derived(!emailVerified)
  const payEnabled = $derived(
    emailVerified && (hasSavedCard || savedCards.length > 0) && canPay
  )
  const cardPlusEnabled = $derived(emailVerified)
  /** 1–2: полные карточки (s02/s03); ≥3: миниатюры (s01) */
  const peekFullCards = $derived(count > 0 && count <= 2)

  onMount(() => {
    bindCheckoutPaymentCart()
    const u1 = checkoutPaymentMode.subscribe((v) => { mode = v })
    const u2 = checkoutPaymentItems.subscribe((v) => { items = v })
    const u3 = checkoutPaymentTotal.subscribe((v) => { total = v })
    const u4 = checkoutPaymentLimitError.subscribe((v) => { limitError = v })
    return () => { u1(); u2(); u3(); u4() }
  })

  function lineName(line) {
    return line?.product_name || line?.name || ""
  }

  function unitPrice(line) {
    const unit = Number(line?.unit_total)
    if (Number.isFinite(unit) && unit > 0) return Math.round(unit)
    const qty = Math.max(1, Number(line?.quantity) || 1)
    return Math.round(Number(line?.line_total) / qty) || 0
  }

  function modifierLines(line) {
    return (line?.selected_modifiers || []).map((m) => m.name).filter(Boolean)
  }

  function modifiersLabel(line) {
    return modifierLines(line).join(", ")
  }

  function handleCardPlus() {
    if (!cardPlusEnabled) return
    if (!assertCanAddCard(savedCards.length)) return
    onSelectNewCard()
    onAddCard()
  }

  function handlePayClick() {
    if (footerLocked || !payEnabled) return
    onPay()
  }

  function handleImageClick(line) {
    const path = openEditCard(line)
    if (path && path !== "/") push(path)
  }

  function onGestureStart(e) {
    gestureStartY = e.touches?.[0]?.clientY ?? e.clientY ?? 0
  }

  function onGestureEnd(e) {
    const endY = e.changedTouches?.[0]?.clientY ?? e.clientY ?? 0
    const delta = gestureStartY - endY
    if (delta >= SWIPE_UP_PX) {
      if (mode === MODE_PEEK) expandSheet()
      else if (mode === MODE_EXPANDED) openPaymentList()
    } else if (delta <= -SWIPE_UP_PX) {
      if (mode === MODE_EXPANDED_PLUS) closePaymentList()
      else if (mode === MODE_EXPANDED) collapseToPeek()
    }
  }
</script>

{#if !items.length}
  <div class="hidden" data-testid="checkout-payment-empty" aria-hidden="true"></div>
{:else}
  <div
    data-testid="checkout-payment-sheet"
    data-checkout-sheet-mode={mode === "peek" ? "peek" : mode}
    class="checkout-payment-sheet fixed bottom-0 left-0 right-0 z-50 mx-auto flex max-w-lg flex-col overflow-hidden rounded-t-2xl border-t border-[#3a3a3a] bg-[#2a2a2a]"
    style="height: {heightVh}vh; transition: height {SHEET_TRANSITION_MS}ms ease-out;"
  >
    <div
      class="flex shrink-0 justify-center py-2"
      data-testid="checkout-payment-gesture-zone"
      ontouchstart={onGestureStart}
      ontouchend={onGestureEnd}
      onmousedown={onGestureStart}
      onmouseup={onGestureEnd}
      role="presentation"
    >
      <div class="h-1 w-10 rounded-full bg-[#555]"></div>
    </div>

    {#if limitError}
      <p class="px-3 pb-1 text-sm text-red-400" data-testid="checkout-payment-card-limit-error" role="alert">
        {limitError}
      </p>
    {/if}

    {#if mode === MODE_EXPANDED_PLUS}
      <div class="flex min-h-0 flex-1 flex-col" data-testid="checkout-payment-expanded-plus">
        <div class="flex items-center justify-between px-3 pb-2">
          <h2 class="text-base font-semibold text-white">Способ оплаты</h2>
          <button type="button" class="text-[#a0a0a0]" data-testid="checkout-payment-close" onclick={() => closePaymentList()} aria-label="Закрыть">✕</button>
        </div>
        <div class="mb-2 flex gap-2 overflow-x-auto px-3" style="overflow-x: auto; touch-action: pan-x;">
          {#each items.slice(0, 2) as line}
            <img src={line.image_url || ""} alt="" class="h-14 w-14 shrink-0 rounded-lg object-cover bg-[#1a1a1a]" />
          {/each}
        </div>
        <div class="min-h-0 flex-1 space-y-2 overflow-y-auto px-3" data-testid="checkout-payment-list">
          {#each savedCards as card}
            <div
              role="button"
              tabindex="0"
              class="flex w-full items-center justify-between rounded-xl border px-3 py-3 text-left cursor-pointer {selectedCardId === card.id ? 'border-[#ff8c42] text-[#ff8c42]' : 'border-[#3a3a3a] text-white'}"
              onclick={() => onSelectCard(card)}
              onkeydown={(e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onSelectCard(card) } }}
            >
              <span>{formatCardListLabel(card)}</span>
            </div>
          {/each}
          <button type="button" class="w-full rounded-xl border border-[#3a3a3a] px-3 py-3 text-[#888]" disabled data-testid="checkout-payment-sbp-list">СБП</button>
          <button type="button" class="w-full rounded-xl border border-[#ff8c42] px-3 py-3 text-[#ff8c42]" onclick={handleCardPlus}>Картой +</button>
        </div>
        <div class="shrink-0 p-3">
          <button
            type="button"
            class="w-full rounded-xl bg-[#ff8c42] py-3 font-semibold text-black disabled:opacity-40"
            data-testid="checkout-payment-pay"
            disabled={footerLocked || !payEnabled}
            onclick={handlePayClick}
          >Оплатить</button>
        </div>
      </div>

    {:else if mode === MODE_EXPANDED}
      <div class="flex min-h-0 flex-1 flex-col" data-testid="checkout-payment-expanded">
        <div class="min-h-0 flex-1 space-y-2 overflow-y-auto px-3">
          {#each items as line}
            <div class="flex gap-3 rounded-xl bg-[#1f1f1f] p-2">
              <button type="button" class="shrink-0" onclick={() => handleImageClick(line)}>
                <img
                  src={line.image_url || ""}
                  alt=""
                  class="h-16 w-16 rounded-lg object-cover"
                  data-testid="checkout-payment-expanded-product-image"
                />
              </button>
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm text-white">{lineName(line)}</p>
                <p class="text-xs text-[#888]">{unitPrice(line)}₽ × {line.quantity}</p>
                {#if modifiersLabel(line)}
                  <p class="text-xs text-[#888]">{modifiersLabel(line)}</p>
                {/if}
                <div class="mt-1 flex items-center gap-2">
                  <button type="button" disabled={atMinQty(line)} onclick={() => bumpCartLine(line.index, -1)}>−</button>
                  <span>{line.quantity}</span>
                  <button type="button" disabled={atMaxQty(line)} onclick={() => bumpCartLine(line.index, 1)}>+</button>
                  <button type="button" class="text-xs text-red-400" onclick={() => removeCartLine(line.index)}>Удалить</button>
                </div>
              </div>
            </div>
          {/each}
        </div>
        <div class="shrink-0 space-y-2 border-t border-[#3a3a3a] p-3">
          <button type="button" class="w-full rounded-xl border border-[#3a3a3a] py-2 text-left text-white" onclick={() => openPaymentList()}>
            Способ оплаты: {cardLabel || (hasSavedCard ? "Картой" : "Выберите")}
          </button>
          <div class="flex gap-2">
            <button type="button" class="flex-1 rounded-2xl border border-[#555] bg-[#1f1f1f] py-2.5 text-sm text-[#888]" data-testid="checkout-payment-sbp" disabled>СБП</button>
            <button type="button" class="flex-1 rounded-2xl border-2 border-[#ff8c42] bg-transparent py-2.5 text-sm font-medium text-[#ff8c42] disabled:border-[#ff8c42]/55 disabled:text-[#ff8c42]/55" data-testid="checkout-payment-card-plus" disabled={!cardPlusEnabled} onclick={handleCardPlus}>Картой +</button>
            <button type="button" class="flex-[1.35] rounded-2xl bg-[#ff8c42] py-2.5 text-sm font-semibold text-black disabled:bg-[#ff8c42]/45 disabled:text-black/50" data-testid="checkout-payment-pay" disabled={footerLocked || !payEnabled} onclick={handlePayClick}>оплатить</button>
          </div>
        </div>
      </div>

    {:else}
      <div class="flex min-h-0 flex-1 flex-col">
        {#if peekFullCards}
          <div
            class="min-h-0 flex-1 space-y-2 overflow-y-auto px-3"
            data-testid={count === 1 ? "checkout-payment-peek-single" : "checkout-payment-peek-two"}
          >
            {#each items as line}
              <div class="flex gap-3 rounded-xl bg-[#1f1f1f] p-2" data-testid="checkout-payment-peek-full-card">
                <button type="button" class="shrink-0" onclick={() => handleImageClick(line)}>
                  {#if line.image_url}
                    <img
                      src={line.image_url}
                      alt=""
                      class="h-20 w-20 rounded-lg object-cover bg-[#1a1a1a]"
                      data-testid="checkout-payment-peek-image"
                    />
                  {:else}
                    <div
                      class="flex h-20 w-20 items-center justify-center rounded-lg bg-[#1a1a1a] text-[10px] text-[#666]"
                      data-testid="checkout-payment-peek-image-empty"
                    >нет</div>
                  {/if}
                </button>
                <div class="min-w-0 flex-1">
                  <p class="line-clamp-2 text-sm text-white" data-testid="checkout-payment-peek-name">{lineName(line)}</p>
                  <p class="text-xs text-[#888]" data-testid="checkout-payment-peek-price">{unitPrice(line)}₽ × {line.quantity}</p>
                  {#each modifierLines(line) as modName}
                    <p class="text-xs text-[#888]" data-testid="checkout-payment-peek-modifier">{modName}</p>
                  {/each}
                  {#if line.description}
                    <p class="line-clamp-2 text-xs text-[#888]" data-testid="checkout-payment-peek-description">{line.description}</p>
                  {/if}
                  <div class="mt-1 flex items-center gap-2">
                    <button type="button" data-testid="checkout-payment-peek-minus" disabled={atMinQty(line)} onclick={() => bumpCartLine(line.index, -1)}>−</button>
                    <span>{line.quantity}</span>
                    <button type="button" data-testid="checkout-payment-peek-plus" disabled={atMaxQty(line)} onclick={() => bumpCartLine(line.index, 1)}>+</button>
                    <button type="button" class="text-xs text-red-400" data-testid="checkout-payment-peek-remove" onclick={() => removeCartLine(line.index)}>Удалить</button>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <div
            class="flex gap-2 px-3 pb-2"
            data-testid="checkout-payment-peek-multi"
            style="overflow-x: auto; touch-action: pan-x;"
          >
            {#each items as line}
              <div class="w-[28vw] shrink-0" data-testid="checkout-payment-peek-thumb">
                {#if line.image_url}
                  <img src={line.image_url} alt="" class="mb-1 aspect-square w-full rounded-lg object-cover bg-[#1a1a1a]" />
                {:else}
                  <div class="mb-1 flex aspect-square w-full items-center justify-center rounded-lg bg-[#1a1a1a] text-[10px] text-[#666]">нет</div>
                {/if}
                <div class="flex items-center justify-center gap-1 text-sm">
                  <button type="button" data-testid="checkout-payment-peek-minus" disabled={atMinQty(line)} onclick={() => bumpCartLine(line.index, -1)}>−</button>
                  <span>{line.quantity}</span>
                  <button type="button" data-testid="checkout-payment-peek-plus" disabled={atMaxQty(line)} onclick={() => bumpCartLine(line.index, 1)}>+</button>
                </div>
              </div>
            {/each}
          </div>
        {/if}
        <div class="mt-auto flex gap-2 border-t border-[#3a3a3a] px-3 py-3" data-testid="checkout-payment-footer">
          <button type="button" class="flex-1 rounded-2xl border border-[#555] bg-[#1f1f1f] py-2.5 text-sm text-[#888]" data-testid="checkout-payment-sbp" disabled>СБП</button>
          <button type="button" class="flex-1 rounded-2xl border-2 border-[#ff8c42] bg-transparent py-2.5 text-sm font-medium text-[#ff8c42] disabled:border-[#ff8c42]/55 disabled:text-[#ff8c42]/55" data-testid="checkout-payment-card-plus" disabled={!emailVerified || !cardPlusEnabled} onclick={handleCardPlus}>Картой +</button>
          <button type="button" class="flex-[1.35] rounded-2xl bg-[#ff8c42] py-2.5 text-sm font-semibold text-black disabled:bg-[#ff8c42]/45 disabled:text-black/50" data-testid="checkout-payment-pay" disabled={!emailVerified || !payEnabled} onclick={handlePayClick}>оплатить</button>
        </div>
      </div>
    {/if}
  </div>
{/if}
