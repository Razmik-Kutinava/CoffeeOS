<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { useTelegramBack } from "../lib/telegram.js"
  import PageSkeleton from "../components/PageSkeleton.svelte"

  let { params = {} } = $props()

  useTelegramBack(() => push("/profile"))

  let order = $state(null)
  let loading = $state(true)
  let loadError = $state(false)

  const OFD_PLACEHOLDER =
    "Чек будет доступен после подключения ОФД банка. Сейчас отображается состав заказа из CoffeeOS."

  onMount(async () => {
    try {
      order = await api(`/orders/${params.id}`)
    } catch {
      order = null
      loadError = true
    } finally {
      loading = false
    }
  })

  function formatDate(iso) {
    const d = new Date(iso)
    if (Number.isNaN(d.getTime())) return ""
    return d.toLocaleDateString("ru-RU", { day: "2-digit", month: "2-digit" })
  }

  function primaryTitle() {
    const first = order?.items?.[0]?.product_name
    return first || "Заказ"
  }

  function onRepeatStub() {
    /* Subtask 12: без бизнес-логики повтора */
  }
</script>

<div class="receipt-page" data-testid="shop-order-receipt">
  <div class="page-header">
    <button type="button" class="back-btn" onclick={() => push("/profile")} aria-label="Назад">‹</button>
    <h1>{order ? formatDate(order.created_at) : "Заказ"}</h1>
  </div>

  {#if loading}
    <PageSkeleton />
  {:else if loadError || !order}
    <div class="state-error">Не удалось загрузить заказ</div>
  {:else}
    <section class="card">
      <h2>{primaryTitle()}</h2>
      <div class="ofd-box" data-testid="shop-order-ofd-placeholder">{OFD_PLACEHOLDER}</div>

      <ul class="items">
        {#each order.items || [] as item, i (i)}
          <li class="item-row">
            <span>{item.product_name} × {item.quantity}</span>
            <span>{Math.round(item.line_total ?? item.price * item.quantity)} ₽</span>
          </li>
        {/each}
      </ul>

      <div class="total-row">
        <span>Итого</span>
        <span>{Math.round(order.total)} ₽</span>
      </div>
    </section>

    <div class="repeat-wrap">
      <button type="button" class="repeat-main" data-testid="shop-order-repeat-stub" onclick={onRepeatStub}>
        ПОВТОРИТЬ
      </button>
    </div>
  {/if}
</div>

<style>
  .receipt-page { min-height: 100vh; background: #1a1a1a; color: #fff; padding-bottom: 96px; }
  .page-header { display: flex; align-items: center; padding: 16px 20px; background: #2a2a2a; gap: 12px; position: sticky; top: 0; z-index: 10; }
  .back-btn { background: none; border: none; color: #ff8c42; font-size: 28px; cursor: pointer; padding: 0; line-height: 1; }
  h1 { margin: 0; font-size: 20px; font-weight: 700; }
  .card { margin: 16px; padding: 16px; background: #2a2a2a; border-radius: 16px; }
  h2 { margin: 0 0 12px; font-size: 18px; }
  .ofd-box { background: #1a1a1a; border-radius: 12px; padding: 12px; color: #a0a0a0; font-size: 13px; line-height: 1.45; margin-bottom: 16px; min-height: 96px; }
  .items { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
  .item-row { display: flex; justify-content: space-between; gap: 12px; font-size: 14px; }
  .total-row { display: flex; justify-content: space-between; margin-top: 16px; padding-top: 12px; border-top: 1px solid #3a3a3a; font-weight: 700; font-size: 16px; }
  .repeat-wrap { position: fixed; left: 16px; right: 16px; bottom: calc(16px + env(safe-area-inset-bottom, 0px)); }
  .repeat-main { width: 100%; background: #ff8c42; color: #fff; border: none; border-radius: 12px; padding: 16px; font-size: 16px; font-weight: 700; cursor: pointer; }
  .state-error { text-align: center; padding: 48px 20px; color: #a0a0a0; }
</style>
