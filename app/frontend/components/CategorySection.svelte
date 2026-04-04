<script>
  import { push } from "svelte-spa-router"

  let { category } = $props()
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
        onclick={() => push(`/product/${product.id}`)}
        class="w-40 shrink-0 overflow-hidden rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] text-left cursor-pointer"
      >
        {#if product.image_url}
          <img
            src={product.image_url}
            alt=""
            class="h-28 w-full object-cover"
            decoding="async"
          />
        {:else}
          <div class="flex h-28 items-center justify-center bg-[#333] text-xs text-[#a0a0a0]">Нет фото</div>
        {/if}
        <div class="p-2">
          <p class="line-clamp-2 text-sm leading-tight text-white">{product.name}</p>
          <p class="mt-1 font-semibold text-[#ff8c42]">{Math.round(product.price)}₽</p>
          {#if product.stock <= 0}
            <p class="text-xs text-red-400">Нет в наличии</p>
          {/if}
        </div>
      </button>
    {/each}
  </div>
</section>
