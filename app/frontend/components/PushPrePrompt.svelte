<script>
  /**
   * TASK_110: встроенная карточка перед системным запросом уведомлений.
   * Секция в потоке родителя (панель заказов / экран заказа) — не модальное окно и не слой поверх шторки.
   * `onAccept` вызывается синхронно из клика: до `requestPermission` нет await (TASK_99).
   */
  import {
    PUSH_PREPROMPT_TITLE,
    PUSH_PREPROMPT_TEXT,
    PUSH_PREPROMPT_ACCEPT,
    PUSH_PREPROMPT_LATER,
    PUSH_PREPROMPT_PENDING
  } from "../lib/pushPrePrompt.js"

  let {
    pending = false,
    compact = false,
    onAccept = undefined,
    onLater = undefined
  } = $props()

  function accept(e) {
    e.stopPropagation()
    if (!pending && typeof onAccept === "function") onAccept()
  }

  function later(e) {
    e.stopPropagation()
    if (!pending && typeof onLater === "function") onLater()
  }
</script>

<div
  class="ppp"
  class:ppp--compact={compact}
  data-testid="push-preprompt"
  role="group"
  aria-label={PUSH_PREPROMPT_TITLE}
>
  <p class="ppp__title">{PUSH_PREPROMPT_TITLE}</p>
  <p class="ppp__text">{PUSH_PREPROMPT_TEXT}</p>
  <div class="ppp__actions">
    <button
      type="button"
      class="ppp__btn ppp__btn--primary"
      data-testid="push-preprompt-accept"
      disabled={pending}
      onclick={accept}
    >{pending ? PUSH_PREPROMPT_PENDING : PUSH_PREPROMPT_ACCEPT}</button>
    <button
      type="button"
      class="ppp__btn"
      data-testid="push-preprompt-later"
      disabled={pending}
      onclick={later}
    >{PUSH_PREPROMPT_LATER}</button>
  </div>
</div>

<style>
  .ppp {
    margin: 0 0 16px;
    padding: 14px 16px;
    border: 1px solid #3a3a3a;
    border-radius: 12px;
    background: #242424;
  }
  .ppp__title {
    margin: 0 0 4px;
    font-size: 15px;
    font-weight: 600;
    color: #f2f2f2;
    line-height: 1.3;
  }
  .ppp__text {
    margin: 0 0 10px;
    font-size: 13px;
    color: #c8c8c8;
    line-height: 1.4;
  }
  .ppp__actions {
    display: flex;
    gap: 8px;
  }
  .ppp__btn {
    flex: 1 1 0;
    min-width: 0;
    margin: 0;
    padding: 10px 12px;
    border: 1px solid #555;
    border-radius: 10px;
    background: #333;
    color: #eee;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
  }
  .ppp__btn--primary {
    border-color: #ff8c42;
    background: #ff8c42;
    color: #1a1a1a;
  }
  .ppp__btn:disabled {
    opacity: 0.7;
    cursor: wait;
  }

  /* Панель заказов: высота ограничена (min(22vh, 8.5rem)), блок прокручивается внутри списка. */
  .ppp--compact {
    margin: 0.35rem 0 0;
    padding: 0.45rem 0.55rem;
    border-color: #555;
    border-radius: 0.65rem;
    background: #222;
  }
  .ppp--compact .ppp__title {
    margin-bottom: 0.15rem;
    font-size: 0.72rem;
  }
  .ppp--compact .ppp__text {
    margin-bottom: 0.35rem;
    font-size: 0.64rem;
    color: #ccc;
    line-height: 1.35;
  }
  .ppp--compact .ppp__actions {
    gap: 0.3rem;
  }
  .ppp--compact .ppp__btn {
    padding: 0.35rem 0.5rem;
    border-color: #666;
    border-radius: 0.5rem;
    font-size: 0.72rem;
  }
  .ppp--compact .ppp__btn--primary {
    border-color: #ff8c42;
    color: #000;
  }
</style>
