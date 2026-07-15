<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    cartItems,
    cartTotal,
    cartSheetMode,
    cartSheetBusy,
    cartUndoLine,
    cartSheetError,
    isCartSheetRoute,
    onCartSheetRouteChange,
    refreshCartSheet,
    handleSheetGestureDelta,
    bumpCartLine,
    removeCartLine,
    bindCartSheetEvents,
    atMinQty,
    atMaxQty,
    openEditCard,
    undoRemoveCartLine
  } from "../lib/cartSheetStore.js"
  import {
    MODE_EMPTY,
    MODE_EXPANDED,
    MODE_PEEK,
    MODE_HIDDEN,
    sheetHeightVh,
    SHEET_TRANSITION_MS,
    CART_SHEET_BOTTOM_REM,
    CART_SHEET_MAX_WIDTH_PX,
    CART_SHEET_BUILD
  } from "../lib/cartSheetThresholds.js"

  let hash = $state(typeof window !== "undefined" ? window.location.hash : "")
  let items = $state([])
  let total = $state(0)
  let mode = $state(MODE_EMPTY)
  let busy = $state(false)
  let undoLine = $state(null)
  let sheetError = $state(null)
  let gestureStartY = 0
  let gestureActive = false
  let gestureZoneEl = $state(null)

  let showSheet = $derived(isCartSheetRoute(hash))
  let count = $derived(items.length)
  let heightVh = $derived(sheetHeightVh(mode, count))
  let singleItem = $derived(count === 1 ? items[0] : null)

  // Touch-события должны перехватываться первыми и блокировать pointer-дубли.
  function onTouchStart(e) {
    gestureActive = true
    gestureStartY = e.touches[0].clientY
    if (e.cancelable) e.preventDefault()
  }

  function onTouchEnd(e) {
    if (!gestureActive) return
    gestureActive = false
    handleSheetGestureDelta(gestureStartY, e.changedTouches[0].clientY)
  }

  // Pointer-события — ТОЛЬКО для мыши (desktop); touch-устройства используют touch-обработчики выше.
  // pointerType="touch" приходит от браузера параллельно с touch-событиями → игнорируем.
  function onPointerDown(e) {
    if (e.pointerType !== "mouse" || !e.isPrimary) return
    gestureActive = true
    gestureStartY = e.clientY
    e.currentTarget.setPointerCapture(e.pointerId)
  }

  function onPointerUp(e) {
    if (e.pointerType !== "mouse" || !e.isPrimary || !gestureActive) return
    gestureActive = false
    handleSheetGestureDelta(gestureStartY, e.clientY)
  }

  function onGestureCancel() {
    gestureActive = false
    gestureStartY = 0
  }

  // S4-блок-3: индикаторы прокрутки в peek 4+
  let peekScrollIndex = $state(0)

  function onPeekScroll(e) {
    const el = e.currentTarget
    const maxScroll = el.scrollWidth - el.clientWidth
    peekScrollIndex = maxScroll > 0
      ? Math.round((el.scrollLeft / maxScroll) * (count - 1))
      : 0
  }

  $effect(() => {
    const gz = gestureZoneEl
    if (!gz) return
    gz.addEventListener("touchstart",  onTouchStart,    { passive: false })
    gz.addEventListener("touchend",    onTouchEnd,      { passive: false })
    gz.addEventListener("touchcancel", onGestureCancel, { passive: true  })
    gz.addEventListener("pointerdown", onPointerDown)
    gz.addEventListener("pointerup",   onPointerUp)
    gz.addEventListener("pointercancel", onGestureCancel)
    return () => {
      gz.removeEventListener("touchstart",   onTouchStart)
      gz.removeEventListener("touchend",     onTouchEnd)
      gz.removeEventListener("touchcancel",  onGestureCancel)
      gz.removeEventListener("pointerdown",  onPointerDown)
      gz.removeEventListener("pointerup",    onPointerUp)
      gz.removeEventListener("pointercancel", onGestureCancel)
    }
  })

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }

  let checkoutDisabled = $derived(roundPrice(total) <= 0)

  function formatThousands(n) {
    const s = String(roundPrice(n))
    return s.replace(/\B(?=(\d{3})+(?!\d))/g, " ")
  }

  function formatCartButtonTotal(n) {
    return `+${formatThousands(n)}₽`
  }

  // Авто-уменьшение шрифта для больших сумм: вместо измерения DOM используем число цифр.
  // Геометрия кнопки не меняется (adjust-only: font-size).
  function checkoutButtonFontSizePx(n) {
    const digits = String(roundPrice(n)).length
    if (digits >= 9) return 10
    if (digits >= 8) return 11
    if (digits >= 7) return 12
    if (digits >= 5) return 13
    return 14
  }

  // S4: tap по карточке → Product (редактирование модификаторов).
  // Если клик по кнопке (− / + / Удалить) — игнорируем; кнопки обрабатывают себя сами.
  function tapToProduct(line, e) {
    if (e.target.closest("button")) return
    push(`/product/${line.product_id}?cart_line=${line.index}`)
  }

  // «−» при quantity = 1 удаляет товар из корзины; иначе уменьшает на 1.
  function decrementLine(line) {
    if (atMinQty(line)) {
      removeCartLine(line.index)
    } else {
      bumpCartLine(line.index, -1)
    }
  }

  function modifierLabel(mod) {
    const extra = Number(mod.price) > 0 ? ` (+${roundPrice(mod.price)}₽)` : ""
    return `${mod.name}${extra}`
  }

  onMount(() => {
    const unsubItems = cartItems.subscribe((v) => { items = v })
    const unsubTotal = cartTotal.subscribe((v) => { total = v })
    const unsubMode  = cartSheetMode.subscribe((v) => { mode = v })
    const unsubBusy  = cartSheetBusy.subscribe((v) => { busy = v })
    const unsubUndo  = cartUndoLine.subscribe((v) => { undoLine = v })
    const unsubErr   = cartSheetError.subscribe((v) => { sheetError = v })

    const onHash = () => {
      const next = window.location.hash
      const wasSheet = isCartSheetRoute(hash)
      hash = next
      if (wasSheet !== isCartSheetRoute(hash)) {
        onCartSheetRouteChange(isCartSheetRoute(hash))
      }
    }

    bindCartSheetEvents()
    window.addEventListener("hashchange", onHash)
    refreshCartSheet().catch(() => {})

    return () => {
      unsubItems(); unsubTotal(); unsubMode(); unsubBusy()
      unsubUndo(); unsubErr()
      window.removeEventListener("hashchange", onHash)
    }
  })
</script>

{#snippet lineControls(line)}
  <div class="mt-1 flex items-center gap-1.5">
    <button
      type="button"
      data-testid="shop-cart-expanded-minus"
      class="rounded bg-[#3a3a3a] px-2 py-0.5 text-xs disabled:opacity-40"
      disabled={busy}
      onclick={() => decrementLine(line)}
    >−</button>
    <span class="text-xs">{line.quantity}</span>
    <button
      type="button"
      data-testid="shop-cart-expanded-plus"
      class="rounded bg-[#3a3a3a] px-2 py-0.5 text-xs disabled:opacity-40"
      disabled={atMaxQty(line)}
      onclick={() => bumpCartLine(line.index, 1)}
    >+</button>
    <button
      type="button"
      data-testid="shop-cart-expanded-delete"
      class="ml-auto text-xs text-red-400 disabled:opacity-40"
      disabled={busy}
      onclick={() => removeCartLine(line.index)}
    >Удалить</button>
  </div>
{/snippet}

{#snippet lineThumb(line, sizeClass, objectPosition = "")}
  {#if line.image_url}
    <img
      src={line.image_url}
      alt=""
      class="{sizeClass} rounded-lg object-cover {objectPosition}"
      decoding="async"
    />
  {:else}
    <div class="flex {sizeClass} items-center justify-center rounded-lg bg-[#333] text-[10px] text-[#888]">нет</div>
  {/if}
{/snippet}

{#snippet checkoutBar(totalTestId = null)}
  <div class="mt-2 flex shrink-0 items-center justify-end gap-2 border-t border-[#3a3a3a] pt-2">
    <button
      type="button"
      data-testid="shop-cart-sheet-checkout"
      class="rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
      disabled={checkoutDisabled}
      onclick={() => push("/checkout")}
    >
      <span
        class="whitespace-nowrap leading-none"
        data-testid={totalTestId}
        style:font-size={`${checkoutButtonFontSizePx(total)}px`}
      >
        {formatCartButtonTotal(total)}
      </span>
    </button>
  </div>
{/snippet}

{#if showSheet}
  <div
    data-testid="shop-cart-sheet"
    data-cart-sheet-mode={mode}
    data-cart-sheet-build={CART_SHEET_BUILD}
    class="cart-sheet fixed left-0 right-0 z-50 mx-auto flex flex-col overflow-hidden border-t border-[#3a3a3a] bg-[#2a2a2a]/98 backdrop-blur transition-[height] ease-out"
    style:height="{heightVh}vh"
    style:bottom="{CART_SHEET_BOTTOM_REM}rem"
    style:max-width="{CART_SHEET_MAX_WIDTH_PX}px"
    style:transition-duration="{SHEET_TRANSITION_MS}ms"
  >
    {#if sheetError}
      <div
        data-testid="shop-cart-error"
        role="status"
        class="mx-3 mt-2 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-3 py-2 text-[12px] text-[#ff8c42]"
      >
        {sheetError}
      </div>
    {/if}

    {#if undoLine}
      <div
        data-testid="shop-cart-undo"
        role="status"
        class="mx-3 mt-2 flex items-center justify-between gap-3 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-3 py-2 text-[12px]"
      >
        <span class="text-[#a0a0a0]">Удаление можно отменить</span>
        <button
          type="button"
          data-testid="shop-cart-undo-button"
          class="shrink-0 rounded bg-[#ff8c42] px-3 py-1.5 text-[12px] font-semibold text-black"
          disabled={busy}
          onclick={() => undoRemoveCartLine()}
        >
          Отменить
        </button>
      </div>
    {/if}

    <!-- Drag-handle / gesture zone -->
    <div
      bind:this={gestureZoneEl}
      data-testid="shop-cart-sheet-gesture-zone"
      class="cart-sheet-gesture-zone flex w-full min-h-14 shrink-0 touch-none select-none flex-col items-center justify-center border-b border-[#3a3a3a]/60"
      style:touch-action="none"
      role="button"
      tabindex="-1"
      aria-label="Потяните вверх или вниз, чтобы изменить высоту корзины"
    >
      <div class="drag-handle h-1.5 w-12 rounded-full bg-[#777]" aria-hidden="true"></div>
    </div>

    <!-- EMPTY -->
    {#if mode === MODE_EMPTY || !count}
      <p data-testid="shop-cart-sheet-empty" class="px-4 py-6 text-center text-sm italic text-[#888]">
        тут будут твои заказы
      </p>
      {@render checkoutBar("shop-cart-empty-total")}

    <!-- HIDDEN — чип с суммой (ТЗ S2a) -->
    {:else if mode === MODE_HIDDEN}
      <div
        class="flex flex-1 min-h-0 items-center justify-between gap-2 px-3 py-1.5"
        data-testid="shop-cart-hidden-chip"
      >
        <div class="flex min-w-0 flex-1 items-center gap-2 rounded-full border border-[#3a3a3a] bg-[#1f1f1f] px-3 py-1.5">
          <span class="shrink-0 text-xs text-[#888]">Корзина</span>
          <span data-testid="shop-cart-hidden-total" class="truncate text-sm font-semibold text-[#ff8c42]">{roundPrice(total)}₽</span>
        </div>
        <button
          type="button"
          data-testid="shop-cart-sheet-checkout"
          class="shrink-0 rounded-full bg-[#ff8c42] px-3 py-1.5 text-sm font-semibold text-black"
          disabled={checkoutDisabled}
          onclick={() => push("/checkout")}
        >
          <span
            class="whitespace-nowrap leading-none"
            style:font-size={`${checkoutButtonFontSizePx(total)}px`}
          >
            {formatCartButtonTotal(total)}
          </span>
        </button>
      </div>

    <!-- PEEK 2+ — горизонтальный ряд карточек 28vw (§ S2-канон: компактный peek) -->
    {:else if mode === MODE_PEEK && count >= 2}
      <div
        class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1"
        data-testid="shop-cart-peek-list"
        data-cart-layout="horizontal"
      >
        <div
          class="flex min-h-0 flex-1 gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          onscroll={onPeekScroll}
        >
          {#each items as line (line.index)}
            <div
              class="flex w-[min(28vw,110px)] shrink-0 flex-col gap-1 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-1.5 cursor-pointer"
              data-testid="shop-cart-peek-line"
              role="button"
              tabindex="0"
              onclick={(e) => tapToProduct(line, e)}
            >
              {@render lineThumb(line, "h-16 w-full rounded-lg")}
              <div class="min-w-0">
                <p class="line-clamp-2 text-[11px] font-medium leading-tight">{line.product_name}</p>
                <p class="mt-0.5 text-[10px] text-[#a0a0a0]">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
                <div class="mt-1 flex items-center justify-between gap-0.5">
                  <button
                    type="button"
                    data-testid="shop-cart-peek-minus"
                    class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                    disabled={busy}
                    onclick={() => decrementLine(line)}
                  >−</button>
                  <span class="text-[10px]">{line.quantity}</span>
                  <button
                    type="button"
                    data-testid="shop-cart-peek-plus"
                    class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                    disabled={atMaxQty(line)}
                    onclick={() => bumpCartLine(line.index, 1)}
                  >+</button>
                </div>
              </div>
            </div>
          {/each}
        </div>
        {#if count >= 4}
          <div
            class="flex justify-center gap-1 py-1 shrink-0"
            data-testid="shop-cart-peek-dots"
            aria-hidden="true"
          >
            {#each items as _, i}
              <div
                class="h-1.5 rounded-full transition-colors duration-150 {i === peekScrollIndex ? 'w-3 bg-[#ff8c42]' : 'w-1.5 bg-[#555]'}"
              ></div>
            {/each}
          </div>
        {/if}
        {@render checkoutBar("shop-cart-peek-total")}
      </div>

    <!-- EXPANDED 2+ — вертикальный компактный список (§ S2-канон: развёрнутый вид) -->
    {:else if mode === MODE_EXPANDED && count >= 2}
      <div
        class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1"
        data-testid="shop-cart-expanded-horizontal"
        data-cart-layout="vertical"
      >
        <div class="min-h-0 flex-1 space-y-1.5 overflow-y-auto">
          {#each items as line (line.index)}
            <div
              class="flex items-center gap-2 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-2 py-1.5 cursor-pointer"
              data-testid="shop-cart-expanded-card"
              role="button"
              tabindex="0"
              onclick={(e) => tapToProduct(line, e)}
            >
              <div
                data-testid="shop-cart-expanded-product-image"
                class="shrink-0"
                onclick={(e) => {
                  e.stopPropagation()
                  const cart_line = line.index
                  const selected_modifiers = line.selected_modifiers
                  void cart_line
                  void selected_modifiers
                  push(openEditCard(line))
                }}
              >
                {@render lineThumb(line, "h-10 w-10 shrink-0")}
              </div>
              <div class="min-w-0 flex-1">
                <p class="line-clamp-1 text-xs font-medium">{line.product_name}</p>
                <p class="text-[10px] text-[#a0a0a0]">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
              </div>
              <div class="flex shrink-0 items-center gap-1">
                <button
                  type="button"
                  data-testid="shop-cart-expanded-minus"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={busy}
                  onclick={() => decrementLine(line)}
                >−</button>
                <span class="min-w-[1rem] text-center text-[10px]">{line.quantity}</span>
                <button
                  type="button"
                  data-testid="shop-cart-expanded-plus"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={atMaxQty(line)}
                  onclick={() => bumpCartLine(line.index, 1)}
                >+</button>
                <button
                  type="button"
                  data-testid="shop-cart-expanded-delete"
                  class="ml-1 text-[10px] text-red-400 disabled:opacity-40"
                  disabled={busy}
                  onclick={() => removeCartLine(line.index)}
                >Удалить</button>
              </div>
            </div>
          {/each}
        </div>
        {@render checkoutBar()}
      </div>

    <!-- 1 товар — широкая горизонтальная карточка (только peek/hidden, expanded недоступен) -->
    {:else if singleItem}
      <div
        class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1"
        data-cart-layout="horizontal"
      >
          <div
            class="flex min-h-0 flex-1 gap-2 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-2 cursor-pointer"
            data-testid="shop-cart-expanded-single"
            role="button"
            tabindex="0"
            onclick={(e) => tapToProduct(singleItem, e)}
          >
          {@render lineThumb(singleItem, "h-16 w-16 shrink-0")}
          <div class="min-w-0 flex-1">
            <p class="line-clamp-2 text-sm font-medium">{singleItem.product_name}</p>
            <p class="text-xs text-[#a0a0a0]">{roundPrice(singleItem.unit_total)}₽ × {singleItem.quantity}</p>
            {#if singleItem.selected_modifiers?.length}
              <ul class="mt-0.5 space-y-0.5 text-[11px] text-[#888]">
                {#each singleItem.selected_modifiers as mod (mod.id)}
                  <li>{modifierLabel(mod)}</li>
                {/each}
              </ul>
            {/if}
            {@render lineControls(singleItem)}
          </div>
        </div>
        {@render checkoutBar()}
      </div>
    {/if}
  </div>
{/if}
