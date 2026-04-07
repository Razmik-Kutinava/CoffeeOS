<script>
  import { onMount } from "svelte"
  import { loadCatalog } from "../lib/stores/catalog.js"
  import CategorySection from "../components/CategorySection.svelte"

  let categories = $state([])
  let loading = $state(true)
  let err = $state(null)

  onMount(async () => {
    try {
      categories = await loadCatalog()
    } catch (e) {
      err = e.message
    } finally {
      loading = false
    }
  })
</script>

{#if loading}
  <p class="text-center text-[#a0a0a0] py-8">Загрузка…</p>
{:else if err}
  <p class="text-center text-red-400 py-8">{err}</p>
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
