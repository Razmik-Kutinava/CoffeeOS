<script>
  import { THREE_DS_FRAME_NAME } from "../lib/tbankCardEncrypt.js"

  let { open = false, onClose = () => {} } = $props()
</script>

{#if open}
  <div class="three-ds-overlay" data-testid="three-ds-overlay" role="dialog" aria-label="3-D Secure">
    <header class="three-ds-overlay__bar">
      <span>3-D Secure</span>
      <button
        type="button"
        class="three-ds-overlay__close"
        aria-label="Закрыть"
        data-testid="three-ds-close"
        onclick={onClose}
      >
        ×
      </button>
    </header>
    <iframe
      title="3-D Secure"
      name={THREE_DS_FRAME_NAME}
      class="three-ds-overlay__frame"
      data-testid="three-ds-frame"
    ></iframe>
  </div>
{/if}

<style>
  .three-ds-overlay {
    position: fixed;
    inset: 0;
    z-index: 60;
    display: flex;
    flex-direction: column;
    background: #0f0f0f;
  }

  .three-ds-overlay__bar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.75rem 1rem;
    background: #1a1a1a;
    border-bottom: 1px solid #3a3a3a;
    color: #fff;
    font-weight: 600;
  }

  .three-ds-overlay__close {
    border: 0;
    background: #2a2a2a;
    color: #fff;
    width: 2rem;
    height: 2rem;
    border-radius: 999px;
    font-size: 1.25rem;
    line-height: 1;
    cursor: pointer;
  }

  .three-ds-overlay__frame {
    flex: 1;
    width: 100%;
    border: 0;
    background: #fff;
  }
</style>
