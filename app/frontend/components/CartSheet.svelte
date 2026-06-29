<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    cartItems,
    cartTotal,
    cartSheetMode,
    cartSheetExpandedLayout,
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
    EXPANDED_LAYOUT_HORIZONTAL,
    sheetHeightVh,
    SHEET_TRANSITION_MS,
    CART_SHEET_BOTTOM_REM,
    CART_SHEET_MAX_WIDTH_PX
  } from "../lib/cartSheetThresholds.js"

  let hash = $state(typeof window !== "undefined" ? window.location.hash : "")
  let items = $state([])
  let total = $state(0)
  let mode = $state(MODE_EMPTY)
  let expandedLayout = $state("vertical")
  let busy = $state(false)
  let gestureStartY = 0
  let gestureZoneEl = $state(null)

  let onCatalog = $derived(isCatalogRoute(hash))
  let count = $derived(items.length)
  let heightVh = $derived(sheetHeightVh(mode, count, expandedLayout))
  let singleItem = $derived(count === 1 ? items[0] : null)
  let expandedHorizontal = $derived(
    mode === MODE_EXPANDED && count >= 2 && expandedLayout === EXPANDED_LAYOUT_HORIZONTAL
  )

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }

  function modifierLabel(mod) {
    const extra = Number(mod.price) > 0 ? ` (+${roundPrice(mod.price)}₽)` : ""
    return `${mod.name}${extra}`
  }

  function applySheetGesture(startY, endY) {
    handleSheetGestureDelta(startY, endY)
  }

  function onGestureStart(event) {
    gestureStartY = event.touches?.[0]?.clientY ?? event.clientY
    if (event.cancelable) event.preventDefault()
    event.currentTarget?.setPointerCapture?.(event.pointerId)
  }

  function onGestureEnd(event) {
    const endY = event.changedTouches?.[0]?.clientY ?? event.clientY
    applySheetGesture(gestureStartY, endY)
    event.currentTarget?.releasePointerCapture?.(event.pointerId)
  }

  function onGestureCancel() {
    gestureStartY = 0
  }

  onMount(() => {
    const unsubItems = cartItems.subscribe((v) => {
      items = v
    })
    const unsubTotal = cartTotal.subscribe((v) => {
      total = v
    })
    const unsubMode = cartSheetMode.subscribe((v) => {
      mode = v
    })
    const unsubLayout = cartSheetExpandedLayout.subscribe((v) => {
      expandedLayout = v
    })
    const unsubBusy = cartSheetBusy.subscribe((v) => {
      busy = v
    })
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

    // Touch-события с { passive: false } — нельзя передать через Svelte-шаблон.
    // Нужно для preventDefault() при свайпе, иначе браузер скроллит страницу.
    const gz = gestureZoneEl
    if (gz) {
      gz.addEventListener("touchstart", onGestureStart, { passive: false })
      gz.addEventListener("touchend", onGestureEnd, { passive: false })
      gz.addEventListener("touchcancel", onGestureCancel, { passive: true })
    }

    return () => {
      unsubItems()
      unsubTotal()
      unsubMode()
      unsubLayout()
      unsubBusy()
      window.removeEventListener("hashchange", onHash)
      if (gz) {
        gz.removeEventListener("touchstart", onGestureStart)
        gz.removeEventListener("touchend", onGestureEnd)
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
    >
      −
    </button>
    <span class="text-xs">{line.quantity}</span>
    <button
      type="button"
      data-testid="shop-cart-expanded-plus"
      class="rounded bg-[#3a3a3a] px-2 py-0.5 text-xs disabled:opacity-40"
      disabled={atMaxQty(line)}
      onclick={() => bumpCartLine(line.index, 1)}
    >
      +
    </button>
    <button
      type="button"
      data-testid="shop-cart-expanded-delete"
      class="ml-auto text-xs text-red-400 disabled:opacity-40"
      disabled={busy}
      onclick={() => removeCartLine(line.index)}
    >
      Удалить
    </button>
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

{#if onCatalog}
  <div
    data-testid="shop-cart-sheet"
    data-cart-sheet-mode={mode}
    data-cart-sheet-layout={expandedLayout}
    class="cart-sheet fixed left-0 right-0 z-50 mx-auto flex flex-col overflow-hidden border-t border-[#3a3a3a] bg-[#2a2a2a]/98 backdrop-blur transition-[height] ease-out"
    style:height="{heightVh}vh"
    style:bottom="{CART_SHEET_BOTTOM_REM}rem"
    style:max-width="{CART_SHEET_MAX_WIDTH_PX}px"
    style:transition-duration="{SHEET_TRANSITION_MS}ms"
  >
    <div
      bind:this={gestureZoneEl}
      data-testid="shop-cart-sheet-gesture-zone"
      class="cart-sheet-gesture-zone flex min-h-11 w-full shrink-0 touch-none select-none flex-col items-center justify-center border-b border-[#3a3a3a]/60"
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

    {#if mode === MODE_EMPTY || !count}
      <p
        data-testid="shop-cart-sheet-empty"
        class="px-4 py-6 text-center text-sm italic text-[#888]"
      >
        тут будут твои заказы
      </p>
    {:else if mode === MODE_HIDDEN}
      <div class="flex flex-1 min-h-0 items-end justify-between gap-2 px-3 pb-2 pt-0.5">
        <div
          class="flex min-w-0 flex-1 flex-col gap-0.5 overflow-hidden"
          data-testid="shop-cart-hidden-heads"
          data-cart-layout="vertical"
        >
          {#each items as line (line.index)}
            <div class="h-2.5 overflow-hidden rounded-t-lg" data-testid="shop-cart-hidden-head">
              {@render lineThumb(line, "h-8 w-full", "object-top")}
            </div>
          {/each}
        </div>
        <span data-testid="shop-cart-hidden-total" class="shrink-0 text-sm font-semibold text-[#ff8c42]">{roundPrice(total)}₽</span>
        <button
          type="button"
          data-testid="shop-cart-sheet-checkout"
          class="shrink-0 rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
          onclick={() => push("/checkout")}
        >
          +цена
        </button>
      </div>
    {:else if mode === MODE_PEEK}
      <div class="flex flex-1 min-h-0 items-end justify-between gap-2 px-3 pb-2 pt-1">
        <div
          class="flex min-w-0 flex-1 gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          data-cart-layout="horizontal"
        >
          {#each items as line (line.index)}
            <div class="w-14 shrink-0" data-testid="shop-cart-peek-line">
              {@render lineThumb(line, "h-14 w-14")}
              <div class="mt-0.5 flex items-center justify-center gap-0.5">
                <button
                  type="button"
                  data-testid="shop-cart-peek-minus"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={atMinQty(line)}
                  aria-label="Уменьшить"
                  onclick={() => bumpCartLine(line.index, -1)}
                >
                  −
                </button>
                <span class="min-w-[1rem] text-center text-[10px]">{line.quantity}</span>
                <button
                  type="button"
                  data-testid="shop-cart-peek-plus"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={atMaxQty(line)}
                  aria-label="Увеличить"
                  onclick={() => bumpCartLine(line.index, 1)}
                >
                  +
                </button>
              </div>
            </div>
          {/each}
        </div>
        <span data-testid="shop-cart-peek-total" class="shrink-0 text-sm font-semibold text-[#ff8c42]">{roundPrice(total)}₽</span>
        <button
          type="button"
          data-testid="shop-cart-sheet-checkout"
          class="shrink-0 rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
          onclick={() => push("/checkout")}
        >
          +цена
        </button>
      </div>
    {:else if expandedHorizontal}
      <div
        class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1"
        data-cart-layout="horizontal"
        data-testid="shop-cart-expanded-horizontal"
      >
        <div
          class="flex min-h-0 flex-1 gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        >
          {#each items as line (line.index)}
            <div
              class="flex w-[min(85vw,280px)] shrink-0 flex-col gap-2 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-2"
              data-testid="shop-cart-expanded-line"
            >
              {@render lineThumb(line, "h-24 w-full")}
              <div class="min-w-0 flex-1">
                <p class="line-clamp-2 text-sm font-medium">{line.product_name}</p>
                <p class="text-xs text-[#a0a0a0]">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
                {#if line.selected_modifiers?.length}
                  <ul class="mt-0.5 space-y-0.5 text-[11px] text-[#888]">
                    {#each line.selected_modifiers as mod (mod.id)}
                      <li>{modifierLabel(mod)}</li>
                    {/each}
                  </ul>
                {/if}
                {@render lineControls(line)}
              </div>
            </div>
          {/each}
        </div>
        <div class="mt-2 flex items-center justify-end gap-2 border-t border-[#3a3a3a] pt-2">
          <span class="text-sm text-[#a0a0a0]">{roundPrice(total)}₽</span>
          <button
            type="button"
            data-testid="shop-cart-sheet-checkout"
            class="rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
            onclick={() => push("/checkout")}
          >
            +цена
          </button>
        </div>
      </div>
    {:else if singleItem}
      <div class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1" data-cart-layout="horizontal">
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
        <div class="mt-2 flex items-center justify-end gap-2 border-t border-[#3a3a3a] pt-2">
          <span class="text-sm text-[#a0a0a0]">{roundPrice(total)}₽</span>
          <button
            type="button"
            data-testid="shop-cart-sheet-checkout"
            class="rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
            onclick={() => push("/checkout")}
          >
            +цена
          </button>
        </div>
      </div>
    {:else}
      <div class="flex flex-1 min-h-0 flex-col overflow-hidden px-3 pb-2 pt-1" data-cart-layout="vertical">
        <div class="min-h-0 flex-1 space-y-2 overflow-y-auto">
          {#each items as line (line.index)}
            <div class="flex gap-2 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-2" data-testid="shop-cart-expanded-line">
              {@render lineThumb(line, "h-16 w-16 shrink-0")}
              <div class="min-w-0 flex-1">
                <p class="line-clamp-2 text-sm font-medium">{line.product_name}</p>
                <p class="text-xs text-[#a0a0a0]">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
                {#if line.selected_modifiers?.length}
                  <ul class="mt-0.5 space-y-0.5 text-[11px] text-[#888]">
                    {#each line.selected_modifiers as mod (mod.id)}
                      <li>{modifierLabel(mod)}</li>
                    {/each}
                  </ul>
                {/if}
                {@render lineControls(line)}
              </div>
            </div>
          {/each}
        </div>
        <div class="mt-2 flex items-center justify-end gap-2 border-t border-[#3a3a3a] pt-2">
          <span class="text-sm text-[#a0a0a0]">{roundPrice(total)}₽</span>
          <button
            type="button"
            data-testid="shop-cart-sheet-checkout"
            class="rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
            onclick={() => push("/checkout")}
          >
            +цена
          </button>
        </div>
      </div>
    {/if}
  </div>
{/if}
