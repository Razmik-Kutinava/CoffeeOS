<script>
  import { onDestroy } from "svelte"
  import {
    historyRepeatNotice,
    dismissHistoryRepeatNotice
  } from "../lib/historyRepeatPriceCheck.js"

  let notice = $state(null)
  let startX = 0

  const unsub = historyRepeatNotice.subscribe((v) => {
    notice = v
  })

  onDestroy(() => {
    unsub()
    dismissHistoryRepeatNotice()
  })

  function onPointerDown(e) {
    startX = e.clientX
  }

  function onPointerUp(e) {
    if (Math.abs(e.clientX - startX) > 40) dismissHistoryRepeatNotice()
  }

  function onTouchStart(e) {
    startX = e.changedTouches?.[0]?.clientX ?? 0
  }

  function onTouchEnd(e) {
    const x = e.changedTouches?.[0]?.clientX ?? startX
    if (Math.abs(x - startX) > 40) dismissHistoryRepeatNotice()
  }
</script>

{#if notice}
  <div
    class="history-repeat-notice"
    data-testid="shop-history-repeat-notice"
    role="status"
    onpointerdown={onPointerDown}
    onpointerup={onPointerUp}
    ontouchstart={onTouchStart}
    ontouchend={onTouchEnd}
  >
    <p class="history-repeat-notice__text">{notice.text}</p>
    <button
      type="button"
      class="history-repeat-notice__close"
      aria-label="Закрыть"
      onclick={() => dismissHistoryRepeatNotice()}
    >
      ×
    </button>
  </div>
{/if}

<style>
  .history-repeat-notice {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    margin: 0 16px 12px;
    padding: 12px 14px;
    border-radius: 12px;
    background: rgba(255, 140, 66, 0.12);
    border: 1px solid rgba(255, 140, 66, 0.35);
    color: #f5f5f5;
    font-size: 14px;
    line-height: 1.35;
  }
  .history-repeat-notice__text {
    flex: 1;
    margin: 0;
  }
  .history-repeat-notice__close {
    flex-shrink: 0;
    border: none;
    background: transparent;
    color: #a0a0a0;
    font-size: 22px;
    line-height: 1;
    cursor: pointer;
    padding: 0 4px;
  }
</style>
