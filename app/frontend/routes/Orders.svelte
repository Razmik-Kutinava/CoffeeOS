<script>
  import { onMount } from 'svelte';
  import { push } from 'svelte-spa-router';
  import { api } from '../lib/api.js';
  import { useTelegramBack } from '../lib/telegram.js';
  import PageSkeleton from '../components/PageSkeleton.svelte';

  useTelegramBack(() => push('/profile'));

  let orders = $state([]);
  let loading = $state(true);

  const STATUS_LABELS = {
    pending_payment: 'Ожидает оплаты',
    accepted: 'Принят',
    preparing: 'Готовится',
    ready: 'Готов',
    issued: 'Выдан',
    cancelled: 'Отменён'
  };

  const STATUS_COLORS = {
    pending_payment: '#a0a0a0',
    accepted: '#ff8c42',
    preparing: '#ff8c42',
    ready: '#4caf50',
    issued: '#4caf50',
    cancelled: '#f44336'
  };

  onMount(async () => {
    try {
      orders = await api('/orders/history?today=1');
    } catch {
      orders = [];
    } finally {
      loading = false;
    }
  });

  function formatTime(iso) {
    return new Date(iso).toLocaleTimeString('ru-RU', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }
</script>

<div class="orders-page">
  <div class="page-header">
    <button class="back-btn" onclick={() => push('/profile')}>‹</button>
    <h1>Заказы за сегодня</h1>
  </div>

  {#if loading}
    <PageSkeleton />
  {:else if orders.length === 0}
    <div class="empty-state">
      <div class="empty-icon">📦</div>
      <p>Сегодня заказов пока нет</p>
      <p class="empty-hint">Показаны заказы только этой кофейни. Заказали в другой точке — откройте её витрину по QR.</p>
      <button class="go-catalog" onclick={() => push('/')}>Сделать заказ</button>
    </div>
  {:else}
    <div class="orders-list">
      {#each orders as order (order.id)}
        <div class="order-card">
          <div class="order-top">
            <span class="order-id">Заказ #{order.id}</span>
            <span class="order-status" style="color: {STATUS_COLORS[order.status] || '#a0a0a0'}">
              {STATUS_LABELS[order.status] || order.status}
            </span>
          </div>
          <div class="order-bottom">
            <span class="order-date">{formatTime(order.created_at)}</span>
            <span class="order-total">{Math.round(order.total)} ₽</span>
          </div>
          {#if order.items_count}
            <div class="order-items-count">{order.items_count} поз.</div>
          {/if}
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .orders-page {
    min-height: 100vh;
    background: var(--bg-primary, #1a1a1a);
    padding-bottom: 80px;
  }

  .page-header {
    display: flex;
    align-items: center;
    padding: 16px 20px;
    background: var(--bg-secondary, #2a2a2a);
    gap: 12px;
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .back-btn {
    background: none;
    border: none;
    color: var(--accent, #ff8c42);
    font-size: 28px;
    cursor: pointer;
    padding: 0;
    line-height: 1;
  }

  h1 {
    font-size: 20px;
    font-weight: 700;
    color: var(--text-primary, #fff);
    margin: 0;
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 80px 20px;
    gap: 16px;
    color: var(--text-secondary, #a0a0a0);
  }

  .empty-icon { font-size: 48px; }

  .empty-hint {
    font-size: 13px;
    line-height: 1.4;
    text-align: center;
    max-width: 280px;
    color: #888;
  }

  .go-catalog {
    background: var(--accent, #ff8c42);
    color: white;
    border: none;
    border-radius: 12px;
    padding: 12px 32px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
  }

  .orders-list {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 16px;
  }

  .order-card {
    background: var(--bg-secondary, #2a2a2a);
    border-radius: 12px;
    padding: 16px;
  }

  .order-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
  }

  .order-id {
    font-size: 15px;
    font-weight: 600;
    color: var(--text-primary, #fff);
  }

  .order-status {
    font-size: 13px;
    font-weight: 600;
  }

  .order-bottom {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .order-date {
    font-size: 13px;
    color: var(--text-secondary, #a0a0a0);
  }

  .order-total {
    font-size: 16px;
    font-weight: 700;
    color: var(--accent, #ff8c42);
  }

  .order-items-count {
    font-size: 12px;
    color: var(--text-secondary, #a0a0a0);
    margin-top: 4px;
  }
</style>
