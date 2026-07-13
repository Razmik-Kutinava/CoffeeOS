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
  import { cardMethodParts } from "../lib/paymentMethodLabels.js"

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
      // ТЗ Шаг 2: Peek→Expanded только после подтверждённого email
      if (mode === MODE_PEEK && emailVerified) expandSheet()
      else if (mode === MODE_EXPANDED) openPaymentList()
    } else if (delta <= -SWIPE_UP_PX) {
      if (mode === MODE_EXPANDED_PLUS) closePaymentList()
      else if (mode === MODE_EXPANDED) collapseToPeek()
    }
  }

  /** Клик по handle: Peek→Expanded (email) — для desktop/MCP без swipe */
  function onGestureActivate() {
    if (mode === MODE_PEEK && emailVerified) expandSheet()
    else if (mode === MODE_EXPANDED) openPaymentList()
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
    <button
      type="button"
      class="flex w-full shrink-0 cursor-grab justify-center py-2 active:cursor-grabbing"
      data-testid="checkout-payment-gesture-zone"
      aria-label="Потяните вверх или вниз, чтобы изменить высоту шторки"
      ontouchstart={onGestureStart}
      ontouchend={onGestureEnd}
      onmousedown={onGestureStart}
      onmouseup={onGestureEnd}
      onclick={onGestureActivate}
    >
      <div class="h-1 w-10 rounded-full bg-[#555]" aria-hidden="true"></div>
    </button>

    {#if limitError}
      <p class="px-3 pb-1 text-sm text-red-400" data-testid="checkout-payment-card-limit-error" role="alert">
        {limitError}
      </p>
    {/if}

    {#if mode === MODE_EXPANDED_PLUS}
      <!-- s05/s07: 2 thumbs сверху → Способ оплаты + X → список карт / СБП / Картой + → Оплатить -->
      <div class="flex min-h-0 flex-1 flex-col" data-testid="checkout-payment-expanded-plus">
        <div
          class="mb-2 flex gap-3 overflow-x-auto px-3"
          data-testid="checkout-payment-plus-thumbs"
          style="overflow-x: auto; touch-action: pan-x;"
        >
          {#each items.slice(0, 2) as line}
            <div class="w-[28vw] shrink-0" data-testid="checkout-payment-plus-thumb">
              <button type="button" class="block w-full" onclick={() => handleImageClick(line)}>
                {#if line.image_url}
                  <img src={line.image_url} alt="" class="mb-1 aspect-square w-full rounded-lg object-cover bg-[#1a1a1a]" />
                {:else}
                  <div class="mb-1 flex aspect-square w-full items-center justify-center rounded-lg bg-[#1a1a1a] text-[10px] text-[#666]">нет</div>
                {/if}
              </button>
              <div class="flex items-center justify-center gap-1 text-sm text-white">
                <button type="button" data-testid="checkout-payment-plus-minus" disabled={atMinQty(line)} onclick={() => bumpCartLine(line.index, -1)}>−</button>
                <span>{line.quantity}</span>
                <button type="button" data-testid="checkout-payment-plus-plus" disabled={atMaxQty(line)} onclick={() => bumpCartLine(line.index, 1)}>+</button>
              </div>
            </div>
          {/each}
        </div>
        <div class="flex items-center justify-between px-3 pb-2">
          <h2 class="text-base font-semibold text-white">Способ оплаты</h2>
          <button
            type="button"
            class="flex h-8 w-8 items-center justify-center rounded-full bg-[#3a3a3a] text-white"
            data-testid="checkout-payment-close"
            onclick={() => closePaymentList()}
            aria-label="Закрыть"
          >✕</button>
        </div>
        <div class="min-h-0 flex-1 space-y-2 overflow-y-auto px-3" data-testid="checkout-payment-list">
          {#each savedCards as card}
            {@const parts = cardMethodParts(card)}
            <button
              type="button"
              class="flex w-full items-center rounded-2xl border-2 border-[#ff8c42] bg-[#1f1f1f] px-4 py-3.5 text-left"
              data-testid="checkout-payment-plus-card"
              onclick={() => onSelectCard(card)}
            >
              <span class="text-[#ff8c42]">{parts.word}</span>
              <span class="ml-1 italic text-white">{parts.pan}</span>
            </button>
          {/each}
          <button
            type="button"
            class="w-full rounded-2xl border border-[#555] bg-[#1f1f1f] px-4 py-3.5 text-center text-lg font-semibold text-white disabled:opacity-60"
            disabled
            data-testid="checkout-payment-sbp-list"
          >СБП</button>
          <button
            type="button"
            class="flex w-full items-center justify-between rounded-2xl border-2 border-[#ff8c42] bg-[#1f1f1f] px-4 py-3.5 text-[#ff8c42] disabled:border-[#ff8c42]/55 disabled:text-[#ff8c42]/55"
            data-testid="checkout-payment-card-plus"
            disabled={!cardPlusEnabled}
            onclick={handleCardPlus}
          ><span>Картой</span><span aria-hidden="true">+</span></button>
        </div>
        <div class="shrink-0 p-3">
          <button
            type="button"
            class="w-full rounded-2xl bg-[#ff8c42] py-3.5 text-base font-semibold text-black disabled:bg-[#ff8c42]/45 disabled:text-black/50"
            data-testid="checkout-payment-pay"
            disabled={footerLocked || !payEnabled}
            onclick={handlePayClick}
          >Оплатить</button>
        </div>
      </div>

    {:else if mode === MODE_EXPANDED}
      <!-- s06 / ТЗ Шаг 2: все товары + вертикальный блок методов + Оплатить -->
      <div class="flex min-h-0 flex-1 flex-col" data-testid="checkout-payment-expanded">
        <div
          class="min-h-0 flex-1 overflow-y-auto px-3 {count > 3 ? 'flex gap-2 overflow-x-auto' : 'space-y-2'}"
          data-testid="checkout-payment-expanded-items"
          style={count > 3 ? "overflow-x: auto; touch-action: pan-x;" : undefined}
        >
          {#each items as line}
            <div
              class="flex gap-3 rounded-xl bg-[#1f1f1f] p-2 {count > 3 ? 'w-[72vw] shrink-0' : ''}"
              data-testid="checkout-payment-expanded-full-card"
            >
              <button type="button" class="shrink-0" onclick={() => handleImageClick(line)}>
                {#if line.image_url}
                  <img
                    src={line.image_url}
                    alt=""
                    class="h-16 w-16 rounded-lg object-cover bg-[#1a1a1a]"
                    data-testid="checkout-payment-expanded-product-image"
                  />
                {:else}
                  <div class="flex h-16 w-16 items-center justify-center rounded-lg bg-[#1a1a1a] text-[10px] text-[#666]">нет</div>
                {/if}
              </button>
              <div class="min-w-0 flex-1">
                <p class="line-clamp-2 text-sm text-white">{lineName(line)}</p>
                <p class="text-xs text-[#888]">{unitPrice(line)}₽ × {line.quantity}</p>
                {#each modifierLines(line) as modName}
                  <p class="text-xs text-[#888]">{modName}</p>
                {/each}
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
        <div class="shrink-0 space-y-2 border-t border-[#3a3a3a] px-3 pt-2" data-testid="checkout-payment-expanded-methods">
          <div class="flex items-center justify-between pb-1">
            <button
              type="button"
              class="text-base font-semibold text-white"
              data-testid="checkout-payment-open-plus"
              onclick={() => openPaymentList()}
            >Способ оплаты</button>
            <button type="button" class="flex h-8 w-8 items-center justify-center rounded-full bg-[#3a3a3a] text-white" data-testid="checkout-payment-expanded-close" onclick={() => collapseToPeek()} aria-label="Закрыть">✕</button>
          </div>
          {#each savedCards as card}
            {@const parts = cardMethodParts(card)}
            <button
              type="button"
              class="flex w-full items-center rounded-xl border-2 border-[#ff8c42] bg-[#1f1f1f] px-3 py-3 text-left"
              data-testid="checkout-payment-expanded-card"
              onclick={() => onSelectCard(card)}
            >
              <span class="text-[#ff8c42]">{parts.word}</span>
              <span class="ml-1 italic text-white">{parts.pan}</span>
            </button>
          {/each}
          <button type="button" class="w-full rounded-xl border border-[#555] bg-[#1f1f1f] px-3 py-3 text-left text-[#888]" data-testid="checkout-payment-sbp" disabled>СБП</button>
          <button
            type="button"
            class="flex w-full items-center justify-between rounded-xl border-2 border-[#ff8c42] px-3 py-3 text-[#ff8c42] disabled:border-[#ff8c42]/55 disabled:text-[#ff8c42]/55"
            data-testid="checkout-payment-card-plus"
            disabled={!cardPlusEnabled}
            onclick={handleCardPlus}
          ><span>Картой</span><span aria-hidden="true">+</span></button>
        </div>
        <div class="shrink-0 p-3">
          <button
            type="button"
            class="w-full rounded-2xl bg-[#ff8c42] py-3 text-base font-semibold text-black disabled:bg-[#ff8c42]/45 disabled:text-black/50"
            data-testid="checkout-payment-pay"
            disabled={footerLocked || !payEnabled}
            onclick={handlePayClick}
          >Оплатить</button>
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
