<script>
  import { onMount } from "svelte"
  import { api } from "../lib/api.js"
  import { createRepeatInlineOrder } from "../lib/createRepeatInlineOrder.js"

  let user = $state(null)
  let orders = $state([])
  let loading = $state(true)
  let error = $state(null)

  const STATUS_LABELS = {
    pending_payment: "Ожидает оплаты",
    accepted: "Принят",
    preparing: "Готовится",
    ready: "Готов",
    issued: "Выдан",
    cancelled: "Отменён"
  }

  const STATUS_COLORS = {
    pending_payment: "#a0a0a0",
    accepted: "#ff8c42",
    preparing: "#ff8c42",
    ready: "#4caf50",
    issued: "#4caf50",
    cancelled: "#f44336"
  }

  onMount(async () => {
    try {
      user = await api("profile")
      orders = await api("/orders/history")
    } catch (e) {
      error = e.message || "Не удалось загрузить данные"
      user = null
      orders = []
    } finally {
      loading = false
    }
  })

  function formatDate(iso) {
    return new Date(iso).toLocaleDateString("ru-RU", {
      month: "short",
      day: "numeric"
    })
  }

  function getAvatarText(user) {
    if (!user) return "G"
    const name = user.first_name || user.name || ""
    return name[0]?.toUpperCase() || "G"
  }

  async function logout() {
    try {
      await fetch("/logout", { method: "DELETE", credentials: "same-origin" })
      window.location.href = "/"
    } catch (e) {
      alert("Не удалось выйти")
    }
  }

  async function repeatOrder(orderId) {
    try {
      await createRepeatInlineOrder(api, orderId)
    } catch (e) {
      alert(e.message || "Не удалось повторить заказ")
    }
  }
</script>

<div class="personal-account-page">
  {#if loading}
    <div class="loading">Загрузка личного кабинета...</div>
  {:else if error && !user}
    <div class="error-state">
      <div class="error-icon">❌</div>
      <p>{error}</p>
      <button class="btn-primary" onclick={() => (window.location.href = "/#/")}>
        Вернуться на главную
      </button>
    </div>
  {:else if user}
    <!-- Заголовок с данными пользователя -->
    <div class="account-header">
      <div class="avatar">{getAvatarText(user)}</div>
      <div class="user-info">
        <h2 class="user-name">{user.first_name || user.name || "Гость"}</h2>
        <p class="user-phone">{user.phone || user.email || "Телефон не указан"}</p>
      </div>
      <button class="icon-button" title="Уведомления">🔔</button>
    </div>

    <!-- PLG блоки (зарезервированы, без логики) -->
    <div class="plg-containers">
      <div class="plg-block plg-1">
        <!-- PLG Marketing Block 1 -->
      </div>
      <div class="plg-block plg-2">
        <!-- PLG Marketing Block 2 -->
      </div>
    </div>

    <!-- История заказов -->
    <section class="orders-section">
      <h3 class="section-title">Недавние заказы</h3>

      {#if orders.length === 0}
        <div class="empty-orders">
          <div class="empty-icon">📦</div>
          <p>У вас еще нет заказов</p>
          <p class="empty-hint">Начните с каталога и разместите свой первый заказ</p>
          <button class="btn-primary" onclick={() => (window.location.href = "/#/")}>
            Перейти в каталог
          </button>
        </div>
      {:else}
        <div class="orders-list">
          {#each orders as order (order.id)}
            <a href={`/#/order/${order.id}`} class="order-item">
              <div class="order-info">
                <div class="order-title">{order.title || `Заказ #${order.id}`}</div>
                <div class="order-meta">
                  <span class="order-date">{formatDate(order.created_at)}</span>
                  <span class="order-status" style="color: {STATUS_COLORS[order.status] || '#a0a0a0'}">
                    {STATUS_LABELS[order.status] || order.status}
                  </span>
                </div>
              </div>
              <div class="order-amount">{Math.round(order.total)} ₽</div>
              <button class="repeat-btn" onclick={(e) => {
                e.preventDefault()
                repeatOrder(order.id)
              }}>
                Повторить
              </button>
            </a>
          {/each}
        </div>
      {/if}
    </section>

    <!-- Меню -->
    <div class="menu-section">
      <a href="/#/profile" class="menu-item">
        <span>⚙️ Профиль и настройки</span>
        <span>›</span>
      </a>
      <a href="/#/about" class="menu-item">
        <span>ℹ️ О приложении</span>
        <span>›</span>
      </a>
      <button type="button" class="menu-item menu-btn logout-btn" onclick={logout}>
        <span>🚪 Выход</span>
        <span>›</span>
      </button>
    </div>
  {/if}
</div>

<style>
  .personal-account-page {
    min-height: 100vh;
    background: var(--bg-primary, #1a1a1a);
    padding-bottom: 80px;
    color: #fff;
  }

  .loading, .error-state {
    text-align: center;
    padding: 60px 20px;
    color: #a0a0a0;
  }

  .error-icon {
    font-size: 48px;
    margin-bottom: 16px;
  }

  .account-header {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 20px;
    background: linear-gradient(135deg, #2a2a2a 0%, #1f1f1f 100%);
    border-bottom: 1px solid #3a3a3a;
  }

  .avatar {
    width: 56px;
    height: 56px;
    border-radius: 50%;
    background: linear-gradient(135deg, #ff8c42 0%, #ff7a2a 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 24px;
    font-weight: 700;
    flex-shrink: 0;
  }

  .user-info {
    flex: 1;
    min-width: 0;
  }

  .user-name {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .user-phone {
    margin: 4px 0 0;
    font-size: 13px;
    color: #a0a0a0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .icon-button {
    background: none;
    border: none;
    font-size: 20px;
    cursor: pointer;
    padding: 8px;
  }

  .plg-containers {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
    padding: 8px;
    background: #1a1a1a;
  }

  .plg-block {
    aspect-ratio: 1;
    background: #2a2a2a;
    border-radius: 12px;
    border: 2px dashed #3a3a3a;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #666;
    font-size: 12px;
    text-align: center;
    padding: 8px;
    min-height: 120px;
  }

  .orders-section {
    padding: 16px;
  }

  .section-title {
    margin: 0 0 12px;
    font-size: 16px;
    font-weight: 600;
    color: #fff;
  }

  .empty-orders {
    text-align: center;
    padding: 40px 20px;
    background: #2a2a2a;
    border-radius: 12px;
    color: #a0a0a0;
  }

  .empty-icon {
    font-size: 48px;
    margin-bottom: 12px;
  }

  .empty-hint {
    font-size: 13px;
    margin-top: 8px;
    color: #888;
  }

  .orders-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .order-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px;
    background: #2a2a2a;
    border-radius: 10px;
    text-decoration: none;
    color: inherit;
    border: 1px solid #3a3a3a;
    transition: background 0.2s;
  }

  .order-item:active {
    background: #333;
  }

  .order-info {
    flex: 1;
    min-width: 0;
  }

  .order-title {
    font-size: 14px;
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .order-meta {
    display: flex;
    gap: 8px;
    margin-top: 4px;
    font-size: 12px;
    color: #a0a0a0;
  }

  .order-status {
    font-weight: 500;
  }

  .order-amount {
    font-size: 14px;
    font-weight: 600;
    white-space: nowrap;
    margin-right: 8px;
  }

  .repeat-btn {
    padding: 6px 12px;
    background: #ff8c42;
    border: none;
    border-radius: 6px;
    color: #fff;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    white-space: nowrap;
    transition: background 0.2s;
  }

  .repeat-btn:active {
    background: #ff7a2a;
  }

  .menu-section {
    margin: 16px;
    background: #2a2a2a;
    border-radius: 12px;
    overflow: hidden;
    border: 1px solid #3a3a3a;
  }

  .menu-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 14px 16px;
    color: #fff;
    text-decoration: none;
    border-bottom: 1px solid #3a3a3a;
    font-size: 14px;
    transition: background 0.2s;
  }

  .menu-item:last-child {
    border-bottom: none;
  }

  .menu-item:active {
    background: #333;
  }

  .menu-btn {
    background: none;
    border: none;
    cursor: pointer;
    width: 100%;
    text-align: left;
  }

  .logout-btn {
    color: #f44336;
  }

  .btn-primary {
    background: #ff8c42;
    color: #fff;
    border: none;
    padding: 12px 24px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    margin-top: 16px;
    transition: background 0.2s;
  }

  .btn-primary:active {
    background: #ff7a2a;
  }
</style>
