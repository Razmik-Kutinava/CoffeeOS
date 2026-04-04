<script>
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"

  let name = $state("")
  let phone = $state("")
  let comment = $state("")
  let is_car_pickup = $state(false)
  let car_number = $state("")
  let promo_code = $state("")
  let submitting = $state(false)
  let err = $state(null)
  let doneId = $state(null)

  async function submit() {
    err = null
    submitting = true
    try {
      const res = await api("/orders", {
        method: "POST",
        body: JSON.stringify({
          name,
          phone,
          comment,
          is_car_pickup,
          car_number,
          promo_code: promo_code || undefined
        })
      })
      doneId = res.order_id
    } catch (e) {
      err = e.message
    } finally {
      submitting = false
    }
  }
</script>

{#if doneId}
  <div class="py-8 text-center">
    <p class="mb-2 text-xl font-bold text-green-400">Заказ #{doneId} создан</p>
    <p class="mb-6 text-[#a0a0a0]">Оплата (ЮКасса) подключается на следующем шаге.</p>
    <button
      type="button"
      class="rounded-xl bg-[#ff8c42] px-6 py-3 font-semibold text-black"
      onclick={() => push("/")}
    >
      На главную
    </button>
  </div>
{:else}
  <h1 class="mb-4 text-xl font-bold">Оформление</h1>
  <p class="mb-4 text-sm text-[#a0a0a0]">Самовывоз: NAPI:BAR, Самара</p>

  <label class="mb-3 block">
    <span class="mb-1 block text-sm text-[#a0a0a0]">Имя</span>
    <input
      bind:value={name}
      class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2"
      autocomplete="name"
    />
  </label>
  <label class="mb-3 block">
    <span class="mb-1 block text-sm text-[#a0a0a0]">Телефон</span>
    <input
      bind:value={phone}
      class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2"
      autocomplete="tel"
    />
  </label>
  <label class="mb-3 block">
    <span class="mb-1 block text-sm text-[#a0a0a0]">Комментарий</span>
    <textarea
      bind:value={comment}
      class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2"
      rows="2"
    ></textarea>
  </label>
  <label class="mb-3 flex items-center gap-2">
    <input type="checkbox" bind:checked={is_car_pickup} />
    <span class="text-sm">Выдача в машину</span>
  </label>
  {#if is_car_pickup}
    <label class="mb-3 block">
      <span class="mb-1 block text-sm text-[#a0a0a0]">Номер авто</span>
      <input bind:value={car_number} class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2" />
    </label>
  {/if}
  <label class="mb-6 block">
    <span class="mb-1 block text-sm text-[#a0a0a0]">Промокод (необязательно)</span>
    <input bind:value={promo_code} class="w-full rounded-lg border border-[#3a3a3a] bg-[#2a2a2a] px-3 py-2" />
  </label>

  {#if err}
    <p class="mb-4 text-sm text-red-400">{err}</p>
  {/if}

  <button
    type="button"
    class="w-full rounded-xl bg-[#ff8c42] py-4 text-lg font-semibold text-black disabled:opacity-50"
    disabled={submitting || !phone || !name}
    onclick={submit}
  >
    {submitting ? "Отправка…" : "Подтвердить заказ"}
  </button>
{/if}
