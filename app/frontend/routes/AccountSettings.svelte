<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import {
    linkEmailToProfile,
    linkPhoneToProfile,
    sendEmailOtp,
    sendPhoneOtp,
    patchProfileNames
  } from "../lib/shopProfileLink.js"
  import { formatPhoneMask, normalizePhoneToE164Ru } from "../lib/phoneOtp.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import { loadNotificationPref, saveNotificationPref } from "../lib/shopNotificationPrefs.js"
  import { logoutShopSession } from "../lib/shopAccountLogout.js"
  import ContactSupportSheet from "../components/ContactSupportSheet.svelte"

  useTelegramBack(() => push("/profile"))

  let user = $state(null)
  let loading = $state(true)
  let toast = $state("")
  let firstName = $state("")
  let lastName = $state("")
  let savingNames = $state(false)
  let notificationsEnabled = $state(true)
  let savingNotifications = $state(false)
  let supportSheetOpen = $state(false)
  let loggingOut = $state(false)

  let linkMode = $state(null)
  let linkValue = $state("")
  let linkCode = $state("")
  let linkBusy = $state(false)
  let linkErr = $state("")

  function showToast(msg) {
    toast = msg
    setTimeout(() => {
      if (toast === msg) toast = ""
    }, 3500)
  }

  function applyUser(data) {
    user = data
    firstName = data?.first_name || ""
    lastName = data?.last_name || ""
  }

  onMount(async () => {
    notificationsEnabled = loadNotificationPref(true)
    try {
      applyUser(await api("profile"))
    } catch (e) {
      user = null
      if (e.httpStatus >= 500) showToast("Ошибка сервера. Попробуйте позже.")
      else showToast(e.message || "Войдите, чтобы открыть профиль")
    } finally {
      loading = false
    }
  })

  async function saveNames() {
    savingNames = true
    try {
      applyUser(await patchProfileNames({ first_name: firstName, last_name: lastName }))
      showToast("Имя сохранено")
    } catch (e) {
      showToast(e.message || "Не удалось сохранить")
    } finally {
      savingNames = false
    }
  }

  async function toggleNotifications() {
    const next = !notificationsEnabled
    savingNotifications = true
    const prev = notificationsEnabled
    notificationsEnabled = next
    const result = saveNotificationPref(next)
    savingNotifications = false
    if (!result.ok) {
      notificationsEnabled = prev
      showToast("Не удалось сохранить настройку")
    }
  }

  function startLink(mode) {
    linkMode = mode
    linkValue = mode === "phone" ? "+7" : ""
    linkCode = ""
    linkErr = ""
  }

  async function sendLinkOtp() {
    linkErr = ""
    linkBusy = true
    try {
      if (linkMode === "email") await sendEmailOtp(linkValue)
      else await sendPhoneOtp(normalizePhoneToE164Ru(linkValue) || linkValue, "sms")
      showToast("Код отправлен")
    } catch (e) {
      linkErr = e.message
    } finally {
      linkBusy = false
    }
  }

  async function confirmLink() {
    linkErr = ""
    linkBusy = true
    try {
      const data =
        linkMode === "email"
          ? await linkEmailToProfile(linkValue, linkCode)
          : await linkPhoneToProfile(normalizePhoneToE164Ru(linkValue) || linkValue, linkCode)
      applyUser(data)
      linkMode = null
      showToast("Контакт подтверждён")
    } catch (e) {
      linkErr = e.message
    } finally {
      linkBusy = false
    }
  }

  async function doLogout() {
    if (loggingOut) return
    loggingOut = true
    try {
      await logoutShopSession()
      push("/")
    } finally {
      loggingOut = false
    }
  }
</script>

<div class="settings-page" data-testid="shop-account-settings">
  {#if toast}
    <div class="toast" data-testid="shop-profile-toast" role="status">{toast}</div>
  {/if}

  <div class="page-header">
    <button type="button" class="back-btn" onclick={() => push("/profile")} aria-label="Назад">‹</button>
    <h1>Настройки</h1>
  </div>

  {#if loading}
    <div class="loading">Загрузка...</div>
  {:else if !user?.id}
    <div class="loading">Войдите по email или телефону, чтобы управлять профилем</div>
  {:else}
    <section class="card">
      <label class="label" for="pf-fn">Имя</label>
      <input id="pf-fn" class="input" bind:value={firstName} />
      <button type="button" class="btn primary" disabled={savingNames} onclick={saveNames}>Сохранить</button>
    </section>

    <section class="card row-toggle" data-testid="shop-notifications-toggle">
      <div>
        <div class="label">уведомление</div>
      </div>
      <button
        type="button"
        class="toggle"
        class:on={notificationsEnabled}
        role="switch"
        aria-checked={notificationsEnabled}
        disabled={savingNotifications}
        onclick={toggleNotifications}
      ></button>
    </section>

    <section class="card" data-testid="shop-profile-contacts">
      <div class="row">
        <div>
          <div class="label">Email</div>
          <div class="value">{user.email || "—"}</div>
        </div>
        {#if user.email_verified}
          <span class="badge ok">Подтвержден</span>
        {:else}
          <button type="button" class="link-btn" onclick={() => startLink("email")}>Подтвердить</button>
        {/if}
      </div>
      <div class="row">
        <div>
          <div class="label">Телефон</div>
          <div class="value">{user.phone || "—"}</div>
        </div>
        {#if user.phone_verified}
          <span class="badge ok">Подтвержден</span>
        {:else}
          <button type="button" class="link-btn" onclick={() => startLink("phone")}>Подтвердить</button>
        {/if}
      </div>

      {#if linkMode}
        <div class="link-box" data-testid="shop-profile-link-flow">
          <div class="label">{linkMode === "email" ? "Подтвердить Email" : "Подтвердить телефон"}</div>
          <input
            class="input"
            bind:value={linkValue}
            oninput={linkMode === "phone" ? (e) => (linkValue = formatPhoneMask(e.target.value)) : undefined}
            placeholder={linkMode === "email" ? "email@example.com" : "+7 (900) 000-00-00"}
          />
          <div class="actions">
            <button type="button" class="btn" disabled={linkBusy} onclick={sendLinkOtp}>Код</button>
            <input class="input code" bind:value={linkCode} placeholder="Код" />
            <button type="button" class="btn primary" disabled={linkBusy} onclick={confirmLink}>OK</button>
          </div>
          {#if linkErr}<p class="err">{linkErr}</p>{/if}
          <button type="button" class="link-btn" onclick={() => (linkMode = null)}>Отмена</button>
        </div>
      {/if}
    </section>

    <div class="menu-list">
      <button type="button" class="menu-item" onclick={() => push("/about")}>
        <span>о нас</span><span>›</span>
      </button>
      <button type="button" class="menu-item" data-testid="shop-write-us" onclick={() => (supportSheetOpen = true)}>
        <span>написать нам</span><span>›</span>
      </button>
    </div>

    <div class="logout-wrap">
      <button type="button" class="btn logout" disabled={loggingOut} data-testid="shop-logout" onclick={doLogout}>
        ВЫХОД
      </button>
    </div>
  {/if}
</div>

<ContactSupportSheet bind:open={supportSheetOpen} />

<style>
  .settings-page { min-height: 100vh; background: var(--bg-primary, #1a1a1a); padding-bottom: 80px; color: #fff; }
  .page-header { display: flex; align-items: center; padding: 16px 20px; background: #2a2a2a; gap: 12px; position: sticky; top: 0; z-index: 10; }
  .back-btn { background: none; border: none; color: #ff8c42; font-size: 28px; cursor: pointer; padding: 0; line-height: 1; }
  h1 { margin: 0; font-size: 20px; font-weight: 700; }
  .loading { text-align: center; padding: 60px 20px; color: #a0a0a0; }
  .toast { position: fixed; top: 16px; left: 50%; transform: translateX(-50%); background: #333; padding: 10px 16px; border-radius: 10px; z-index: 50; font-size: 14px; }
  .card { margin: 16px; padding: 16px; background: #2a2a2a; border-radius: 16px; }
  .row-toggle { display: flex; justify-content: space-between; align-items: center; }
  .row { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid #3a3a3a; }
  .row:last-of-type { border-bottom: none; }
  .label { font-size: 12px; color: #a0a0a0; margin-bottom: 4px; display: block; }
  .value { font-size: 15px; }
  .badge.ok { color: #6dcf7a; font-size: 13px; }
  .link-btn { background: none; border: none; color: #ff8c42; font-size: 13px; cursor: pointer; }
  .input { width: 100%; box-sizing: border-box; margin: 6px 0 10px; padding: 10px 12px; border-radius: 10px; border: 1px solid #444; background: #1a1a1a; color: #fff; }
  .input.code { width: 96px; margin: 0; }
  .actions { display: flex; gap: 8px; align-items: center; margin-bottom: 8px; }
  .btn { padding: 10px 16px; border-radius: 10px; border: 1px solid #555; background: #333; color: #fff; cursor: pointer; font-weight: 600; }
  .btn.primary { background: #ff8c42; border-color: #ff8c42; width: 100%; margin-top: 8px; }
  .btn.logout { width: 100%; background: #ff8c42; border-color: #ff8c42; padding: 14px; font-size: 15px; letter-spacing: 0.04em; }
  .err { color: #f88; font-size: 13px; }
  .link-box { margin-top: 12px; padding-top: 12px; border-top: 1px solid #3a3a3a; }
  .toggle { width: 48px; height: 28px; border-radius: 999px; border: none; background: #555; position: relative; cursor: pointer; flex-shrink: 0; }
  .toggle::after { content: ""; position: absolute; top: 3px; left: 3px; width: 22px; height: 22px; border-radius: 50%; background: #fff; transition: transform 0.2s; }
  .toggle.on { background: #ff8c42; }
  .toggle.on::after { transform: translateX(20px); }
  .menu-list { margin: 0 16px; background: #2a2a2a; border-radius: 16px; overflow: hidden; }
  .menu-item { display: flex; justify-content: space-between; width: 100%; padding: 16px 20px; color: #fff; background: none; border: none; border-bottom: 1px solid #3a3a3a; font-size: 15px; cursor: pointer; text-align: left; }
  .menu-item:last-child { border-bottom: none; }
  .logout-wrap { margin: 24px 16px 0; }
</style>
