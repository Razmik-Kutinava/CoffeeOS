<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { cartItems } from "../lib/cartSheetStore.js"

  let items = $state([])

  onMount(() => {
    const unsub = cartItems.subscribe((v) => {
      items = v || []
    })
    return () => unsub()
  })

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }

  function openLine(line) {
    if (!line?.product_id && line?.product_id !== 0) return
    push(`/product/${line.product_id}?cart_line=${line.index}`)
  }
</script>

{#if items.length}
  <div
    class="product-cart-peek"
    data-testid="shop-product-peek-list"
  >
    <p class="peek-title">уже в заказе</p>
    <div class="peek-row">
      {#each items as line (line.index)}
        <div
          class="peek-line"
          data-testid="shop-product-peek-line"
          role="button"
          tabindex="0"
          onclick={() => openLine(line)}
          onkeydown={(e) => e.key === "Enter" && openLine(line)}
        >
          {#if line.image_url}
            <img src={line.image_url} alt="" class="peek-thumb" decoding="async" />
          {:else}
            <div class="peek-thumb peek-thumb--empty">нет</div>
          {/if}
          <p class="peek-name">{line.product_name}</p>
          <p class="peek-meta">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
        </div>
      {/each}
    </div>
  </div>
{/if}

<style>
  .product-cart-peek {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 45;
    margin: 0 auto;
    max-width: 480px;
    border-top: 1px solid #3a3a3a;
    background: #2a2a2a;
    padding: 8px 12px 10px;
  }

  .peek-title {
    margin: 0 0 6px;
    font-size: 12px;
    font-weight: 600;
    color: #a0a0a0;
  }

  .peek-row {
    display: flex;
    gap: 8px;
    overflow-x: auto;
    -ms-overflow-style: none;
    scrollbar-width: none;
  }

  .peek-row::-webkit-scrollbar {
    display: none;
  }

  .peek-line {
    flex: 0 0 auto;
    width: min(28vw, 110px);
    cursor: pointer;
    border-radius: 12px;
    border: 1px solid #3a3a3a;
    background: #1f1f1f;
    padding: 6px;
  }

  .peek-thumb {
    display: block;
    width: 100%;
    height: 64px;
    border-radius: 8px;
    object-fit: cover;
  }

  .peek-thumb--empty {
    display: flex;
    align-items: center;
    justify-content: center;
    background: #333;
    color: #888;
    font-size: 10px;
  }

  .peek-name {
    margin: 4px 0 0;
    font-size: 11px;
    font-weight: 500;
    line-height: 1.2;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .peek-meta {
    margin: 2px 0 0;
    font-size: 10px;
    color: #a0a0a0;
  }
</style>
