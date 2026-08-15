<script>
  import { onMount } from "svelte"
  import {
    loadCatalog,
    getCatalogCache,
    startCatalogPolling,
    stopCatalogPolling,
    shouldShowCatalogSkeleton,
    catalogRetryShowsSkeleton
  } from "../lib/stores/catalog.js"
  import { catalogErrorKind } from "../lib/shopNetwork.js"
  import { handleCatalogScroll, refreshCartSheet } from "../lib/cartSheetStore.js"
  import CategorySection from "../components/CategorySection.svelte"
  import PageSkeleton from "../components/PageSkeleton.svelte"

  let categories = $state([])
  let loading = $state(true)
  let err = $state(null)
  let errKind = $state(null)

  async function fetchMenu() {
    const cached = getCatalogCache()
    if (cached?.length && !categories.length) categories = cached
    loading =
      shouldShowCatalogSkeleton(categories) &&
      catalogRetryShowsSkeleton({ visibleCount: categories.length })
    err = null
    errKind = null
    try {
      categories = await loadCatalog()
      startCatalogPolling((cats) => {
        categories = cats
      })
    } catch (e) {
      if (!categories.length) {
        err = e
        errKind = catalogErrorKind(e)
      }
    } finally {
      loading = false
    }
  }

  onMount(() => {
    const onScroll = () => handleCatalogScroll()
    window.addEventListener("scroll", onScroll, { passive: true })
    const onOnline = () => {
      fetchMenu()
    }
    window.addEventListener("online", onOnline)
    try {
      refreshCartSheet().catch(() => {})
    } catch {
      /* storage / sync — не блокировать каталог */
    }

    const cached = getCatalogCache()
    if (cached?.length) {
      categories = cached
      loading = false
    }
    fetchMenu()

    return () => {
      stopCatalogPolling()
      window.removeEventListener("scroll", onScroll)
      window.removeEventListener("online", onOnline)
    }
  })

  function errorTitle(kind) {
    if (kind === "network") return "Нет сети"
    if (kind === "server") return "Ошибка сервера"
    return "Не удалось загрузить меню"
  }

  function errorHint(kind) {
    if (kind === "network") return "Проверьте интернет и нажмите «Повторить»"
    if (kind === "server") return "Попробуйте позже — меню сейчас недоступно"
    return "Проверьте интернет и обновите страницу"
  }
</script>

{#if loading}
  <PageSkeleton />
{:else if err}
  <div class="catalog-error py-8 px-4 text-center">
    <p class="text-[#ff8c42] font-medium mb-2">{errorTitle(errKind)}</p>
    <p class="text-[#a0a0a0] text-sm">{err?.message || ""}</p>
    <p class="text-[#888] text-xs mt-3">{errorHint(errKind)}</p>
    <button
      type="button"
      class="mt-4 rounded-lg bg-[#ff8c42] px-4 py-2 text-sm font-medium text-[#1a1a1a]"
      onclick={fetchMenu}
    >Повторить</button>
  </div>
{:else if categories.length === 0}
  <div class="no-results">
    <p>Пока нет товаров</p>
  </div>
{:else}
  <div class="catalog-with-sheet" style="padding-bottom: var(--cart-sheet-h, 42vh)">
  {#each categories as cat (cat.id)}
    <CategorySection category={cat} />
  {/each}
  </div>
{/if}

<style>
  .no-results {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 60px 20px;
    color: #a0a0a0;
    font-size: 16px;
  }
</style>
