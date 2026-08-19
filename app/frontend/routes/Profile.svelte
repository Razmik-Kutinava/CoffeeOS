<script>
  import { onMount } from "svelte"
  import { api } from "../lib/api.js"
  import {
    linkEmailToProfile,
    linkPhoneToProfile,
    sendEmailOtp,
    sendPhoneOtp,
    patchProfileNames
  } from "../lib/shopProfileLink.js"
  import { formatPhoneMask, normalizePhoneToE164Ru } from "../lib/phoneOtp.js"
  import SupportContactSheet from "../components/SupportContactSheet.svelte"

  let user = $state(null)
  let loading = $state(true)
  let toast = $state("")
  let firstName = $state("")
  let lastName = $state("")
  let savingNames = $state(false)
  let supportSheetRef = $state(null)

  let linkMode = $state(null) // email | phone | null
  let linkValue = $state("")
  let linkCode = $state("")
  let linkBusy = $state(false)
  let linkErr = $state("")

  let notificationsEnabled = $state(true)
  let savingNotifications = $state(false)

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
    notificationsEnabled = data?.notifications_enabled !== false
  }

  onMount(async () => {
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
      showToast("Контакт привязан")
    } catch (e) {
      linkErr = e.message
    } finally {
      linkBusy = false
    }
  }

  async function saveNotifications() {
    savingNotifications = true
    try {
      applyUser(await api("profile", {
        method: "PATCH",
        body: JSON.stringify({ notifications_enabled: notificationsEnabled })
      }))
      showToast("Настройки уведомлений сохранены")
    } catch (e) {
      notificationsEnabled = !notificationsEnabled
      showToast(e.message || "Не удалось сохранить настройки")
    } finally {
      savingNotifications = false
    }
  }

  function onSupportChatClick() {
    if (supportSheetRef) {
      supportSheetRef.open()
    }
  }

  async function logout() {
    try {
      await fetch("/logout", { method: "DELETE", credentials: "same-origin" })
      window.location.href = "/"
    } catch (e) {
      showToast("Не удалось выйти. Попробуйте снова")
    }
  }
</script>

<div class="profile-page" data-testid="shop-profile-page">
  {#if toast}
    <div class="toast" data-testid="shop-profile-toast" role="status">{toast}</div>
  {/if}

  {#if loading}
    <div class="loading">Загрузка...</div>
  {:else if !user?.id}
    <div class="loading">Войдите по email или телефону, чтобы управлять профилем</div>
  {:else}
    <div class="profile-header">
      <div class="avatar">{(firstName || user.name || "G")[0]?.toUpperCase()}</div>
      <h2 class="user-name">{user.name || "Гость"}</h2>
    </div>

    <section class="card" data-testid="shop-profile-contacts">
      <h3>Контакты</h3>
      <div class="row">
        <div>
          <div class="label">Email</div>
          <div class="value">{user.email || "—"}</div>
        </div>
        {#if user.email_verified}
          <span class="badge ok">Подтвержден</span>
        {:else}
          <button type="button" class="link-btn" onclick={() => startLink("email")}>Привязать</button>
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
          <button type="button" class="link-btn" onclick={() => startLink("phone")}>Привязать</button>
        {/if}
      </div>

      {#if linkMode}
        <div class="link-box" data-testid="shop-profile-link-flow">
          <div class="label">{linkMode === "email" ? "Добавить Email" : "Добавить телефон"}</div>
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

    <section class="card">
      <h3>Имя</h3>
      <label class="label" for="pf-fn">Имя</label>
      <input id="pf-fn" class="input" bind:value={firstName} />
      <label class="label" for="pf-ln">Фамилия</label>
      <input id="pf-ln" class="input" bind:value={lastName} />
      <button type="button" class="btn primary" disabled={savingNames} onclick={saveNames}>Сохранить</button>
    </section>

    <section class="card">
      <h3>Уведомления</h3>
      <div class="notification-row">
        <label class="label" for="pf-notif">Получать уведомления</label>
        <input
          id="pf-notif"
          type="checkbox"
          bind:checked={notificationsEnabled}
          disabled={savingNotifications}
          onchange={saveNotifications}
          class="checkbox"
        />
      </div>
      {#if savingNotifications}
        <p class="saving-hint">Сохранение...</p>
      {/if}
    </section>

    <div class="menu-list">
      <a href="/#/orders" class="menu-item"><span>📦 Мои заказы</span><span>›</span></a>
      <a href="/#/bonuses" class="menu-item"><span>🎁 Бонусы</span><span>›</span></a>
      <button type="button" class="menu-item menu-btn" data-testid="shop-profile-support-button" onclick={onSupportChatClick}>
        <span>💬 Написать нам</span><span>›</span>
      </button>
      <button type="button" class="menu-item menu-btn logout-btn" onclick={logout}>
        <span>🚪 Выход</span><span>›</span>
      </button>
    </div>
  {/if}
</div>

<SupportContactSheet bind:this={supportSheetRef} />

<style>
  .profile-page { min-height: 100vh; background: var(--bg-primary, #1a1a1a); padding-bottom: 80px; color: #fff; }
  .loading { text-align: center; padding: 60px 20px; color: #a0a0a0; }
  .toast { position: fixed; top: 16px; left: 50%; transform: translateX(-50%); background: #333; padding: 10px 16px; border-radius: 10px; z-index: 50; font-size: 14px; }
  .profile-header { display: flex; flex-direction: column; align-items: center; padding: 32px 20px 16px; background: #2a2a2a; }
  .avatar { width: 64px; height: 64px; border-radius: 50%; background: #ff8c42; display: flex; align-items: center; justify-content: center; font-size: 24px; font-weight: 700; margin-bottom: 8px; }
  .user-name { margin: 0; font-size: 20px; }
  .card { margin: 16px; padding: 16px; background: #2a2a2a; border-radius: 16px; }
  .card h3 { margin: 0 0 12px; font-size: 15px; }
  .row { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid #3a3a3a; }
  .row:last-of-type { border-bottom: none; }
  .label { font-size: 12px; color: #a0a0a0; margin-bottom: 4px; display: block; }
  .value { font-size: 15px; }
  .badge.ok { color: #6dcf7a; font-size: 13px; }
  .link-btn { background: none; border: none; color: #ff8c42; font-size: 13px; cursor: pointer; }
  .input { width: 100%; box-sizing: border-box; margin: 6px 0 10px; padding: 10px 12px; border-radius: 10px; border: 1px solid #444; background: #1a1a1a; color: #fff; }
  .input.code { width: 96px; margin: 0; }
  .actions { display: flex; gap: 8px; align-items: center; margin-bottom: 8px; }
  .btn { padding: 8px 12px; border-radius: 10px; border: 1px solid #555; background: #333; color: #fff; cursor: pointer; }
  .btn.primary { background: #ff8c42; border-color: #ff8c42; }
  .err { color: #f88; font-size: 13px; }
  .link-box { margin-top: 12px; padding-top: 12px; border-top: 1px solid #3a3a3a; }
  .menu-list { margin: 0 16px; background: #2a2a2a; border-radius: 16px; overflow: hidden; }
  .menu-item { display: flex; justify-content: space-between; padding: 16px 20px; color: #fff; text-decoration: none; border-bottom: 1px solid #3a3a3a; }
  .menu-item:last-child { border-bottom: none; }
  .menu-btn { background: none; border: none; cursor: pointer; width: 100%; text-align: left; }
  .logout-btn { color: #f44336; }
  .notification-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; }
  .checkbox { width: 20px; height: 20px; cursor: pointer; }
  .checkbox:disabled { opacity: 0.6; cursor: not-allowed; }
  .saving-hint { font-size: 12px; color: #a0a0a0; margin-top: 8px; }
</style>
