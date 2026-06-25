<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    cartItems,
    cartTotal,
    cartSheetMode,
    cartSheetBusy,
    isCatalogRoute,
    refreshCartSheet,
    expandFromSwipe,
    bumpCartLine,
    removeCartLine,
    bindCartSheetEvents,
    cartLineCount,
    MAX_ITEM_QUANTITY
  } from "../lib/cartSheetStore.js"
  import { MODE_EMPTY, MODE_EXPANDED, MODE_PEEK, MODE_HIDDEN, sheetHeightVh, SWIPE_UP_PX } from "../lib/cartSheetThresholds.js"

  let hash = $state(typeof window !== "undefined" ? window.location.hash : "")
  let items = $state([])
  let total = $state(0)
  let mode = $state(MODE_EMPTY)
  let busy = $state(false)
  let touchStartY = 0

  let onCatalog = $derived(isCatalogRoute(hash))
  let count = $derived(items.length)
  let heightVh = $derived(sheetHeightVh(mode, count))

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }

  function modifierLabel(mod) {
    const extra = Number(mod.price) > 0 ? ` (+${roundPrice(mod.price)}₽)` : ""
    return `${mod.name}${extra}`
  }

  function atMaxQty(line) {
    return Number(line.quantity) >= MAX_ITEM_QUANTITY
  }

  function onTouchStart(event) {
    touchStartY = event.touches[0]?.clientY ?? 0
  }

  function onTouchEnd(event) {
    const endY = event.changedTouches[0]?.clientY ?? touchStartY
    const dy = touchStartY - endY
    if (dy >= SWIPE_UP_PX) expandFromSwipe()
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
    const unsubBusy = cartSheetBusy.subscribe((v) => {
      busy = v
    })
    const onHash = () => {
      hash = window.location.hash
    }

    bindCartSheetEvents()
    window.addEventListener("hashchange", onHash)
    refreshCartSheet().catch(() => {})

    return () => {
      unsubItems()
      unsubTotal()
      unsubMode()
      unsubBusy()
      window.removeEventListener("hashchange", onHash)
    }
  })
</script>

{#if onCatalog}
  <div
    data-testid="shop-cart-sheet"
    data-cart-sheet-mode={mode}
    class="cart-sheet fixed left-0 right-0 z-50 mx-auto max-w-lg border-t border-[#3a3a3a] bg-[#2a2a2a]/98 backdrop-blur transition-[height] duration-300 ease-out"
    style:height="{heightVh}vh"
    style:bottom="3.5rem"
    ontouchstart={onTouchStart}
    ontouchend={onTouchEnd}
  >
    <div class="drag-handle mx-auto mt-1.5 h-1 w-10 rounded-full bg-[#555]" aria-hidden="true"></div>

    {#if mode === MODE_EMPTY || !count}
      <p
        data-testid="shop-cart-sheet-empty"
        class="px-4 py-6 text-center text-sm italic text-[#888]"
      >
        тут будут твои заказы
      </p>
    {:else if mode === MODE_HIDDEN}
      <div class="flex items-center justify-between gap-3 px-4 py-2">
        {#if items[0]}
          <div class="w-10 shrink-0">
            {#if items[0].image_url}
              <img src={items[0].image_url} alt="" class="h-10 w-10 rounded-lg object-cover" decoding="async" />
            {:else}
              <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-[#333] text-[9px] text-[#888]">нет</div>
            {/if}
          </div>
        {/if}
        <span class="ml-auto text-sm font-semibold text-[#ff8c42]">{roundPrice(total)}₽</span>
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
      <div class="flex items-end justify-between gap-2 px-3 pb-2 pt-1">
        <div class="flex min-w-0 flex-1 gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {#each items as line (line.index)}
            <div class="w-14 shrink-0" data-testid="shop-cart-peek-line">
              {#if line.image_url}
                <img src={line.image_url} alt="" class="h-14 w-14 rounded-lg object-cover" decoding="async" />
              {:else}
                <div class="flex h-14 w-14 items-center justify-center rounded-lg bg-[#333] text-[10px] text-[#888]">нет</div>
              {/if}
              <div class="mt-0.5 flex items-center justify-center gap-0.5">
                <button
                  type="button"
                  data-testid="shop-cart-peek-minus"
                  class="rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[10px] leading-none disabled:opacity-40"
                  disabled={busy}
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
                  disabled={busy || atMaxQty(line)}
                  aria-label="Увеличить"
                  onclick={() => bumpCartLine(line.index, 1)}
                >
                  +
                </button>
              </div>
            </div>
          {/each}
        </div>
        <button
          type="button"
          data-testid="shop-cart-sheet-checkout"
          class="shrink-0 rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-semibold text-black"
          onclick={() => push("/checkout")}
        >
          +цена
        </button>
      </div>
    {:else}
      <div class="flex h-[calc(100%-0.75rem)] flex-col overflow-hidden px-3 pb-2 pt-1">
        <div class="min-h-0 flex-1 space-y-2 overflow-y-auto">
          {#each items as line (line.index)}
            <div class="flex gap-2 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-2">
              {#if line.image_url}
                <img src={line.image_url} alt="" class="h-16 w-16 shrink-0 rounded-lg object-cover" decoding="async" />
              {/if}
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
                <div class="mt-1 flex items-center gap-1.5">
                  <button
                    type="button"
                    data-testid="shop-cart-expanded-minus"
                    class="rounded bg-[#3a3a3a] px-2 py-0.5 text-xs disabled:opacity-40"
                    disabled={busy}
                    onclick={() => bumpCartLine(line.index, -1)}
                  >
                    −
                  </button>
                  <span class="text-xs">{line.quantity}</span>
                  <button
                    type="button"
                    data-testid="shop-cart-expanded-plus"
                    class="rounded bg-[#3a3a3a] px-2 py-0.5 text-xs disabled:opacity-40"
                    disabled={busy || atMaxQty(line)}
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
