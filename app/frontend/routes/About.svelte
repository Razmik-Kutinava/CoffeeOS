<script>
  import { push } from "svelte-spa-router"

  const APP_VERSION = "1.0.0"
  const BUILD_CODE = "2026-08-19-001"

  const ABOUT_LINKS = [
    {
      title: "Политика обработки персональных данных",
      url: "https://docs.google.com/document/d/1/view"
    },
    {
      title: "Пользовательское соглашение",
      url: "https://docs.google.com/document/d/2/view"
    },
    {
      title: "Публичная оферта",
      url: "https://docs.google.com/document/d/3/view"
    },
    {
      title: "Полные правила акций",
      url: "https://docs.google.com/document/d/4/view"
    },
    {
      title: "Калорийность и состав",
      url: "https://docs.google.com/document/d/5/view"
    },
    {
      title: "Программа благодарности",
      url: "https://docs.google.com/document/d/6/view"
    }
  ]

  let copied = false

  async function copyAppInfo() {
    const text = `Code Black\nВерсия: ${APP_VERSION}\nКод сборки: ${BUILD_CODE}`
    try {
      await navigator.clipboard.writeText(text)
      copied = true
      setTimeout(() => {
        copied = false
      }, 2000)
    } catch (e) {
      console.error("Не удалось скопировать", e)
    }
  }

  function openLink(url) {
    window.open(url, "_blank")
  }
</script>

<div class="about-page">
  <!-- Заголовок -->
  <div class="about-header">
    <button class="back-btn" onclick={() => push("/personal-account")}>‹</button>
    <h1>О приложении</h1>
  </div>

  <!-- Информация о приложении -->
  <section class="app-info-section">
    <div class="app-info-card">
      <div class="app-icon">☕</div>
      <h2 class="app-name">Code Black</h2>
      <p class="app-version">Версия {APP_VERSION}</p>
      <p class="build-code">Код сборки: <code>{BUILD_CODE}</code></p>
      <button
        class="btn-copy"
        class:copied
        onclick={copyAppInfo}
      >
        {copied ? "✓ Скопировано" : "Скопировать информацию"}
      </button>
    </div>
  </section>

  <!-- Информационные ссылки -->
  <section class="links-section">
    <h3 class="section-title">Информация и правовые документы</h3>
    <div class="links-list">
      {#each ABOUT_LINKS as link (link.title)}
        <button type="button" class="link-item" onclick={() => openLink(link.url)}>
          <span class="link-text">{link.title}</span>
          <span class="link-arrow">›</span>
        </button>
      {/each}
    </div>
  </section>

  <!-- Footer -->
  <footer class="about-footer">
    <p class="footer-org">© 2026 Code Black — Кофейная компания</p>
    <p class="footer-email">support@codeblack.coffee</p>
  </footer>
</div>

<style>
  .about-page {
    min-height: 100vh;
    background: var(--bg-primary, #1a1a1a);
    padding-bottom: 80px;
    color: #fff;
  }

  .about-header {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    background: #2a2a2a;
    border-bottom: 1px solid #3a3a3a;
  }

  .back-btn {
    background: none;
    border: none;
    font-size: 24px;
    color: #fff;
    cursor: pointer;
    padding: 8px;
    display: flex;
    align-items: center;
  }

  .about-header h1 {
    margin: 0;
    font-size: 20px;
    flex: 1;
  }

  .app-info-section {
    padding: 24px 16px;
  }

  .app-info-card {
    background: linear-gradient(135deg, #2a2a2a 0%, #1f1f1f 100%);
    border: 1px solid #3a3a3a;
    border-radius: 16px;
    padding: 32px 24px;
    text-align: center;
  }

  .app-icon {
    font-size: 64px;
    margin-bottom: 16px;
  }

  .app-name {
    margin: 0 0 8px;
    font-size: 24px;
    font-weight: 700;
  }

  .app-version {
    margin: 0 0 4px;
    font-size: 14px;
    color: #a0a0a0;
  }

  .build-code {
    margin: 0 0 20px;
    font-size: 12px;
    color: #888;
    font-family: monospace;
  }

  .build-code code {
    background: #1a1a1a;
    padding: 2px 6px;
    border-radius: 4px;
    color: #ff8c42;
  }

  .btn-copy {
    background: #ff8c42;
    color: #fff;
    border: none;
    padding: 12px 24px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s;
  }

  .btn-copy:active {
    background: #ff7a2a;
  }

  .btn-copy.copied {
    background: #4caf50;
  }

  .links-section {
    padding: 16px;
  }

  .section-title {
    margin: 0 0 12px;
    font-size: 14px;
    font-weight: 600;
    color: #a0a0a0;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .links-list {
    display: flex;
    flex-direction: column;
    gap: 0;
    background: #2a2a2a;
    border-radius: 12px;
    overflow: hidden;
    border: 1px solid #3a3a3a;
  }

  .link-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 14px 16px;
    background: none;
    border: none;
    border-bottom: 1px solid #3a3a3a;
    color: #fff;
    font-size: 14px;
    cursor: pointer;
    transition: background 0.2s;
    text-align: left;
  }

  .link-item:last-child {
    border-bottom: none;
  }

  .link-item:active {
    background: #333;
  }

  .link-text {
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .link-arrow {
    color: #a0a0a0;
    margin-left: 8px;
    font-size: 16px;
  }

  .about-footer {
    text-align: center;
    padding: 32px 16px 16px;
    color: #888;
    font-size: 12px;
    border-top: 1px solid #3a3a3a;
    margin: 0 16px;
  }

  .footer-org {
    margin: 0 0 8px;
  }

  .footer-email {
    margin: 0;
  }
</style>
