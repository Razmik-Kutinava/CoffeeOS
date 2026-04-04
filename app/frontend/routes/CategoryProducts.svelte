<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { loadCatalog } from "../lib/stores/catalog.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import { favorites } from "../lib/stores/favorites.js"

  let { params } = $props()

  let category = $state(null)
  let products = $state([])
  let loading = $state(true)
  let error = $state(null)
  let addingId = $state(null)

  useTelegramBack(() => push('/'))

  onMount(async () => {
    try {
      const categories = await loadCatalog()
      category = categories.find(c => c.id == params.id)
      if (category) {
        products = category.products
      } else {
        error = "Категория не найдена"
      }
      await favorites.load()
    } catch (e) {
      error = e.message
    } finally {
      loading = false
    }
  })

  async function quickAddToCart(product) {
    if (addingId) return
    addingId = product.id
    try {
      await api("/cart/add", {
        method: "POST",
        body: JSON.stringify({
          product_id: product.id,
          quantity: 1,
          selected_modifiers: []
        })
      })
      push("/cart")
    } finally {
      addingId = null
    }
  }

  async function toggleFav(e, productId) {
    e.stopPropagation()
    await favorites.toggle(productId)
  }
</script>

<div class="category-page">
  <div class="page-header">
    <button class="back-btn" onclick={() => push('/')}>‹</button>
    <h1>{category?.name || 'Категория'}</h1>
  </div>

  {#if loading}
    <div class="loading">Загрузка...</div>
  {:else if error}
    <div class="error">{error}</div>
  {:else if products.length === 0}
    <div class="empty">Товаров нет</div>
  {:else}
    <div class="products-list">
      {#each products as product (product.id)}
        <article class="product-card">
          <button
            type="button"
            class="card-nav"
            onclick={() => push(`/product/${product.id}`)}
          >
            <span class="card-nav-inner">
              <span class="card-image-wrap">
                {#if product.image_url}
                  <img
                    src={product.image_url}
                    alt={product.name}
                    class="product-img"
                    decoding="async"
                  />
                {:else}
                  <span class="product-img-placeholder">☕</span>
                {/if}
              </span>
              <span class="card-info">
                <span class="product-name">{product.name}</span>
                {#if product.description}
                  <span class="product-desc">{product.description}</span>
                {/if}
                <span class="price-row">
                  <span class="product-price">{Math.round(product.price)} ₽</span>
                  {#if product.stock <= 0}
                    <span class="out-of-stock">Нет в наличии</span>
                  {/if}
                </span>
              </span>
            </span>
          </button>
          <div class="card-toolbar">
            <button
              type="button"
              class="action-btn fav-btn"
              class:is-fav={favorites.isFavorite(product.id)}
              onclick={(e) => toggleFav(e, product.id)}
              aria-label="Избранное"
            >
              {favorites.isFavorite(product.id) ? "♥" : "♡"}
            </button>
            <button
              type="button"
              class="action-btn cart-btn"
              disabled={product.stock <= 0 || addingId === product.id}
              onclick={(e) => {
                e.stopPropagation()
                quickAddToCart(product)
              }}
              aria-label="В корзину"
            >
              {addingId === product.id ? "..." : "🛒"}
            </button>
          </div>
        </article>
      {/each}
    </div>
  {/if}
</div>

<style>
  .category-page {
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

  h1 { font-size: 20px; font-weight: 700; color: #fff; margin: 0; }
  .loading, .error, .empty { text-align: center; padding: 60px 20px; color: #a0a0a0; }

  .products-list {
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
    color: #fff;
    line-height: 1.2;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    min-height: calc(1.2em * 2);
  }

  /* В сетке 2×N описание даёт разный перенос — только карточка товара */
  .product-desc {
    display: none;
  }

  .product-price {
    font-size: 12px;
    font-weight: 700;
    color: #ff8c42;
  }

  .out-of-stock { font-size: 9px; color: #f44336; }

  .card-toolbar {
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
    padding: 6px;
    border-top: 1px solid #333;
    background: rgba(0, 0, 0, 0.15);
  }

  .action-btn {
    width: 34px;
    height: 34px;
    border-radius: 8px;
    border: 1px solid #3a3a3a;
    background: #333;
    color: #a0a0a0;
    font-size: 15px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.15s;
  }

  .action-btn:active { background: #444; }
  .action-btn:disabled { opacity: 0.4; cursor: default; }

  .fav-btn.is-fav {
    color: #ff8c42;
    border-color: #ff8c42;
  }

  .cart-btn {
    background: #ff8c42;
    border-color: #ff8c42;
    color: #000;
  }
</style>
