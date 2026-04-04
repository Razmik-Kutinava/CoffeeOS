<script>
  import { onMount } from "svelte"
  import { loadCatalog } from "../lib/stores/catalog.js"
  import CategorySection from "../components/CategorySection.svelte"
  import CatalogFiltersSheet from "../components/CatalogFiltersSheet.svelte"
  import CatalogSortSheet from "../components/CatalogSortSheet.svelte"

  let categories = $state([])
  let loading = $state(true)
  let err = $state(null)

  let searchQuery = $state("")
  let debouncedSearch = $state("")
  let sortBy = $state("")

  let filterSheetOpen = $state(false)
  let sortSheetOpen = $state(false)
  let filterPriceMin = $state(null)
  let filterPriceMax = $state(null)
  let filterParam = $state("all")

  $effect(() => {
    const q = searchQuery
    const t = setTimeout(() => {
      debouncedSearch = q
    }, 160)
    return () => clearTimeout(t)
  })

  onMount(async () => {
    try {
      categories = await loadCatalog()
    } catch (e) {
      err = e.message
    } finally {
      loading = false
    }
  })

  function decafMatch(p) {
    const t = `${p.name} ${p.description || ""}`.toLowerCase()
    return (
      t.includes("без кофеина") ||
      t.includes("декаф") ||
      t.includes("декофеин") ||
      t.includes("decaf")
    )
  }

  let filtersActive = $derived(
    filterPriceMin != null ||
      filterPriceMax != null ||
      (filterParam !== "all" && filterParam !== "")
  )

  let filteredCategories = $derived.by(() => {
    const q = debouncedSearch.trim().toLowerCase()

    let cats = categories

    if (filterParam.startsWith("cat:")) {
      const cid = Number(filterParam.slice(4))
      if (!Number.isNaN(cid)) {
        cats = cats.filter((c) => Number(c.id) === cid)
      }
    }

    cats = cats
      .map((cat) => ({
        ...cat,
        products: cat.products.filter((p) => {
          if (filterParam === "in_stock" && p.stock <= 0) return false
          if (filterParam === "decaf" && !decafMatch(p)) return false

          if (filterPriceMin != null && Number(p.price) < filterPriceMin) return false
          if (filterPriceMax != null && Number(p.price) > filterPriceMax) return false

          if (q) {
            return (
              p.name.toLowerCase().includes(q) ||
              (p.description || "").toLowerCase().includes(q)
            )
          }
          return true
        })
      }))
      .filter((cat) => cat.products.length > 0)

    const sortFn = {
      price_asc: (a, b) => Number(a.price) - Number(b.price),
      price_desc: (a, b) => Number(b.price) - Number(a.price),
      newest: (a, b) => Number(b.id) - Number(a.id),
      name_asc: (a, b) => a.name.localeCompare(b.name, "ru"),
      name_desc: (a, b) => b.name.localeCompare(a.name, "ru")
    }[sortBy]

    if (sortFn) {
      cats = cats.map((c) => ({
        ...c,
        products: [...c.products].sort(sortFn)
      }))
    }

    return cats
  })

  function resetAllFilters() {
    searchQuery = ""
    debouncedSearch = ""
    sortBy = ""
    filterPriceMin = null
    filterPriceMax = null
    filterParam = "all"
  }
</script>

<div class="catalog-toolbar">
  <div class="search-row">
    <input
      type="search"
      placeholder="🔍 Найти..."
      bind:value={searchQuery}
      class="search-input"
    />
    <button
      type="button"
      class="tool-btn"
      class:active={sortBy !== ""}
      onclick={() => (sortSheetOpen = true)}
      aria-label="Сортировка"
    >
      ⇅
    </button>
    <button
      type="button"
      class="tool-btn"
      class:active={filtersActive}
      onclick={() => (filterSheetOpen = true)}
      aria-label="Фильтры"
    >
      ☰
    </button>
  </div>
</div>

<CatalogFiltersSheet
  bind:open={filterSheetOpen}
  {categories}
  bind:priceMin={filterPriceMin}
  bind:priceMax={filterPriceMax}
  bind:paramKey={filterParam}
/>

<CatalogSortSheet bind:open={sortSheetOpen} bind:sortBy />

{#if loading}
  <p class="text-center text-[#a0a0a0] py-8">Загрузка…</p>
{:else if err}
  <p class="text-center text-red-400 py-8">{err}</p>
{:else if filteredCategories.length === 0}
  <div class="no-results">
    <p>Ничего не найдено</p>
    {#if searchQuery || filtersActive || sortBy}
      <button type="button" onclick={resetAllFilters}>Сбросить</button>
    {/if}
  </div>
{:else}
  {#each filteredCategories as cat (cat.id)}
    <CategorySection category={cat} />
  {/each}
{/if}

<style>
  .catalog-toolbar {
    margin-bottom: 8px;
  }

  .search-row {
    display: flex;
    gap: 8px;
    margin-bottom: 0;
  }

  .search-input {
    flex: 1;
    background: #2a2a2a;
    border: 1px solid #3a3a3a;
    border-radius: 10px;
    padding: 10px 14px;
    color: #fff;
    font-size: 14px;
    outline: none;
    min-width: 0;
  }

  .search-input:focus {
    border-color: #ff8c42;
  }

  .search-input::placeholder {
    color: #666;
  }

  .tool-btn {
    background: #2a2a2a;
    border: 1px solid #3a3a3a;
    border-radius: 10px;
    padding: 10px 14px;
    color: #a0a0a0;
    font-size: 16px;
    cursor: pointer;
    flex-shrink: 0;
    transition: all 0.15s;
  }

  .tool-btn.active {
    border-color: #ff8c42;
    color: #ff8c42;
  }

  .no-results {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    padding: 60px 20px;
    color: #a0a0a0;
    font-size: 16px;
  }

  .no-results button {
    background: #3a3a3a;
    border: none;
    border-radius: 10px;
    padding: 10px 20px;
    color: #fff;
    font-size: 14px;
    cursor: pointer;
  }
</style>
