<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"
  import { getOperatingHours, subscribeOperatingHours } from "../lib/shopOperatingHours.js"

  let hours = $state(getOperatingHours())

  onMount(() => subscribeOperatingHours((next) => {
    hours = next
  }))
</script>

<header
  class="fixed left-0 right-0 top-0 z-40 border-b border-[#3a3a3a] bg-[#1a1a1a]/95 backdrop-blur"
>
  <div class="mx-auto flex max-w-lg items-start justify-between px-3 py-2.5">
    <div class="flex min-w-0 flex-col items-start gap-0.5">
      <button
        type="button"
        class="border-none bg-transparent p-0 text-lg font-semibold text-[#ff8c42] cursor-pointer"
        onclick={() => push("/")}
      >
        CoffeeOS
      </button>
      {#if hours.loaded && hours.schedule_display}
        <span
          class="text-[10px] leading-tight text-[#a0a0a0]"
          data-testid="shop-hours-display"
        >
          {hours.schedule_display}
        </span>
      {/if}
    </div>
    <span class="pt-0.5 text-xs text-[#a0a0a0]">Витрина</span>
  </div>
</header>
