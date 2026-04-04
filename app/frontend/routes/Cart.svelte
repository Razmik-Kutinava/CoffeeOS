<script>
  import { onMount } from "svelte"
  import { link, push } from "svelte-spa-router"
  import { api } from "../lib/api.js"

  let items = $state([])
  let total = $state(0)
  let loading = $state(true)
  let promo = $state("")
  let promoPreview = $state(null)
  let err = $state(null)

  async function load() {
    const data = await api("/cart")
    items = data.items
    total = data.total
  }

  onMount(async () => {
    try {
      await load()
    } catch (e) {
      err = e.message
    } finally {
      loading = false
    }
  })

  async function applyPromo() {
    try {
      promoPreview = await api("/promo_codes/apply", {
        method: "POST",
        body: JSON.stringify({ code: promo, order_total: total })
      })
    } catch (e) {
      err = e.message
      promoPreview = null
    }
  }

  async function bump(index, delta) {
    err = null
    await api(`/cart/items/${index}`, {
      method: "PATCH",
      body: JSON.stringify({ delta })
    })
    await load()
  }

  async function removeLine(index) {
    err = null
    await api(`/cart/items/${index}`, { method: "DELETE" })
    await load()
  }
</script>

<h1 class="mb-4 text-xl font-bold">Корзина</h1>

{#if loading}
  <p class="text-[#a0a0a0]">Загрузка…</p>
{:else if err && !items.length}
  <p class="text-red-400">{err}</p>
{:else if !items.length}
  <div class="py-12 text-center text-[#a0a0a0]">
    <p class="mb-4 text-4xl">🛒</p>
    <p>Корзина пуста</p>
    <a use:link href="/" class="mt-4 inline-block text-[#ff8c42]">Перейти в каталог</a>
  </div>
{:else}
  {#each items as line (line.index)}
    <div class="mb-4 flex gap-3 rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-3">
      {#if line.image_url}
        <img src={line.image_url} alt="" class="h-20 w-20 shrink-0 rounded-lg object-cover" decoding="async" />
      {/if}
      <div class="min-w-0 flex-1">
        <a use:link href="/product/{line.product_id}" class="font-medium hover:underline">{line.product_name}</a>
        <p class="text-sm text-[#a0a0a0]">
          {Math.round(line.unit_total)}₽ × {line.quantity}
        </p>
        <div class="mt-2 flex items-center gap-2">
          <button
            type="button"
            class="rounded bg-[#3a3a3a] px-2 py-0.5 text-sm"
            onclick={() => bump(line.index, -1)}
          >
            −
          </button>
          <span class="text-sm">{line.quantity}</span>
          <button
            type="button"
            class="rounded bg-[#3a3a3a] px-2 py-0.5 text-sm"
            onclick={() => bump(line.index, 1)}
          >
            +
          </button>
          <button
            type="button"
            class="ml-auto text-sm text-red-400"
            onclick={() => removeLine(line.index)}
          >
            Удалить
          </button>
        </div>
      </div>
    </div>
  {/each}

  <div class="mb-4 flex gap-2">
    <input
      bind:value={promo}
      placeholder="Промокод"
      class="flex-1 rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2 text-sm"
    />
    <button type="button" class="rounded-lg bg-[#3a3a3a] px-3 py-2 text-sm" onclick={applyPromo}>
      Применить
    </button>
  </div>
  {#if promoPreview?.valid}
    <p class="mb-2 text-sm text-green-400">
      Скидка {Math.round(promoPreview.discount)}₽ → итого {Math.round(promoPreview.final_total)}₽
    </p>
  {/if}

  <div class="mb-4 flex justify-between text-lg">
    <span>Итого</span>
    <span class="font-bold text-[#ff8c42]">{Math.round(total)}₽</span>
  </div>

  <button
    type="button"
    class="w-full rounded-xl bg-[#ff8c42] py-4 text-lg font-semibold text-black"
    onclick={() => push("/checkout")}
  >
    Оформить заказ
  </button>
{/if}
