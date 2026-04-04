<script>
  import { push } from 'svelte-spa-router';
  import { useTelegramBack } from '../lib/telegram.js';
  useTelegramBack(() => push('/profile'));
</script>
<div class="stub-page">
  <div class="page-header">
    <button class="back-btn" onclick={() => push('/profile')}>‹</button>
    <h1>Депозиты</h1>
  </div>
  <div class="coming-soon">
    <div class="icon">💰</div>
    <p>Скоро</p>
  </div>
</div>
<style>
  .stub-page { min-height: 100vh; background: var(--bg-primary, #1a1a1a); }
  .page-header { display: flex; align-items: center; padding: 16px 20px; background: var(--bg-secondary, #2a2a2a); gap: 12px; }
  .back-btn { background: none; border: none; color: var(--accent, #ff8c42); font-size: 28px; cursor: pointer; padding: 0; }
  h1 { font-size: 20px; font-weight: 700; color: var(--text-primary, #fff); margin: 0; }
  .coming-soon { display: flex; flex-direction: column; align-items: center; padding: 80px 20px; gap: 12px; color: var(--text-secondary, #a0a0a0); }
  .icon { font-size: 48px; }
</style>
