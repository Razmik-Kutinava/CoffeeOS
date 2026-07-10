<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import {
    cartItems,
    cartSheetBusy,
    cartSheetError,
    clearCartSheetError,
    bumpCartLine,
    removeCartLine,
    atMinQty,
    atMaxQty
  } from "../lib/cartSheetStore.js"

  let { outOfStockProductId = null } = $props()

  let items = $state([])
  let busy = $state(false)
  let sheetError = $state(null)

  onMount(() => {
    const unsubItems = cartItems.subscribe((v) => {
      items = v || []
    })
    const unsubBusy = cartSheetBusy.subscribe((v) => {
      busy = v
    })
    const unsubErr = cartSheetError.subscribe((v) => {
      sheetError = v
    })
    return () => {
      unsubItems()
      unsubBusy()
      unsubErr()
    }
  })

  function roundPrice(n) {
    return Math.round(Number(n) || 0)
  }

  function lineUnavailable(line) {
    if (outOfStockProductId == null || outOfStockProductId === "") return false
    return String(line?.product_id) === String(outOfStockProductId)
  }

  function openLine(line, e) {
    if (e?.target?.closest?.("button")) return
    if (!line?.product_id && line?.product_id !== 0) return
    push(`/product/${line.product_id}?cart_line=${line.index}`)
  }

  function decrementLine(line) {
    if (lineUnavailable(line)) return
    if (atMinQty(line)) {
      removeCartLine(line.index)
    } else {
      bumpCartLine(line.index, -1)
    }
  }
</script>

{#if items.length}
  <div
    class="product-cart-peek"
    data-testid="shop-product-peek-list"
  >
    <p class="peek-title">уже в заказе</p>

    {#if sheetError}
      <div
        data-testid="shop-product-peek-error"
        role="status"
        class="peek-error"
      >
        <span>{sheetError}</span>
        <button type="button" class="peek-error-dismiss" onclick={() => clearCartSheetError()}>
          закрыть
        </button>
      </div>
    {/if}

    <div
      class="peek-row"
      data-testid="shop-product-peek-scroll"
    >
      {#each items as line (line.index)}
        {@const unavailable = lineUnavailable(line)}
        <div
          class="peek-line"
          class:peek-line--unavailable={unavailable}
          data-testid="shop-product-peek-line"
          role="button"
          tabindex="0"
          onclick={(e) => openLine(line, e)}
          onkeydown={(e) => e.key === "Enter" && openLine(line, e)}
        >
          {#if line.image_url}
            <img src={line.image_url} alt="" class="peek-thumb" decoding="async" />
          {:else}
            <div class="peek-thumb peek-thumb--empty">нет</div>
          {/if}
          <p class="peek-name">{line.product_name}</p>
          {#if unavailable}
            <p data-testid="shop-product-peek-out-of-stock" class="peek-oos">нет в наличии</p>
          {:else}
            <p class="peek-meta">{roundPrice(line.unit_total)}₽ × {line.quantity}</p>
          {/if}
          <div class="peek-qty">
            <button
              type="button"
              data-testid="shop-product-peek-minus"
              class="peek-qty-btn"
              disabled={busy || unavailable}
              onclick={(e) => {
                e.stopPropagation()
                decrementLine(line)
              }}
            >−</button>
            <span class="peek-qty-val">{line.quantity}</span>
            <button
              type="button"
              data-testid="shop-product-peek-plus"
              class="peek-qty-btn"
              disabled={busy || unavailable || atMaxQty(line)}
              onclick={(e) => {
                e.stopPropagation()
                bumpCartLine(line.index, 1)
              }}
            >+</button>
          </div>
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

  .peek-error {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    margin-bottom: 6px;
    padding: 6px 8px;
    border-radius: 8px;
    border: 1px solid #3a3a3a;
    background: #1f1f1f;
    font-size: 11px;
    color: #ff8c42;
  }

  .peek-error-dismiss {
    border: none;
    background: transparent;
    color: #a0a0a0;
    font-size: 10px;
    cursor: pointer;
    flex-shrink: 0;
  }

  .peek-row {
    display: flex;
    gap: 8px;
    overflow-x: auto;
    -ms-overflow-style: none;
    scrollbar-width: none;
    touch-action: pan-x;
    overscroll-behavior-x: contain;
    -webkit-overflow-scrolling: touch;
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

  .peek-line--unavailable {
    opacity: 0.75;
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

  .peek-oos {
    margin: 2px 0 0;
    font-size: 10px;
    color: #ff8c42;
    font-weight: 600;
  }

  .peek-qty {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 2px;
    margin-top: 4px;
  }

  .peek-qty-btn {
    border: none;
    border-radius: 4px;
    background: #3a3a3a;
    color: #fff;
    font-size: 10px;
    line-height: 1;
    padding: 2px 6px;
    cursor: pointer;
  }

  .peek-qty-btn:disabled {
    opacity: 0.4;
    cursor: default;
  }

  .peek-qty-val {
    font-size: 10px;
    color: #fff;
    min-width: 1rem;
    text-align: center;
  }
</style>
