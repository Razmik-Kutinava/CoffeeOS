<script>
  import { onMount } from "svelte"
  import { installSlowRequestTracker, onSlowRequestChange } from "../lib/slowRequest.js"

  let visible = $state(false)

  onMount(() => {
    installSlowRequestTracker()
    return onSlowRequestChange((next) => {
      visible = next
    })
  })
</script>

{#if visible}
  <div
    class="slow-request-shop-overlay"
    aria-busy="true"
    aria-live="polite"
    aria-label="Загрузка данных"
  >
    <div class="slow-request-shop-panel">
      <div class="slow-request-shop-line wide"></div>
      <div class="slow-request-shop-line"></div>
      <div class="slow-request-shop-cards">
        <div class="slow-request-shop-card"></div>
        <div class="slow-request-shop-card"></div>
        <div class="slow-request-shop-card"></div>
      </div>
      <p class="slow-request-shop-message">Загрузка данных… Пожалуйста, подождите.</p>
    </div>
  </div>
{/if}

<style>
  .slow-request-shop-overlay {
    position: fixed;
    inset: 0;
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1.5rem;
    background: rgba(0, 0, 0, 0.72);
    backdrop-filter: blur(2px);
  }

  .slow-request-shop-panel {
    width: min(420px, 100%);
    padding: 1.25rem;
    border-radius: 16px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    background: rgba(26, 26, 26, 0.96);
  }

  .slow-request-shop-message {
    margin: 1rem 0 0;
    text-align: center;
    color: #c7c7c7;
    font-size: 0.95rem;
  }

  .slow-request-shop-line {
    height: 0.85rem;
    width: 55%;
    border-radius: 999px;
    margin-bottom: 0.75rem;
    background: linear-gradient(90deg, #2a2a2a 25%, #3a3a3a 50%, #2a2a2a 75%);
    background-size: 200% 100%;
    animation: shop-pulse 1.4s ease-in-out infinite;
  }

  .slow-request-shop-line.wide {
    width: 75%;
  }

  .slow-request-shop-cards {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 0.75rem;
  }

  .slow-request-shop-card {
    height: 4.5rem;
    border-radius: 12px;
    background: linear-gradient(90deg, #222 25%, #333 50%, #222 75%);
    background-size: 200% 100%;
    animation: shop-pulse 1.4s ease-in-out infinite;
  }

  @keyframes shop-pulse {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }
</style>
