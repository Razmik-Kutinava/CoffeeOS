<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    cartItems,
    cartTotal,
    cartSheetMode,
    cartSheetBusy,
    isCatalogRoute,
    onCatalogRouteChange,
    refreshCartSheet,
    handleSheetGestureDelta,
    bumpCartLine,
    removeCartLine,
    bindCartSheetEvents,
    atMinQty,
    atMaxQty
  } from "../lib/cartSheetStore.js"
  import {
    MODE_EMPTY,
    MODE_EXPANDED,
    MODE_PEEK,
    MODE_HIDDEN,
    sheetHeightVh,
    SHEET_TRANSITION_MS,
    CART_SHEET_BOTTOM_REM,
    CART_SHEET_MAX_WIDTH_PX
  } from "../lib/cartSheetThresholds.js"

  let hash = $state(typeof window !== "undefined" ? window.location.hash : "")
  let items = $state([])
  let total = $state(0)
  let mode = $state(MODE_EMPTY)
  let busy = $state(false)
  let gestureStartY = 0
  let gestureZoneEl = $state(null)

  let onCatalog = $derived(isCatalogRoute(hash))
  let count = $derived(items.length)
  let heightVh = $derived(sheetHeightVh(mode, count))
  let singleItem = $derived(count === 1 ? items[0] : null)

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }

  function modifierLabel(mod) {
    const extra = Number(mod.price) > 0 ? ` (+${roundPrice(mod.price)}₽)` : ""
    return `${mod.name}${extra}`
  }

  function onGestureStart(event) {
    gestureStartY = event.touches?.[0]?.clientY ?? event.clientY
    if (event.cancelable) event.preventDefault()
    event.currentTarget?.setPointerCapture?.(event.pointerId)
  }

  function onGestureEnd(event) {
    const endY = event.changedTouches?.[0]?.clientY ?? event.clientY
    handleSheetGestureDelta(gestureStartY, endY)
    event.currentTarget?.releasePointerCapture?.(event.pointerId)
  }

  function onGestureCancel() {
    gestureStartY = 0
  }

  onMount(() => {
    const unsubItems = cartItems.subscribe((v) => { items = v })
    const unsubTotal = cartTotal.subscribe((v) => { total = v })
    const unsubMode  = cartSheetMode.subscribe((v) => { mode = v })
    const unsubBusy  = cartSheetBusy.subscribe((v) => { busy = v })

    const onHash = () => {
      const next = window.location.hash
      const wasCatalog = isCatalogRoute(hash)
      hash = next
      if (wasCatalog !== isCatalogRoute(hash)) {
        onCatalogRouteChange(isCatalogRoute(hash))
      }
    }

    bindCartSheetEvents()
    window.addEventListener("hashchange", onHash)
    refreshCartSheet().catch(() => {})

    // Touch-события с { passive: false } — нужно для preventDefault() при свайпе
    const gz = gestureZoneEl
    if (gz) {
      gz.addEventListener("touchstart",  onGestureStart, { passive: false })
      gz.addEventListener("touchend",    onGestureEnd,   { passive: false })
      gz.addEventListener("touchcancel", onGestureCancel, { passive: true })
    }

    return () => {
      unsubItems(); unsubTotal(); unsubMode(); unsubBusy()
      window.removeEventListener("hashchange", onHash)
      if (gz) {
        gz.removeEventListener("touchstart",  onGestureStart)
        gz.removeEventListener("touchend",    onGestureEnd)
        gz.removeEventListener("touchcancel", onGestureCancel)
      }
    }
  })
</script>

{#snippet lineControls(line)}
  <div class="mt-1 flex items-center gap-1.5">
    <button
      type="button"
      data-testid="shop-cart-expanded-minus"
      class="rounded bg-[#3a3a3a] px-2 py-0.5 text-xs disabled:opacity-40"
      disabled={atMinQty(line)}
      onclick={() => bumpCartLine(line.index, -1)}
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
    <span class="text-sm text-[#a0a0a0]" data-testid={totalTestId}>{roundPrice(total)}₽</span>
    <button
      type="button"
      data-testid="shop-cart-sheet-checkout"
      class="rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
      onclick={() => push("/checkout")}
    >Оформить</button>
  </div>
{/snippet}

{#if onCatalog}
  <div
    data-testid="shop-cart-sheet"
    data-cart-sheet-mode={mode}
    class="cart-sheet fixed left-0 right-0 z-50 mx-auto flex flex-col overflow-hidden border-t border-[#3a3a3a] bg-[#2a2a2a]/98 backdrop-blur transition-[height] ease-out"
    style:height="{heightVh}vh"
    style:bottom="{CART_SHEET_BOTTOM_REM}rem"
    style:max-width="{CART_SHEET_MAX_WIDTH_PX}px"
    style:transition-duration="{SHEET_TRANSITION_MS}ms"
  >
    <!-- Drag-handle / gesture zone -->
    <div
      bind:this={gestureZoneEl}
      data-testid="shop-cart-sheet-gesture-zone"
      class="cart-sheet-gesture-zone flex min-h-14 w-full shrink-0 touch-none select-none flex-col items-center justify-center border-b border-[#3a3a3a]/60"
      style:touch-action="none"
      role="button"
      tabindex="-1"
      aria-label="Потяните вверх или вниз, чтобы изменить высоту корзины"
      onpointerdown={onGestureStart}
      onpointerup={onGestureEnd}
      onpointercancel={onGestureCancel}
    >
      <div class="drag-handle h-1.5 w-12 rounded-full bg-[#777]" aria-hidden="true"></div>
    </div>

    <!-- EMPTY -->
    {#if mode === MODE_EMPTY || !count}
      <p data-testid="shop-cart-sheet-empty" class="px-4 py-6 text-center text-sm italic text-[#888]">
        тут будут твои заказы
      </p>

    <!-- HIDDEN — чип с суммой (ТЗ S2a) -->
    {:else if mode === MODE_HIDDEN}
      <div
        class="flex flex-1 min-h-0 items-center justify-between gap-2 px-3 pb-1 pt-1"
        data-testid="shop-cart-hidden-chip"
      >
        <span data-testid="shop-cart-hidden-total" class="text-sm font-semibold text-[#ff8c42]">{roundPrice(total)}₽</span>
        <button
          type="button"
          data-testid="shop-cart-sheet-checkout"
          class="shrink-0 rounded-lg bg-[#ff8c42] px-3 py-1.5 text-sm font-semibold text-black"
          onclick={() => push("/checkout")}
        >+цена</button>
      </div>

    <!-- PEEK 2+ — вертикальный компактный список (дефолт при добавлении) -->
    {:else if mode === MODE_PEEK && count >= 2}
      <div class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1" data-testid="shop-cart-peek-list">
        <div class="min-h-0 flex-1 space-y-1.5 overflow-y-auto">
          {#each items as line (line.index)}
            <div
              class="flex items-center gap-2 rounded-lg border border-[#3a3a3a] bg-[#1f1f1f] px-2 py-1.5"
              data-testid="shop-cart-peek-line"
            >
              {@render lineThumb(line, "h-10 w-10 shrink-0")}
              <div class="min-w-0 flex-1">
                <p class="line-clamp-1 text-xs font-medium">{line.product_name}</p>
                <p class="text-[10px] text-[#a0a0a0]">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
              </div>
              <div class="flex shrink-0 items-center gap-1">
                <button
                  type="button"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={atMinQty(line)}
                  onclick={() => bumpCartLine(line.index, -1)}
                >−</button>
                <span class="min-w-[1rem] text-center text-[10px]">{line.quantity}</span>
                <button
                  type="button"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={atMaxQty(line)}
                  onclick={() => bumpCartLine(line.index, 1)}
                >+</button>
              </div>
            </div>
          {/each}
        </div>
        {@render checkoutBar("shop-cart-peek-total")}
      </div>

    <!-- EXPANDED 2+ — горизонтальный ряд карточек (свайп вверх из peek) -->
    {:else if mode === MODE_EXPANDED && count >= 2}
      <div class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1" data-testid="shop-cart-expanded-horizontal">
        <div class="flex min-h-0 flex-1 gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {#each items as line (line.index)}
            <div
              class="flex w-[min(28vw,110px)] shrink-0 flex-col gap-1 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-1.5"
              data-testid="shop-cart-expanded-line"
            >
              {@render lineThumb(line, "h-16 w-full rounded-lg")}
              <div class="min-w-0">
                <p class="line-clamp-2 text-[11px] font-medium leading-tight">{line.product_name}</p>
                <p class="mt-0.5 text-[10px] text-[#a0a0a0]">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
                <div class="mt-1 flex items-center justify-between gap-0.5">
                  <button
                    type="button"
                    class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                    disabled={atMinQty(line)}
                    onclick={() => bumpCartLine(line.index, -1)}
                  >−</button>
                  <span class="text-[10px]">{line.quantity}</span>
                  <button
                    type="button"
                    class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                    disabled={atMaxQty(line)}
                    onclick={() => bumpCartLine(line.index, 1)}
                  >+</button>
                </div>
              </div>
            </div>
          {/each}
        </div>
        {@render checkoutBar()}
      </div>

    <!-- PEEK 1 товар / EXPANDED 1 товар — широкая горизонтальная карточка -->
    {:else if singleItem}
      <div class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1">
        <div
          class="flex min-h-0 flex-1 gap-2 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-2"
          data-testid="shop-cart-expanded-single"
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
