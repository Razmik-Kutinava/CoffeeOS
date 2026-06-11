<script>
  import { onMount } from "svelte"
  import { loadCatalog, getCatalogCache, startCatalogPolling, stopCatalogPolling } from "../lib/stores/catalog.js"
  import CategorySection from "../components/CategorySection.svelte"
  import PageSkeleton from "../components/PageSkeleton.svelte"

  let categories = $state([])
  let loading = $state(true)
  let err = $state(null)

  onMount(async () => {
    try {
      categories = await loadCatalog()
      startCatalogPolling((cats) => {
        categories = cats
      })
    } catch (e) {
      err = e.message
    } finally {
      loading = false
    }
    return () => stopCatalogPolling()
  })
</script>

{#if loading}
  <PageSkeleton />
{:else if err}
  <div class="catalog-error py-8 px-4 text-center">
    <p class="text-[#ff8c42] font-medium mb-2">Не удалось загрузить меню</p>
    <p class="text-[#a0a0a0] text-sm">{err}</p>
    {#if getCatalogCache()?.length}
      <p class="text-[#888] text-xs mt-3">Откройте каталог снова — покажем последнее сохранённое меню</p>
    {:else}
      <p class="text-[#888] text-xs mt-3">Проверьте интернет и обновите страницу</p>
    {/if}
  </div>
{:else if categories.length === 0}
  <div class="no-results">
    <p>Пока нет товаров</p>
  </div>
{:else}
  {#each categories as cat (cat.id)}
    <CategorySection category={cat} />
  {/each}
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
