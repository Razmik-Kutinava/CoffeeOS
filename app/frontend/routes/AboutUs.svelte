<script>
  import { push } from "svelte-spa-router"
  import { useTelegramBack } from "../lib/telegram.js"
  import {
    formatAboutCopyText,
    shopAboutFooter,
    shopAboutLegalLinks,
    shopAppVersionInfo
  } from "../lib/shopAboutConfig.js"
  import { shopSpaHrefStaysInWebView } from "../lib/shopWebView.js"

  useTelegramBack(() => push("/profile/settings"))

  let toast = $state("")
  const versionInfo = shopAppVersionInfo()
  const legalLinks = shopAboutLegalLinks()
  const footer = shopAboutFooter()

  function showToast(msg) {
    toast = msg
    setTimeout(() => {
      if (toast === msg) toast = ""
    }, 2500)
  }

  async function copyInfo() {
    const text = formatAboutCopyText()
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text)
        showToast("Скопировано")
      }
    } catch {
      showToast("Не удалось скопировать")
    }
  }

  function openLink(url) {
    if (!url) return
    if (shopSpaHrefStaysInWebView(url)) {
      window.location.href = url
    } else {
      window.open(url, "_blank")
    }
  }
</script>

<div class="about-page" data-testid="shop-about-page">
  {#if toast}
    <div class="toast" role="status">{toast}</div>
  {/if}

  <div class="page-header">
    <button type="button" class="back-btn" onclick={() => push("/profile/settings")} aria-label="Назад">‹</button>
    <h1>О нас</h1>
  </div>

  <section class="version-card">
    <div class="version-line">Версия {versionInfo.version}</div>
    <div class="version-line">Код {versionInfo.buildCode}</div>
    <div class="version-line muted">Сборка {versionInfo.buildLabel}</div>
    <button type="button" class="copy-link" data-testid="shop-about-copy" onclick={copyInfo}>
      Скопировать информацию
    </button>
  </section>

  <nav class="legal-list" aria-label="Юридическая информация">
    {#each legalLinks as link (link.id)}
      <button type="button" class="legal-item" data-testid="shop-about-link-{link.id}" onclick={() => openLink(link.url)}>
        <span>{link.label}</span><span>›</span>
      </button>
    {/each}
  </nav>

  <footer class="about-footer" data-testid="shop-about-footer">
    <div>© {footer.copyrightYear} {footer.legalName}</div>
    <a href="mailto:{footer.supportEmail}">{footer.supportEmail}</a>
  </footer>
</div>

<style>
  .about-page { min-height: 100vh; background: #1a1a1a; color: #fff; padding-bottom: 80px; }
  .page-header { display: flex; align-items: center; padding: 16px 20px; background: #2a2a2a; gap: 12px; position: sticky; top: 0; z-index: 10; }
  .back-btn { background: none; border: none; color: #ff8c42; font-size: 28px; cursor: pointer; padding: 0; line-height: 1; }
  h1 { margin: 0; font-size: 20px; font-weight: 700; }
  .toast { position: fixed; top: 16px; left: 50%; transform: translateX(-50%); background: #333; padding: 10px 16px; border-radius: 10px; z-index: 50; font-size: 14px; }
  .version-card { margin: 16px; padding: 16px; background: #2a2a2a; border-radius: 16px; }
  .version-line { font-size: 15px; margin-bottom: 6px; }
  .version-line.muted { color: #a0a0a0; font-size: 13px; }
  .copy-link { margin-top: 8px; background: none; border: none; color: #6eb6ff; font-size: 14px; cursor: pointer; padding: 0; text-align: left; }
  .legal-list { margin: 0 16px; background: #2a2a2a; border-radius: 16px; overflow: hidden; }
  .legal-item { display: flex; justify-content: space-between; width: 100%; padding: 16px 20px; color: #fff; background: none; border: none; border-bottom: 1px solid #3a3a3a; font-size: 14px; cursor: pointer; text-align: left; gap: 12px; }
  .legal-item:last-child { border-bottom: none; }
  .about-footer { margin: 24px 16px 0; text-align: center; color: #888; font-size: 12px; line-height: 1.6; }
  .about-footer a { color: #888; text-decoration: none; }
</style>
