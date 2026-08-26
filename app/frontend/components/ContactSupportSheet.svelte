<script>
  import { shopSupportMailto, shopSupportTelegramUrl } from "../lib/shopAboutConfig.js"
  import { cleanDeepLinkUrl, openDeepLink } from "../lib/deepLink.js"
  import { shopSpaHrefStaysInWebView } from "../lib/shopWebView.js"

  let { open = $bindable(false), onClose = undefined } = $props()

  function closeSheet() {
    open = false
    onClose?.()
  }

  function openEmail() {
    const mailto = shopSupportMailto()
    if (!mailto) return
    if (shopSpaHrefStaysInWebView(mailto)) {
      window.location.href = mailto
    } else {
      window.open(mailto, "_blank")
    }
    closeSheet()
  }

  function openTelegram() {
    const url = cleanDeepLinkUrl(shopSupportTelegramUrl())
    if (!url) return
    if (shopSpaHrefStaysInWebView(url)) {
      window.location.href = url
    } else {
      openDeepLink(url)
    }
    closeSheet()
  }
</script>

{#if open}
  <div
    class="cs-backdrop"
    role="presentation"
    data-testid="contact-support-backdrop"
    onclick={closeSheet}
  ></div>
  <section class="cs-sheet" data-testid="contact-support-sheet" aria-label="Написать нам">
    <div class="cs-handle"></div>
    <div class="cs-actions">
      <button type="button" class="cs-btn" data-testid="contact-support-email" onclick={openEmail}>
        e mail
      </button>
      <button type="button" class="cs-btn" data-testid="contact-support-telegram" onclick={openTelegram}>
        Tg
      </button>
    </div>
  </section>
{/if}

<style>
  .cs-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.55);
    z-index: 60;
  }

  .cs-sheet {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 61;
    background: #2a2a2a;
    border-radius: 16px 16px 0 0;
    padding: 12px 16px calc(16px + env(safe-area-inset-bottom, 0px));
  }

  .cs-handle {
    width: 40px;
    height: 4px;
    background: #555;
    border-radius: 999px;
    margin: 0 auto 16px;
  }

  .cs-actions {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }

  .cs-btn {
    min-height: 88px;
    border-radius: 12px;
    border: 1px solid #444;
    background: #1a1a1a;
    color: #fff;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
  }

  .cs-btn:active {
    opacity: 0.9;
  }
</style>
