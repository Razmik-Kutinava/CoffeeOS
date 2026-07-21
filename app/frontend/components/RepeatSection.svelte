<script>
  import { onMount } from "svelte"
  import {
    frequentItems,
    frequentQuantities,
    frequentCardKey,
    setFrequentQty,
    repeatAllToCart,
    repeatMore,
    repeatPayOneClick,
    repeatFeedback
  } from "../lib/frequentRepeatStore.js"

  let items = $state([])
  /** Зеркало store frequentQuantities — источник истины store + localStorage (F3, ТЗ Шаг 10) */
  let storeQty = $state({})
  /** URL с 404 — не показывать broken-icon */
  let brokenUrls = $state(/** @type {Set<string>} */ (new Set()))
  /** Тост «повторить»: success/error из repeatFeedback (F4, ТЗ Шаг 11) */
  let feedback = $state(null)
  let repeatBusy = $state(false)
  let toastTimer = null

  // Клиентский предохранитель поверх бэкового MAX_REPEAT_ITEMS
  let topItems = $derived(items.slice(0, 3))

  onMount(() => {
    const unsubItems = frequentItems.subscribe((v) => { items = Array.isArray(v) ? v : [] })
    const unsubQty = frequentQuantities.subscribe((v) => { storeQty = v || {} })
    const unsubFeedback = repeatFeedback.subscribe((v) => {
      feedback = v
      if (toastTimer) clearTimeout(toastTimer)
      if (v) toastTimer = setTimeout(() => repeatFeedback.set(null), 2500)
    })
    return () => {
      unsubItems(); unsubQty(); unsubFeedback()
      if (toastTimer) clearTimeout(toastTimer)
    }
  })

  async function onRepeatClick() {
    if (repeatBusy) return
    repeatBusy = true
    try {
      await repeatAllToCart()
    } finally {
      repeatBusy = false
    }
  }

  async function onPayClick() {
    if (repeatBusy) return
    repeatBusy = true
    try {
      await repeatPayOneClick()
    } finally {
      repeatBusy = false
    }
  }

  function qtyOf(key) {
    return storeQty[key] || 1
  }

  function bump(key, delta) {
    setFrequentQty(key, qtyOf(key) + delta)
  }

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }
</script>

{#if topItems.length}
  <div
    data-testid="shop-repeat-section"
    class="shrink-0 px-1 pt-1.5"
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
          class="flex w-[min(28vw,110px)] shrink-0 flex-col gap-1 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-1.5"
        >
          {#if url && !brokenUrls.has(url)}
            <img
              data-testid="shop-repeat-thumb"
              src={url}
              alt=""
              class="h-12 w-full rounded-lg object-cover object-top"
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
              class="flex h-12 w-full items-center justify-center rounded-lg bg-[#333] text-[9px] text-[#888]"
            >Нет фото</div>
          {/if}
          <p class="line-clamp-1 text-[11px] font-medium leading-tight">{item.name}</p>
          <p class="text-[10px] text-[#ff8c42]">{roundPrice(item.price)}₽</p>
          <div class="mt-0.5 flex items-center justify-between gap-0.5">
            <button
              type="button"
              data-testid="shop-repeat-minus"
              class="min-h-6 min-w-6 rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[12px] leading-none disabled:opacity-40"
              disabled={qtyOf(key) <= 1}
              onclick={() => bump(key, -1)}
            >−</button>
            <span data-testid="shop-repeat-qty" class="min-w-[1rem] text-center text-[11px] font-medium">{qtyOf(key)}</span>
            <button
              type="button"
              data-testid="shop-repeat-plus"
              class="min-h-6 min-w-6 rounded bg-[#3a3a3a] px-1.5 py-0.5 text-[12px] leading-none"
              onclick={() => bump(key, 1)}
            >+</button>
          </div>
        </div>
      {/each}
    </div>
    <div class="mt-1.5 flex items-center gap-2">
      <button
        type="button"
        data-testid="shop-repeat-one-click"
        class="min-h-8 flex-1 rounded-lg bg-[#ff8c42] px-3 py-1.5 text-[12px] font-semibold text-black disabled:opacity-40"
        disabled={repeatBusy}
        onclick={onRepeatClick}
      >повторить в 1 клик</button>
      <button
        type="button"
        data-testid="shop-repeat-pay-one-click"
        class="min-h-8 flex-1 rounded-lg border border-[#ff8c42] px-3 py-1.5 text-[12px] font-semibold text-[#ff8c42] disabled:opacity-40"
        disabled={repeatBusy}
        onclick={onPayClick}
      >оплатить в 1 клик</button>
      <button
        type="button"
        data-testid="shop-repeat-more"
        class="min-h-8 shrink-0 rounded-lg bg-[#3a3a3a] px-3 py-1.5 text-[12px]"
        onclick={() => repeatMore()}
      >+ещё</button>
    </div>
  </div>
{/if}
