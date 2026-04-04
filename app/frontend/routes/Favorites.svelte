<script>
  import { onMount } from 'svelte'
  import { push } from 'svelte-spa-router'
  import { favorites } from '../lib/stores/favorites.js'
  import { api } from '../lib/api.js'
  import { useTelegramBack } from '../lib/telegram.js'

  useTelegramBack(() => push('/'))

  let selectedProduct = $state(null)
  let showModal = $state(false)
  let addingToCart = $state(false)

  onMount(async () => {
    await favorites.load()
  })

  function handleProductClick(product) {
    selectedProduct = product
    showModal = true
  }

  async function addToCartDirect() {
    if (!selectedProduct || addingToCart) return
    addingToCart = true
    try {
      await api('cart/add', {
        method: 'POST',
        body: JSON.stringify({
          product_id: selectedProduct.id,
          quantity: 1,
          selected_modifiers: []
        })
      })
      showModal = false
      push('/cart')
    } finally {
      addingToCart = false
    }
  }

  function goToProduct() {
    const id = selectedProduct.id
    showModal = false
    push(`/product/${id}`)
  }
</script>

<!-- Модалка -->
{#if showModal && selectedProduct}
  <div class="modal-overlay" onclick={() => showModal = false}>
    <div class="modal" onclick={(e) => e.stopPropagation()}>
      <div class="modal-product">
        {#if selectedProduct.image_url}
          <img src={selectedProduct.image_url} alt={selectedProduct.name} class="modal-img" decoding="async" />
        {/if}
        <div>
          <p class="modal-name">{selectedProduct.name}</p>
          <p class="modal-price">{selectedProduct.price} ₽</p>
        </div>
      </div>
      <p class="modal-question">Как добавить в корзину?</p>
      <div class="modal-actions">
        <button class="btn-primary" onclick={addToCartDirect} disabled={addingToCart}>
          {addingToCart ? 'Добавляю...' : '🛒 Сразу в корзину'}
        </button>
        <button class="btn-secondary" onclick={goToProduct}>
          ✏️ Выбрать модификаторы
        </button>
      </div>
      <button class="modal-close" onclick={() => showModal = false}>Отмена</button>
    </div>
  </div>
{/if}

<div class="favorites-page">
  <div class="page-header">
    <button class="back-btn" onclick={() => push('/')}>‹</button>
    <h1>Избранное</h1>
  </div>

  {#if $favorites.length === 0}
    <div class="empty-state">
      <div class="empty-icon">♡</div>
      <p>Избранных товаров пока нет</p>
      <button class="go-catalog" onclick={() => push('/')}>В каталог</button>
    </div>
  {:else}
    <div class="products-grid">
      {#each $favorites as product (product.id)}
        <article class="product-card">
          <button
            type="button"
            class="card-nav"
            onclick={() => handleProductClick(product)}
          >
            <span class="card-nav-inner">
              <span class="card-image-wrap">
                {#if product.image_url}
                  <img src={product.image_url} alt={product.name} class="product-img" decoding="async" />
                {:else}
                  <span class="product-img-placeholder">☕</span>
                {/if}
              </span>
              <span class="card-info">
                <span class="product-name">{product.name}</span>
                <span class="price-row">
                  <span class="product-price">{Math.round(Number(product.price))} ₽</span>
                </span>
              </span>
            </span>
          </button>
          <div class="card-toolbar">
            <button
              type="button"
              class="unfavorite-btn"
              onclick={() => favorites.toggle(product.id)}
              title="Убрать из избранного"
              aria-label="Убрать из избранного"
            >
              ♥
            </button>
          </div>
        </article>
      {/each}
    </div>
  {/if}
</div>

<style>
  .modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.7);
    z-index: 200;
    display: flex;
    align-items: flex-end;
    justify-content: center;
  }

  .modal {
    background: #2a2a2a;
    border-radius: 20px 20px 0 0;
    padding: 24px 20px 36px;
    width: 100%;
    max-width: 480px;
  }

  .modal-product {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 16px;
  }

  .modal-img {
    width: 56px;
    height: 56px;
    border-radius: 8px;
    object-fit: cover;
  }

  .modal-name {
    font-size: 16px;
    font-weight: 600;
    color: #fff;
  }

  .modal-price {
    font-size: 14px;
    color: #ff8c42;
    margin-top: 2px;
  }

  .modal-question {
    font-size: 14px;
    color: #a0a0a0;
    margin-bottom: 16px;
  }

  .modal-actions {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin-bottom: 12px;
  }

  .btn-primary {
    background: #ff8c42;
    color: #000;
    border: none;
    border-radius: 12px;
    padding: 14px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    width: 100%;
  }

  .btn-primary:disabled {
    opacity: 0.6;
  }

  .btn-secondary {
    background: #3a3a3a;
    color: #fff;
    border: none;
    border-radius: 12px;
    padding: 14px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    width: 100%;
  }

  .modal-close {
    background: none;
    border: none;
    color: #a0a0a0;
    font-size: 14px;
    cursor: pointer;
    width: 100%;
    padding: 8px;
  }

  .favorites-page {
    min-height: 100vh;
    background: var(--bg-primary, #1a1a1a);
    padding-bottom: 80px;
  }

  .page-header {
    display: flex;
    align-items: center;
    padding: 16px 20px;
    background: var(--bg-secondary, #2a2a2a);
    gap: 12px;
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .back-btn {
    background: none;
    border: none;
    color: var(--accent, #ff8c42);
    font-size: 28px;
    cursor: pointer;
    padding: 0;
    line-height: 1;
  }

  h1 {
    font-size: 20px;
    font-weight: 700;
    color: var(--text-primary, #fff);
    margin: 0;
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 80px 20px;
    gap: 16px;
  }

  .empty-icon {
    font-size: 48px;
    color: var(--text-secondary, #a0a0a0);
  }

  .empty-state p {
    color: var(--text-secondary, #a0a0a0);
    font-size: 16px;
  }

  .go-catalog {
    background: var(--accent, #ff8c42);
    color: white;
    border: none;
    border-radius: 12px;
    padding: 12px 32px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
  }

  .products-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
    padding: 12px;
    align-items: stretch;
  }

  .product-card {
    display: flex;
    flex-direction: column;
    width: 100%;
    min-width: 0;
    min-height: 0;
    height: 100%;
    background: var(--bg-secondary, #2a2a2a);
    border-radius: 12px;
    overflow: hidden;
    border: 1px solid #333;
  }

  .card-nav {
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    min-height: 0;
    width: 100%;
    padding: 0;
    margin: 0;
    background: none;
    border: none;
    cursor: pointer;
    text-align: left;
    font: inherit;
    color: inherit;
    -webkit-tap-highlight-color: transparent;
  }

  .card-nav-inner {
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    align-items: stretch;
    min-height: 0;
    width: 100%;
  }

  .card-image-wrap {
    display: block;
    flex-shrink: 0;
    width: 100%;
    aspect-ratio: 5 / 6;
    background: #1f1f1f;
    overflow: hidden;
  }

  .product-img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  .product-img-placeholder {
    display: flex;
    width: 100%;
    height: 100%;
    box-sizing: border-box;
    background: #3a3a3a;
    align-items: center;
    justify-content: center;
    font-size: clamp(22px, 12vw, 32px);
  }

  .card-info {
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    align-items: stretch;
    justify-content: flex-start;
    gap: 3px;
    padding: 6px 6px 4px;
    min-width: 0;
    min-height: 0;
    box-sizing: border-box;
  }

  .price-row {
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;
    align-items: center;
    gap: 6px;
    margin-top: auto;
    padding-top: 2px;
  }

  .product-name {
    font-size: 11px;
    font-weight: 600;
    color: var(--text-primary, #fff);
    line-height: 1.2;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    min-height: calc(1.2em * 2);
  }

  .product-price {
    font-size: 12px;
    font-weight: 700;
    color: var(--accent, #ff8c42);
  }

  .card-toolbar {
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    align-items: center;
    flex-shrink: 0;
    padding: 6px;
    border-top: 1px solid #333;
    background: rgba(0, 0, 0, 0.15);
  }

  .unfavorite-btn {
    background: #333;
    border: 1px solid #3a3a3a;
    color: var(--accent, #ff8c42);
    font-size: 16px;
    cursor: pointer;
    width: 34px;
    height: 34px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0;
  }

  .unfavorite-btn:active {
    background: #444;
  }
</style>
