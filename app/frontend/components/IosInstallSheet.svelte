<script>
  import { IOS_INSTALL_DONE, IOS_INSTALL_STEPS, IOS_INSTALL_TITLE } from "../lib/shopInstallBanner.js"

  let { onclose = () => {} } = $props()

  const SWIPE_UP_PX = 40
  let startY = null

  function onTouchStart(event) {
    startY = event.touches?.[0]?.clientY ?? null
  }

  function onTouchEnd(event) {
    if (startY == null) return
    const endY = event.changedTouches?.[0]?.clientY ?? startY
    const swipedUp = startY - endY > SWIPE_UP_PX
    startY = null
    if (swipedUp) onclose()
  }
</script>

<div
  class="ios-install"
  data-testid="ios-install-sheet"
  role="region"
  aria-label={IOS_INSTALL_TITLE}
  ontouchstart={onTouchStart}
  ontouchend={onTouchEnd}
>
  <p class="ios-install__title">{IOS_INSTALL_TITLE}</p>
  <ol class="ios-install__steps">
    {#each IOS_INSTALL_STEPS as step}
      <li>{step}</li>
    {/each}
  </ol>
  <button type="button" class="ios-install__done" data-testid="ios-install-done" onclick={() => onclose()}>
    {IOS_INSTALL_DONE}
  </button>
</div>

<style>
  .ios-install {
    width: 100%;
    margin-top: 0.5rem;
    padding-top: 0.5rem;
    border-top: 1px solid rgba(255, 140, 66, 0.4);
  }
  .ios-install__title {
    margin: 0 0 0.35rem;
    font-weight: 600;
  }
  .ios-install__steps {
    margin: 0 0 0.5rem;
    padding-left: 1.2rem;
  }
  .ios-install__steps li + li {
    margin-top: 0.2rem;
  }
  .ios-install__done {
    border: none;
    border-radius: 8px;
    padding: 0.35rem 0.65rem;
    background: #ff8c42;
    color: #1a1a1a;
    font-weight: 600;
    font-size: 0.75rem;
    cursor: pointer;
  }
</style>
