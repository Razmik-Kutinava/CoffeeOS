<script>
  /**
   * #40 — подтверждение отмены accepted с суммой возврата.
   */
  let {
    open = false,
    title = "",
    body = "",
    confirmLabel = "",
    dismissLabel = "Оставить заказ",
    confirming = false,
    onConfirm = undefined,
    onDismiss = undefined
  } = $props()

  function dismiss() {
    if (confirming) return
    onDismiss?.()
  }
</script>

{#if open}
  <div class="ocm-backdrop" role="presentation" onclick={dismiss}>
    <div
      class="ocm-dialog"
      role="dialog"
      aria-modal="true"
      aria-labelledby="ocm-title"
      tabindex="-1"
      onclick={(e) => e.stopPropagation()}
    >
      <h2 id="ocm-title" class="ocm-title">{title}</h2>
      {#if body}
        <p class="ocm-body">{body}</p>
      {/if}
      <button
        type="button"
        class="ocm-confirm"
        disabled={confirming}
        onclick={() => onConfirm?.()}
      >
        {confirming ? "Отменяем…" : confirmLabel}
      </button>
      <button
        type="button"
        class="ocm-dismiss"
        disabled={confirming}
        onclick={dismiss}
      >
        {dismissLabel}
      </button>
    </div>
  </div>
{/if}

<style>
  .ocm-backdrop {
    position: fixed;
    inset: 0;
    z-index: 80;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    background: rgba(0, 0, 0, 0.45);
    padding: 16px;
  }

  .ocm-dialog {
    width: 100%;
    max-width: 420px;
    background: #1a1a1a;
    color: #f5f5f5;
    border-radius: 16px 16px 12px 12px;
    padding: 20px 16px 16px;
    box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.35);
  }

  .ocm-title {
    margin: 0 0 8px;
    font-size: 1.125rem;
    font-weight: 700;
    line-height: 1.3;
  }

  .ocm-body {
    margin: 0 0 16px;
    font-size: 0.875rem;
    color: #c8c8c8;
    line-height: 1.4;
  }

  .ocm-confirm {
    width: 100%;
    border: none;
    border-radius: 12px;
    padding: 14px 16px;
    background: #ff8c42;
    color: #111;
    font-size: 0.9375rem;
    font-weight: 700;
    cursor: pointer;
  }

  .ocm-confirm:disabled {
    opacity: 0.65;
    cursor: not-allowed;
  }

  .ocm-dismiss {
    width: 100%;
    margin-top: 8px;
    border: none;
    background: transparent;
    color: #a0a0a0;
    font-size: 0.875rem;
    font-weight: 500;
    padding: 12px;
    cursor: pointer;
    text-decoration: underline;
    text-underline-offset: 3px;
  }

  .ocm-dismiss:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
