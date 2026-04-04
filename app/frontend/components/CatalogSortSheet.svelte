<script>
  const OPTIONS = [
    { value: "", label: "По умолчанию" },
    { value: "price_asc", label: "Сначала подешевле" },
    { value: "price_desc", label: "Сначала подороже" },
    { value: "newest", label: "Сначала новинки" },
    { value: "name_asc", label: "По алфавиту А — Я" },
    { value: "name_desc", label: "По алфавиту Я — А" }
  ]

  let { open = $bindable(false), sortBy = $bindable("") } = $props()

  let draft = $state("")

  $effect(() => {
    if (open) {
      draft = sortBy
    }
  })

  function close() {
    open = false
  }

  function apply() {
    sortBy = draft
    open = false
  }
</script>

<svelte:window onkeydown={(e) => open && e.key === "Escape" && close()} />

{#if open}
  <div class="sheet-backdrop" onclick={close} role="presentation" aria-hidden="true"></div>
  <div class="sheet" role="dialog" aria-modal="true" aria-labelledby="sort-title">
    <div class="sheet-handle" aria-hidden="true"></div>
    <h2 id="sort-title" class="sheet-title">Сортировка</h2>

    <div class="options-card" role="radiogroup" aria-label="Варианты сортировки">
      {#each OPTIONS as opt, i (opt.value)}
        <label class="option-row" class:is-first={i === 0}>
          <input type="radio" name="catalog-sort" value={opt.value} bind:group={draft} class="radio-input" />
          <span class="radio-ui" aria-hidden="true"></span>
          <span class="option-label">{opt.label}</span>
        </label>
      {/each}
    </div>

    <button type="button" class="btn-apply" onclick={apply}>
      Применить
    </button>
  </div>
{/if}

<style>
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
    max-height: min(85vh, 520px);
    background: #1a1a1a;
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
    background: #555;
    margin: 4px auto 16px;
  }

  .sheet-title {
    margin: 0 0 16px;
    font-size: 18px;
    font-weight: 700;
    color: #fff;
  }

  .options-card {
    background: #2a2a2a;
    border-radius: 12px;
    border: 1px solid #333;
    overflow: hidden;
  }

  .option-row {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    cursor: pointer;
    border-top: 1px solid #1f1f1f;
    margin: 0;
  }

  .option-row.is-first {
    border-top: none;
  }

  .radio-input {
    position: absolute;
    opacity: 0;
    width: 0;
    height: 0;
  }

  .radio-ui {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    border: 2px solid #666;
    flex-shrink: 0;
    box-sizing: border-box;
  }

  .radio-input:checked + .radio-ui {
    border-color: #ff8c42;
    background: radial-gradient(circle, #ff8c42 40%, transparent 45%);
  }

  .option-label {
    font-size: 15px;
    color: #eee;
    line-height: 1.3;
  }

  .btn-apply {
    width: 100%;
    margin-top: 20px;
    background: #8b7355;
    border: none;
    border-radius: 12px;
    padding: 16px;
    color: #fff;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
  }

  .btn-apply:active {
    filter: brightness(1.08);
  }
</style>
