<script>
  import { onMount } from "svelte"
  import { frequentItems } from "../lib/frequentRepeatStore.js"

  let items = $state([])
  /** Счётчики карточек: ключ карточки → количество (локально, до add-to-cart в F4) */
  let quantities = $state({})
  /** URL с 404 — не показывать broken-icon */
  let brokenUrls = $state(/** @type {Set<string>} */ (new Set()))

  // Клиентский предохранитель поверх бэкового MAX_REPEAT_ITEMS
  let topItems = $derived(items.slice(0, 3))

  onMount(() => frequentItems.subscribe((v) => { items = Array.isArray(v) ? v : [] }))

  function keyOf(item, i) {
    return `${item.product_id}-${i}`
  }

  function qtyOf(key) {
    return quantities[key] || 1
  }

  function bump(key, delta) {
    quantities = { ...quantities, [key]: Math.max(1, qtyOf(key) + delta) }
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
    <div class="flex gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      {#each topItems as item, i (keyOf(item, i))}
        {@const key = keyOf(item, i)}
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
  </div>
{/if}
