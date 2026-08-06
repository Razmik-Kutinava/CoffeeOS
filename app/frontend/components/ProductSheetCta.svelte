<script>
  /** CTA «добавить к заказу» — секция внутри CartSheet (стык, не overlay). */
  let {
    price = 0,
    qty = 1,
    adding = false,
    editMode = false,
    stockOk = true,
    onAdd = null,
    onQtyDelta = null,
    onMore = null
  } = $props()

  function dec() {
    onQtyDelta?.(-1)
  }

  function inc() {
    onQtyDelta?.(1)
  }
</script>

<div
  class="product-sheet-cta"
  data-testid="shop-product-sheet-cta"
>
  <div class="bar-left">
    <div class="price-display">{Math.round(Number(price) || 0)}₽</div>
    <div class="qty-controls">
      <button type="button" class="qty-btn" disabled={!stockOk} onclick={dec}>−</button>
      <span class="qty-value">{qty}</span>
      <button type="button" class="qty-btn" disabled={!stockOk} onclick={inc}>+</button>
    </div>
  </div>
  <button
    type="button"
    class="add-to-cart-btn"
    data-testid="shop-product-add-btn"
    disabled={!stockOk || adding}
    onclick={() => onAdd?.()}
  >
    {#if adding}
      {editMode ? "Сохраняем…" : "Добавляем…"}
    {:else}
      {editMode ? "Сохранить" : "добавить к заказу"}
    {/if}
  </button>
  <button type="button" class="more-btn" onclick={() => onMore?.()}>⋮</button>
</div>

<style>
  .product-sheet-cta {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 12px 8px;
    border-bottom: 1px solid #3a3a3a;
    flex-shrink: 0;
  }

  .bar-left {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }

  .price-display {
    font-size: 18px;
    font-weight: 700;
    color: #ff8c42;
    white-space: nowrap;
  }

  .qty-controls {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .qty-btn {
    width: 28px;
    height: 28px;
    border-radius: 6px;
    background: #3a3a3a;
    border: none;
    color: #fff;
    font-size: 16px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .qty-btn:disabled {
    opacity: 0.4;
    cursor: default;
  }

  .qty-value {
    font-size: 14px;
    color: #fff;
    min-width: 20px;
    text-align: center;
  }

  .add-to-cart-btn {
    flex: 1;
    background: #ff8c42;
    color: #000;
    border: none;
    border-radius: 12px;
    padding: 14px 16px;
    font-size: 15px;
    font-weight: 700;
    cursor: pointer;
    white-space: nowrap;
  }

  .add-to-cart-btn:disabled {
    opacity: 0.4;
    cursor: default;
  }

  .more-btn {
    background: #3a3a3a;
    border: none;
    color: #a0a0a0;
    font-size: 22px;
    cursor: pointer;
    padding: 10px 12px;
    border-radius: 10px;
    line-height: 1;
    flex-shrink: 0;
  }
</style>
