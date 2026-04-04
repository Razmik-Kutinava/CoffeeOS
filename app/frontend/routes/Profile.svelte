<script>
  import { onMount } from 'svelte';
  import { api } from '../lib/api.js';

  let user = $state(null);
  let loading = $state(true);

  onMount(async () => {
    try {
      user = await api('profile');
    } catch {
      user = { name: 'Гость', balance: 0, points: 0, discount_percent: 0, orders_count: 0 };
    } finally {
      loading = false;
    }
  });
</script>

<div class="profile-page">
  {#if loading}
    <div class="loading">Загрузка...</div>
  {:else}
    <!-- Header / Avatar -->
    <div class="profile-header">
      <div class="avatar">
        {user?.name?.[0]?.toUpperCase() || 'G'}
      </div>
      <h2 class="user-name">{user?.name || 'Гость'}</h2>

      <div class="stats-row">
        <div class="stat-item">
          <span class="stat-value">{user?.balance?.toFixed(0) || 0}₽</span>
          <span class="stat-label">Баланс</span>
        </div>
        <div class="stat-divider"></div>
        <div class="stat-item">
          <span class="stat-value">{user?.points || 0} 🔥</span>
          <span class="stat-label">Баллы</span>
        </div>
        <div class="stat-divider"></div>
        <div class="stat-item">
          <span class="stat-value">{user?.discount_percent || 0}%</span>
          <span class="stat-label">Скидка</span>
        </div>
      </div>
    </div>

    <!-- Menu list -->
    <div class="menu-list">
      <a href="/#/favorites" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">♡</span>
          <span>Избранное</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>

      <a href="/#/orders" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">📦</span>
          <span>Мои заказы</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>

      <a href="/#/reviews" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">💬</span>
          <span>Отзывы</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>

      <a href="/#/deposits" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">💰</span>
          <span>Депозиты</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>

      <a href="/#/bonuses" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">🎁</span>
          <span>Бонусы</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>

      <a href="/#/top-up" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">➕</span>
          <span>Пополнить счёт</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>

      <a href="/#/certificate" class="menu-item">
        <div class="menu-item-left">
          <span class="menu-icon">🎫</span>
          <span>Сертификат</span>
        </div>
        <span class="menu-arrow">›</span>
      </a>
    </div>

    <!-- Footer links -->
    <div class="footer-links">
      <a href="#">Политика конфиденциальности</a>
      <a href="#">Пользовательское соглашение</a>
    </div>
  {/if}
</div>

<style>
  .profile-page {
    min-height: 100vh;
    background: var(--bg-primary, #1a1a1a);
    padding-bottom: 80px;
  }

  .loading {
    text-align: center;
    padding: 60px 20px;
    color: var(--text-secondary, #a0a0a0);
  }

  .profile-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 40px 20px 24px;
    background: var(--bg-secondary, #2a2a2a);
    margin-bottom: 16px;
  }

  .avatar {
    width: 72px;
    height: 72px;
    border-radius: 50%;
    background: var(--accent, #ff8c42);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 28px;
    font-weight: 700;
    color: white;
    margin-bottom: 12px;
  }

  .user-name {
    font-size: 20px;
    font-weight: 700;
    color: var(--text-primary, #fff);
    margin: 0 0 20px;
  }

  .stats-row {
    display: flex;
    align-items: center;
    gap: 0;
    width: 100%;
    justify-content: center;
  }

  .stat-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    flex: 1;
    gap: 4px;
  }

  .stat-value {
    font-size: 18px;
    font-weight: 700;
    color: var(--text-primary, #fff);
  }

  .stat-label {
    font-size: 12px;
    color: var(--text-secondary, #a0a0a0);
  }

  .stat-divider {
    width: 1px;
    height: 36px;
    background: #3a3a3a;
  }

  .menu-list {
    margin: 0 16px;
    background: var(--bg-secondary, #2a2a2a);
    border-radius: 16px;
    overflow: hidden;
  }

  .menu-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 20px;
    color: var(--text-primary, #fff);
    text-decoration: none;
    border-bottom: 1px solid #3a3a3a;
    transition: background 0.15s;
  }

  .menu-item:last-child {
    border-bottom: none;
  }

  .menu-item:active {
    background: #3a3a3a;
  }

  .menu-item-left {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 15px;
  }

  .menu-icon {
    font-size: 20px;
    width: 28px;
    text-align: center;
  }

  .menu-arrow {
    color: var(--text-secondary, #a0a0a0);
    font-size: 22px;
    line-height: 1;
  }

  .footer-links {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    padding: 32px 20px 20px;
  }

  .footer-links a {
    color: var(--text-secondary, #a0a0a0);
    font-size: 13px;
    text-decoration: underline;
    text-underline-offset: 3px;
  }
</style>
