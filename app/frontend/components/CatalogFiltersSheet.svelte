<script>
  let {
    open = $bindable(false),
    categories = [],
    priceMin = $bindable(null),
    priceMax = $bindable(null),
    paramKey = $bindable("all")
  } = $props()

  let draftMin = $state("")
  let draftMax = $state("")
  let draftParam = $state("all")

  $effect(() => {
    if (open) {
      draftMin = priceMin != null ? String(priceMin) : ""
      draftMax = priceMax != null ? String(priceMax) : ""
      draftParam = paramKey
    }
  })

  function close() {
    open = false
  }

  function apply() {
    const mn = draftMin.trim() === "" ? null : Number(draftMin.replace(",", "."))
    const mx = draftMax.trim() === "" ? null : Number(draftMax.replace(",", "."))
    priceMin = mn != null && !Number.isNaN(mn) ? mn : null
    priceMax = mx != null && !Number.isNaN(mx) ? mx : null
    paramKey = draftParam
    open = false
  }

  function reset() {
    draftMin = ""
    draftMax = ""
    draftParam = "all"
    priceMin = null
    priceMax = null
    paramKey = "all"
    open = false
  }
</script>

<svelte:window onkeydown={(e) => open && e.key === "Escape" && close()} />

{#if open}
  <div class="sheet-backdrop" onclick={close} role="presentation" aria-hidden="true"></div>
  <div class="sheet sheet-filters" role="dialog" aria-modal="true" aria-labelledby="filters-title">
    <div class="sheet-handle" aria-hidden="true"></div>
    <h2 id="filters-title" class="sheet-title">Фильтры</h2>
    <div class="title-rule"></div>

    <p class="field-label">Цена</p>
    <div class="price-row">
      <label class="price-field">
        <span class="visually-hidden">От</span>
        <input type="text" inputmode="decimal" placeholder="От" bind:value={draftMin} class="price-input" />
        <span class="currency">₽</span>
      </label>
      <label class="price-field">
        <span class="visually-hidden">До</span>
        <input type="text" inputmode="decimal" placeholder="До" bind:value={draftMax} class="price-input" />
        <span class="currency">₽</span>
      </label>
    </div>

    <label class="param-label" for="param-select">Параметр</label>
    <div class="param-wrap">
      <select id="param-select" bind:value={draftParam} class="param-select">
        <option value="all">Все товары</option>
        <option value="in_stock">Только в наличии</option>
        <option value="decaf">Без кофеина</option>
        {#each categories as c (c.id)}
          <option value={"cat:" + c.id}>{c.name}</option>
        {/each}
      </select>
      <span class="param-chevron" aria-hidden="true">▾</span>
    </div>

    <div class="sheet-actions">
      <button type="button" class="btn-secondary" onclick={reset}>Сбросить</button>
      <button type="button" class="btn-primary" onclick={apply}>Применить</button>
    </div>
  </div>
{/if}

<style>
  .visually-hidden {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }

  .sheet-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.65);
    z-index: 80;
    animation: fade-in 0.2s ease;
  }

  @keyframes fade-in {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  .sheet {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 90;
    max-height: min(88vh, 640px);
    background: #141414;
    border-radius: 20px 20px 0 0;
    padding: 8px 20px 24px;
    padding-bottom: calc(24px + env(safe-area-inset-bottom, 0px));
    box-sizing: border-box;
    overflow-y: auto;
    animation: slide-up 0.25s ease;
    box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.45);
  }

  @keyframes slide-up {
    from {
      transform: translateY(100%);
    }
    to {
      transform: translateY(0);
    }
  }

  .sheet-handle {
    width: 36px;
    height: 4px;
    border-radius: 2px;
    background: #444;
    margin: 4px auto 12px;
  }

  .sheet-title {
    margin: 0 0 10px;
    font-size: 18px;
    font-weight: 700;
    color: #fff;
  }

  .title-rule {
    height: 0;
    border: none;
    border-top: 1px dashed #444;
    margin: 0 0 20px;
  }

  .field-label,
  .param-label {
    margin: 0 0 8px;
    font-size: 13px;
    color: #a0a0a0;
  }

  .param-label {
    margin-top: 20px;
  }

  .price-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
  }

  .price-field {
    position: relative;
    display: block;
  }

  .price-input {
    width: 100%;
    box-sizing: border-box;
    background: #2a2a2a;
    border: 1px solid #3a3a3a;
    border-radius: 10px;
    padding: 12px 32px 12px 12px;
    color: #fff;
    font-size: 15px;
    outline: none;
  }

  .price-input:focus {
    border-color: #ff8c42;
  }

  .price-input::placeholder {
    color: #666;
  }

  .currency {
    position: absolute;
    right: 12px;
    top: 50%;
    transform: translateY(-50%);
    color: #888;
    font-size: 14px;
    pointer-events: none;
  }

  .param-wrap {
    position: relative;
  }

  .param-select {
    width: 100%;
    box-sizing: border-box;
    appearance: none;
    background: #3a3228;
    border: 1px solid #4a4035;
    border-radius: 10px;
    padding: 14px 40px 14px 14px;
    color: #c4b8a8;
    font-size: 15px;
    cursor: pointer;
    outline: none;
  }

  .param-select:focus {
    border-color: #ff8c42;
  }

  .param-chevron {
    position: absolute;
    right: 14px;
    top: 50%;
    transform: translateY(-50%);
    color: #888;
    font-size: 12px;
    pointer-events: none;
  }

  .sheet-actions {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    margin-top: 28px;
  }

  .btn-primary {
    background: #8b7355;
    border: none;
    border-radius: 12px;
    padding: 14px 16px;
    color: #fff;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
  }

  .btn-primary:active {
    filter: brightness(1.08);
  }

  .btn-secondary {
    background: #2a2a2a;
    border: 1px solid #3a3a3a;
    border-radius: 12px;
    padding: 14px 16px;
    color: #a0a0a0;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
  }
</style>
