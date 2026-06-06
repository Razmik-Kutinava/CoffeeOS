<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { api } from "../lib/api.js"
  import { loadGuestProfile, saveGuestProfile } from "../lib/shopGuestProfile.js"
  import {
    lastGuestOrderId,
    reconnectGuestOrder,
    returningFromPaymentPage,
    saveGuestOrderSession
  } from "../lib/shopGuestSession.js"
  import { savePaymentSession } from "../lib/tbankPayment.js"

  let name = $state("")
  let phone = $state("")
  let comment = $state("")
  let is_car_pickup = $state(false)
  let car_number = $state("")
  let promo_code = $state("")
  let payment_method = $state("card")
  let submitting = $state(false)
  let err = $state(null)
  let done = $state(null)
  let savedProfile = $state(false)
  let editContact = $state(true)

  onMount(() => {
    const profile = loadGuestProfile()
    if (profile) {
      name = profile.name
      phone = profile.phone
      savedProfile = true
      editContact = false
    }

    const recover = async () => {
      const orderId = lastGuestOrderId()
      if (!orderId) return
      await reconnectGuestOrder(api)
      if (returningFromPaymentPage()) {
        push(`/payment-result?status=fail&order_id=${orderId}`)
      }
    }

    recover()
    const onPageShow = (event) => {
      if (event.persisted) recover()
    }
    window.addEventListener("pageshow", onPageShow)
    return () => window.removeEventListener("pageshow", onPageShow)
  })

  async function submit() {
    if (submitting) return
    err = null
    submitting = true
    let redirecting = false
    try {
      saveGuestProfile({ name, phone })
      savedProfile = true
      editContact = false

      const res = await api("/orders", {
        method: "POST",
        body: JSON.stringify({
          name,
          phone,
          comment,
          is_car_pickup,
          car_number,
          promo_code: promo_code || undefined,
          payment_method
        })
      })

      if (res.payment_url || res.provider_payment_id) {
        saveGuestOrderSession(res.order_id, res.reconnect_token)

        if (res.payment_iframe && res.provider_payment_id) {
          let config = {}
          try {
            config = await api("/config")
          } catch {
            config = {}
          }
          savePaymentSession({
            order_id: res.order_id,
            total: res.total,
            provider_payment_id: res.provider_payment_id,
            terminal_key: res.terminal_key || config.terminal_key,
            payment_url: res.payment_url,
            reconnect_token: res.reconnect_token,
            payment_iframe: true,
            integration_script_url: config.integration_script_url
          })
          redirecting = true
          push("/payment")
          return
        }

        redirecting = true
        window.location.href = res.payment_url
        return
      }

      done = res
    } catch (e) {
      err = e.message
    } finally {
      if (!redirecting) submitting = false
    }
  }
</script>

{#if done}
  <div class="py-8 text-center">
    <p class="mb-2 text-xs text-[#888]">Корзина → Оформление → Результат</p>
    <p class="mb-2 text-xl font-bold text-green-400">Заказ #{done.order_id} принят</p>
    <p class="mb-1 text-[#fff]">Сумма: {Math.round(done.total)}₽</p>
    <p class="mb-6 text-sm text-[#a0a0a0]">Статус: {done.status}</p>
    <div class="flex flex-col gap-3">
      <button
        type="button"
        class="rounded-xl bg-[#ff8c42] px-6 py-3 font-semibold text-black"
        onclick={() => push("/orders")}
      >
        История заказов
      </button>
      <button
        type="button"
        class="rounded-xl border border-[#3a3a3a] px-6 py-3 text-[#a0a0a0]"
        onclick={() => push("/")}
      >
        На главную
      </button>
    </div>
  </div>
{:else}
  <div class="mb-4 flex items-center gap-3">
    <button type="button" class="text-2xl text-[#ff8c42]" onclick={() => push("/cart")} aria-label="Назад в корзину">
      ‹
    </button>
    <div>
      <h1 class="text-xl font-bold">Оформление</h1>
      <p class="text-xs text-[#888]">Корзина → Оформление → Оплата → История</p>
    </div>
  </div>

  {#if savedProfile && !editContact}
    <div class="mb-4 rounded-xl border border-[#3a3a3a] bg-[#2a2a2a] p-4">
      <p class="mb-1 text-sm text-[#a0a0a0]">Контакты</p>
      <p class="font-medium text-white">{name}</p>
      <p class="text-sm text-[#a0a0a0]">{phone}</p>
      <button type="button" class="mt-2 text-sm text-[#ff8c42]" onclick={() => (editContact = true)}>
        Изменить
      </button>
    </div>
  {:else}
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
  {/if}

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

  <div class="mb-6">
    <span class="mb-2 block text-sm text-[#a0a0a0]">Способ оплаты</span>
    <div class="flex gap-3">
      {#each [["card", "Картой"], ["sbp", "СБП"], ["cash", "Наличные"]] as [val, label]}
        <label class="flex flex-1 cursor-pointer items-center justify-center gap-2 rounded-lg border px-3 py-2 text-sm
          {payment_method === val ? 'border-[#ff8c42] bg-[#ff8c42]/10 text-[#ff8c42]' : 'border-[#3a3a3a] text-[#a0a0a0]'}">
          <input type="radio" bind:group={payment_method} value={val} class="hidden" />
          {label}
        </label>
      {/each}
    </div>
  </div>

  {#if err}
    <p class="mb-4 text-sm text-red-400">{err}</p>
  {/if}

  <button
    type="button"
    class="w-full rounded-xl bg-[#ff8c42] py-4 text-lg font-semibold text-black disabled:opacity-50"
    disabled={submitting || !phone || !name}
    onclick={submit}
  >
    {submitting
      ? payment_method === "cash"
        ? "Оформляем…"
        : "Идёт оплата…"
      : payment_method === "cash"
        ? "Оформить (наличные)"
        : "Оплатить →"}
  </button>
{/if}
