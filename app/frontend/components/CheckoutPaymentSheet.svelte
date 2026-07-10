<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    checkoutPaymentMode,
    checkoutPaymentSubView,
    checkoutPaymentItems,
    checkoutPaymentTotal,
    checkoutPaymentLimitError,
    bindCheckoutPaymentCart,
    expandSheet,
    collapseToPeek,
    openPaymentList,
    closePaymentList,
    openCardForm,
    closeCardForm,
    openThreeDs,
    closeThreeDs,
    restartAddCardAfterThreeDsExpiry
  } from "../lib/checkoutPaymentSheetStore.js"
  import {
    MODE_PEEK,
    MODE_EXPANDED,
    MODE_EXPANDED_PLUS,
    SUBVIEW_PAYMENT_LIST,
    SUBVIEW_CARD_FORM,
    SUBVIEW_THREE_DS,
    SHEET_TRANSITION_MS,
    SWIPE_UP_PX,
    MAX_SAVED_CARDS,
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
  import {
    formatPanInput,
    formatExpiryInput,
    validateCardFields
  } from "../lib/tbankCardFormat.js"

  let {
    emailVerified = false,
    savedCards = [],
    hasSavedCard = false,
    cardLabel = null,
    selectedCardId = null,
    canPay = false,
    totalLabel = "0₽",
    onPay = () => {},
    onSelectCard = () => {},
    onSelectNewCard = () => {},
    onRemoveCard = () => {},
    onCardFormNext = () => {},
    onThreeDsAllow = () => {}
  } = $props()

  let mode = $state(MODE_PEEK)
  let subView = $state(SUBVIEW_PAYMENT_LIST)
  let items = $state([])
  let total = $state(0)
  let limitError = $state(null)
  let gestureStartY = 0

  // Card form (embedded)
  let pan = $state("")
  let expiry = $state("")
  let cvv = $state("")
  let saveCard = $state(true)
  let fieldErrors = $state({})
  let formTouched = $state(false)

  // 3DS
  let smsCode = $state("")
  let threeDsTimer = $state(59)
  let timerExpired = $state(false)
  let threeDsError = $state(null)
  let threeDsNetworkError = $state(false)
  let timerId = null

  const count = $derived(items.length)
  const heightVh = $derived(sheetHeightVh(mode, subView))
  const footerLocked = $derived(!emailVerified)
  const payEnabled = $derived(
    emailVerified && (hasSavedCard || savedCards.length > 0) && canPay
  )
  const cardPlusEnabled = $derived(emailVerified)
  const formValid = $derived(validateCardFields({ pan, expiry, cvv }).valid)

  onMount(() => {
    bindCheckoutPaymentCart()
    const u1 = checkoutPaymentMode.subscribe((v) => { mode = v })
    const u2 = checkoutPaymentSubView.subscribe((v) => { subView = v })
    const u3 = checkoutPaymentItems.subscribe((v) => { items = v })
    const u4 = checkoutPaymentTotal.subscribe((v) => { total = v })
    const u5 = checkoutPaymentLimitError.subscribe((v) => { limitError = v })
    return () => { u1(); u2(); u3(); u4(); u5(); stopTimer() }
  })

  function refreshFieldErrors() {
    fieldErrors = validateCardFields({ pan, expiry, cvv }).errors
  }

  function resetFields() {
    pan = ""
    expiry = ""
    cvv = ""
    saveCard = true
    fieldErrors = {}
    formTouched = false
  }

  function clearForm() {
    resetFields()
  }

  function handleCardPlus() {
    if (!cardPlusEnabled) return
    onSelectNewCard()
    const ok = openCardForm(savedCards.length)
    if (ok) resetFields()
  }

  function handleCloseForm() {
    clearForm()
    closeCardForm()
  }

  function handleFormNext() {
    formTouched = true
    refreshFieldErrors()
    if (!formValid) return
    openThreeDs()
    startTimer()
    smsCode = ""
    threeDsError = null
    threeDsNetworkError = false
    onCardFormNext({ pan, expiry, cvv, saveCard })
  }

  function startTimer() {
    stopTimer()
    threeDsTimer = 59
    timerExpired = false
    timerId = setInterval(() => {
      if (threeDsTimer <= 0) {
        timerExpired = true
        threeDsTimer = 0
        stopTimer()
        return
      }
      threeDsTimer -= 1
    }, 1000)
  }

  function stopTimer() {
    if (timerId) {
      clearInterval(timerId)
      timerId = null
    }
  }

  function keypadPress(key) {
    if (timerExpired) return
    if (key === ">") {
      smsCode = smsCode.slice(0, -1)
      return
    }
    if (key === "*" || key === ".") return
    if (smsCode.length >= 6) return
    smsCode += String(key)
  }

  function handleAllow() {
    if (timerExpired || !smsCode) return
    try {
      onThreeDsAllow({ smsCode, saveCard })
      smsCode = ""
      threeDsError = null
      stopTimer()
      closeCardForm()
    } catch (_e) {
      threeDsError = "Неверный СМС-код"
      smsCode = ""
      resetCode()
    }
  }

  function resetCode() {
    smsCode = ""
  }

  function handleThreeDsRetry() {
    threeDsNetworkError = false
    threeDsError = null
    startTimer()
  }

  function onTimerExpiryRestart() {
    if (!timerExpired) return
    restartAddCardAfterThreeDsExpiry()
    resetFields()
  }

  function handlePayClick() {
    if (footerLocked || !payEnabled) return
    onPay()
  }

  function handleImageClick(line) {
    // openEditCard(line) передаёт cart_line + selected_modifiers через query Product
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
      if (mode === MODE_EXPANDED_PLUS && subView === SUBVIEW_PAYMENT_LIST) closePaymentList()
      else if (mode === MODE_EXPANDED) collapseToPeek()
    }
  }

  const timerLabel = $derived(
    timerExpired ? "00:00" : `00:${String(threeDsTimer).padStart(2, "0")}`
  )
  const displayTotal = $derived(totalLabel || `${Math.round(total)}₽`)
  const allowDisabled = $derived(timerExpired || !smsCode)
</script>

{#if !items.length}
  <div class="hidden" data-testid="checkout-payment-empty" aria-hidden="true"></div>
{:else}
  <!-- data-checkout-sheet-mode="peek" | expanded | expanded_plus -->
  <div
    data-testid="checkout-payment-sheet"
    data-checkout-sheet-mode={mode === "peek" ? "peek" : mode}
    data-checkout-sheet-subview={subView}
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

    {#if mode === MODE_EXPANDED_PLUS && subView === SUBVIEW_THREE_DS}
      <div class="flex min-h-0 flex-1 flex-col px-3" data-testid="checkout-payment-three-ds" data-checkout-layout="three-ds">
        <div class="mb-2 flex items-center justify-between" data-testid="checkout-payment-form-price-bar">
          <span class="text-sm text-[#a0a0a0]">Сумма</span>
          <button type="button" class="rounded-full bg-[#3a3a3a] px-3 py-1 text-sm text-[#888]" disabled>{displayTotal}</button>
        </div>
        <p class="mb-1 text-center text-lg tabular-nums text-white" data-testid="checkout-payment-three-ds-timer">{timerLabel}</p>
        {#if timerExpired}
          <p class="mb-2 text-center text-xs text-[#ff8c42]">Время истекло — начните добавление карты заново</p>
          <button type="button" class="mb-2 text-sm text-[#ff8c42]" onclick={onTimerExpiryRestart}>Заново</button>
        {/if}
        <label class="mb-2 block">
          <span class="mb-1 block text-xs text-[#a0a0a0]">СМС код</span>
          <input class="w-full rounded-lg border border-[#3a3a3a] bg-[#1a1a1a] px-3 py-2 tracking-widest" value={smsCode} readonly />
        </label>
        {#if threeDsError}
          <p class="mb-2 text-sm text-red-400" data-testid="checkout-payment-three-ds-error">{threeDsError}</p>
        {/if}
        {#if threeDsNetworkError}
          <p class="mb-2 text-sm text-red-400" data-testid="checkout-payment-three-ds-network-error">Ошибка соединения</p>
          <button type="button" class="mb-2 text-sm text-[#ff8c42]" onclick={handleThreeDsRetry}>Повторить</button>
        {/if}
        <div class="grid grid-cols-3 gap-2" data-testid="checkout-payment-three-ds-keypad">
          {#each [1, 2, 3, 4, 5, 6, 7, 8, 9, "*", 0, ">"] as key}
            <button type="button" class="rounded-lg bg-[#3a3a3a] py-3 text-white" onclick={() => keypadPress(key)}>{key}</button>
          {/each}
        </div>
        <button
          type="button"
          class="mt-3 w-full rounded-xl bg-[#ff8c42] py-3 font-semibold text-black disabled:opacity-40"
          disabled={allowDisabled}
          onclick={handleAllow}
        >
          Разрешить
        </button>
      </div>

    {:else if mode === MODE_EXPANDED_PLUS && subView === SUBVIEW_CARD_FORM}
      <div class="flex min-h-0 flex-1 flex-col overflow-y-auto px-3" data-testid="checkout-payment-card-form" data-checkout-layout="card-form">
        <div class="mb-2 flex items-center justify-between" data-testid="checkout-payment-form-price-bar">
          <span class="text-sm text-[#a0a0a0]">Сумма</span>
          <button type="button" class="rounded-full bg-[#3a3a3a] px-3 py-1 text-sm text-[#888]" disabled>{displayTotal}</button>
        </div>
        <button type="button" class="mb-2 self-end text-[#a0a0a0]" onclick={handleCloseForm} aria-label="Закрыть форму">✕</button>
        <label class="mb-2 block">
          <span class="mb-1 block text-xs text-[#a0a0a0]">Номер карты</span>
          <input
            class="w-full rounded-lg border border-[#3a3a3a] bg-[#1a1a1a] px-3 py-2"
            placeholder="Номер карты"
            value={pan}
            oninput={(e) => { pan = formatPanInput(e.currentTarget.value); if (formTouched) refreshFieldErrors() }}
          />
          {#if fieldErrors.pan}<span class="text-xs text-red-400">{fieldErrors.pan}</span>{/if}
        </label>
        <div class="mb-2 flex gap-2">
          <label class="block flex-1">
            <span class="mb-1 block text-xs text-[#a0a0a0]">ММ / ГГ</span>
            <input
              class="w-full rounded-lg border border-[#3a3a3a] bg-[#1a1a1a] px-3 py-2"
              placeholder="ММ / ГГ"
              value={expiry}
              oninput={(e) => { expiry = formatExpiryInput(e.currentTarget.value); if (formTouched) refreshFieldErrors() }}
            />
          </label>
          <label class="block w-24">
            <span class="mb-1 block text-xs text-[#a0a0a0]">CVV</span>
            <input
              class="w-full rounded-lg border border-[#3a3a3a] bg-[#1a1a1a] px-3 py-2"
              placeholder="CVV"
              value={cvv}
              oninput={(e) => { cvv = e.currentTarget.value.replace(/\D/g, "").slice(0, 4); if (formTouched) refreshFieldErrors() }}
            />
          </label>
        </div>
        <div class="mb-3 flex items-center justify-between gap-2">
          <div>
            <p class="text-sm text-white">Использовать карту для будущих заказов</p>
            <p class="text-xs text-[#888]">Это безопасно, данные зашифрованы</p>
          </div>
          <button type="button" class="text-[#ff8c42]" onclick={() => (saveCard = !saveCard)} aria-pressed={saveCard}>
            {saveCard ? "ON" : "OFF"}
          </button>
        </div>
        <button
          type="button"
          class="w-full rounded-xl border border-[#ff8c42] py-3 text-[#ff8c42] disabled:opacity-40"
          disabled={!formValid}
          onclick={handleFormNext}
        >
          Далее
        </button>
      </div>

    {:else if mode === MODE_EXPANDED_PLUS}
      <div class="flex min-h-0 flex-1 flex-col" data-testid="checkout-payment-expanded-plus">
        <div class="flex items-center justify-between px-3 pb-2">
          <h2 class="text-base font-semibold text-white">Способ оплаты</h2>
          <button type="button" class="text-[#a0a0a0]" data-testid="checkout-payment-close" onclick={() => closePaymentList()} aria-label="Закрыть">✕</button>
        </div>
        <div class="mb-2 flex gap-2 overflow-x-auto px-3" style="overflow-x: auto; touch-action: pan-x;">
          {#each items.slice(0, 4) as line}
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
              <button type="button" class="text-xs text-red-400" onclick={(e) => { e.stopPropagation(); onRemoveCard(card) }}>Удалить карту</button>
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
                <p class="truncate text-sm text-white">{line.name}</p>
                <p class="text-xs text-[#888]">{line.line_total}₽ × {line.quantity}</p>
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
            <button type="button" class="flex-1 rounded-xl border border-[#3a3a3a] py-2 text-[#888]" data-testid="checkout-payment-sbp" disabled>СБП</button>
            <button type="button" class="flex-1 rounded-xl border border-[#ff8c42] py-2 text-[#ff8c42] disabled:opacity-40" data-testid="checkout-payment-card-plus" disabled={!cardPlusEnabled} onclick={handleCardPlus}>Картой +</button>
            <button type="button" class="flex-[1.4] rounded-xl bg-[#ff8c42] py-2 font-semibold text-black disabled:opacity-40" data-testid="checkout-payment-pay" disabled={footerLocked || !payEnabled} onclick={handlePayClick}>оплатить</button>
          </div>
        </div>
      </div>

    {:else}
      <!-- peek -->
      <div class="flex min-h-0 flex-1 flex-col">
        {#if count === 1}
          <div class="min-h-0 flex-1 overflow-y-auto px-3" data-testid="checkout-payment-peek-single">
            {#each items as line}
              <div class="flex gap-3">
                <img src={line.image_url || ""} alt="" class="h-20 w-20 rounded-lg object-cover" />
                <div class="min-w-0 flex-1">
                  <p class="text-sm text-white">{line.name}</p>
                  <p class="text-xs text-[#888]">{line.line_total}₽ × {line.quantity}</p>
                  <div class="mt-1 flex items-center gap-2">
                    <button type="button" data-testid="checkout-payment-peek-minus" disabled={atMinQty(line)} onclick={() => bumpCartLine(line.index, -1)}>−</button>
                    <span>{line.quantity}</span>
                    <button type="button" data-testid="checkout-payment-peek-plus" disabled={atMaxQty(line)} onclick={() => bumpCartLine(line.index, 1)}>+</button>
                    <button type="button" class="text-xs text-red-400" onclick={() => removeCartLine(line.index)}>Удалить</button>
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
              <div class="w-[28vw] shrink-0">
                <img src={line.image_url || ""} alt="" class="mb-1 aspect-square w-full rounded-lg object-cover bg-[#1a1a1a]" />
                <div class="flex items-center justify-center gap-1 text-sm">
                  <button type="button" data-testid="checkout-payment-peek-minus" disabled={atMinQty(line)} onclick={() => bumpCartLine(line.index, -1)}>−</button>
                  <span>{line.quantity}</span>
                  <button type="button" data-testid="checkout-payment-peek-plus" disabled={atMaxQty(line)} onclick={() => bumpCartLine(line.index, 1)}>+</button>
                </div>
              </div>
            {/each}
          </div>
        {/if}
        <div class="mt-auto flex gap-2 border-t border-[#3a3a3a] p-3" data-testid="checkout-payment-footer">
          <button type="button" class="flex-1 rounded-xl border border-[#3a3a3a] py-2 text-[#888]" data-testid="checkout-payment-sbp" disabled>СБП</button>
          <button type="button" class="flex-1 rounded-xl border border-[#ff8c42] py-2 text-[#ff8c42] disabled:opacity-40" data-testid="checkout-payment-card-plus" disabled={!emailVerified || !cardPlusEnabled} onclick={handleCardPlus}>Картой +</button>
          <button type="button" class="flex-[1.4] rounded-xl bg-[#ff8c42] py-2 font-semibold text-black disabled:opacity-40" data-testid="checkout-payment-pay" disabled={!emailVerified || !payEnabled} onclick={handlePayClick}>оплатить</button>
        </div>
      </div>
    {/if}
  </div>
{/if}
