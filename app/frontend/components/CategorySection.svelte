<script>
  import { push } from "svelte-spa-router"
  import { cartSheetMode } from "../lib/cartSheetStore.js"
  import { MODE_HIDDEN } from "../lib/cartSheetThresholds.js"

  let { category } = $props()

  /** Режим шторки — плотность карточек каталога (hidden crop vs peek/expanded) */
  let sheetMode = $state(MODE_HIDDEN)
  /** product_id с битым URL — fallback «Нет фото» */
  let brokenIds = $state(/** @type {Set<string|number>} */ (new Set()))

  $effect(() => {
    const unsub = cartSheetMode.subscribe((v) => {
      sheetMode = v || MODE_HIDDEN
    })
    return unsub
  })

  function markBroken(productId) {
    const next = new Set(brokenIds)
    next.add(productId)
    brokenIds = next
  }

  function hasImage(product) {
    return Boolean(product.image_url) && !brokenIds.has(product.id)
  }
</script>

<section class="mb-8">
  <div class="mb-3 flex items-center justify-between">
    <h2 class="text-lg font-semibold">{category.name}</h2>
    <button
      class="text-sm text-[#ff8c42] cursor-pointer bg-transparent border-none p-0"
      onclick={() => push(`/category/${category.id}`)}
    >
      Смотреть все →
    </button>
  </div>
  <div class="flex gap-3 overflow-x-auto pb-2 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
    {#each category.products as product (product.id)}
      <button
        type="button"
        data-testid="shop-catalog-card"
        data-catalog-card-mode={sheetMode}
        onclick={() => push(`/product/${product.id}`)}
        class="w-[8.5rem] shrink-0 overflow-hidden rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] text-left cursor-pointer"
      >
        <div
          data-testid="shop-catalog-card-media"
          class="catalog-card-media aspect-[4/3] min-h-24 w-full overflow-hidden bg-[#333]"
        >
          {#if hasImage(product)}
            <img
              data-testid="shop-catalog-card-image"
              src={product.image_url}
              alt=""
              class="h-full w-full object-cover object-top"
              decoding="async"
              onerror={() => markBroken(product.id)}
            />
          {:else}
            <div
              data-testid="shop-catalog-card-no-photo"
              class="flex h-full min-h-24 w-full items-center justify-center bg-[#333] text-xs text-[#a0a0a0]"
            >
              Нет фото
            </div>
          {/if}
        </div>
        <div class="p-2">
          <p
            data-testid="shop-catalog-card-name"
            class="truncate text-sm leading-tight text-white"
          >
            {product.name}
          </p>
          <p
            data-testid="shop-catalog-card-price"
            class="mt-1 font-semibold text-[#ff8c42]"
          >
            {Math.round(product.price)}₽
          </p>
        </div>
      </button>
    {/each}
  </div>
</section>
