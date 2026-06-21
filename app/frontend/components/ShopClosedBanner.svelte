<script>
  import { onMount } from "svelte"
  import { getOperatingHours, subscribeOperatingHours } from "../lib/shopOperatingHours.js"

  let hours = $state(getOperatingHours())

  onMount(() => subscribeOperatingHours((next) => {
    hours = next
  }))
</script>

{#if hours.loaded && hours.is_open === false && hours.closed_message}
  <div
    class="fixed left-0 right-0 top-[4.25rem] z-40 mx-auto max-w-lg px-3"
    role="status"
    data-testid="shop-closed-banner"
  >
    <div class="rounded-lg border border-amber-500/40 bg-amber-950/90 px-3 py-2 text-sm text-amber-100">
      {hours.closed_message}
    </div>
  </div>
{/if}
