<script>
  import { onMount } from "svelte"
  import { push } from "svelte-spa-router"

  onMount(() => {
    push("/")
  })
</script>

<p class="py-8 text-center text-sm text-[#a0a0a0]">Перенаправление…</p>
