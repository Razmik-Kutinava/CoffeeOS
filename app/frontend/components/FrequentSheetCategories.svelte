<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { frequentCategories } from "../lib/frequentRepeatStore.js"

  let categories = $state({})
  let brokenIds = $state(/** @type {Set<string|number>} */ (new Set()))

  let entries = $derived(
    Object.entries(categories || {}).filter(([, products]) => Array.isArray(products) && products.length)
  )

  onMount(() => {
    const unsub = frequentCategories.subscribe((v) => {
      categories = v && typeof v === "object" ? v : {}
    })
    return unsub
  })

  function markBroken(productId) {
    const next = new Set(brokenIds)
    next.add(productId)
    brokenIds = next
  }

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }
</script>

{#if entries.length}
  <div
    data-testid="shop-sheet-frequent-categories"
    class="mb-2 space-y-2 border-b border-[#3a3a3a]/60 pb-2"
  >
    {#each entries as [name, products] (name)}
      <div data-testid="shop-sheet-frequent-category">
        <div class="mb-1 flex items-center justify-between px-0.5">
          <p class="text-xs font-semibold">{name}</p>
          <span class="text-[10px] text-[#ff8c42]">Смотреть все →</span>
        </div>
        <div class="flex gap-2 overflow-x-auto [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {#each products as product (product.id)}
            <button
              type="button"
              data-testid="shop-sheet-frequent-product"
              class="flex w-[min(28vw,110px)] shrink-0 flex-col gap-1 rounded-xl border border-[#3a3a3a] bg-[#1f1f1f] p-1.5 text-left"
              onclick={() => push(`/product/${product.id}`)}
            >
              {#if product.image_url && !brokenIds.has(product.id)}
                <img
                  src={product.image_url}
                  alt=""
                  class="h-12 w-full rounded-lg object-cover object-top"
                  decoding="async"
                  onerror={() => markBroken(product.id)}
                />
              {:else}
                <div class="flex h-12 w-full items-center justify-center rounded-lg bg-[#333] text-[9px] text-[#888]">
                  Нет фото
                </div>
              {/if}
              <p class="line-clamp-2 text-[11px] font-medium leading-tight">{product.name}</p>
              <p class="text-[10px] text-[#ff8c42]">{roundPrice(product.price)}₽</p>
            </button>
          {/each}
        </div>
      </div>
    {/each}
  </div>
{/if}
