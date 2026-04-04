<script>
  import { link } from "svelte-spa-router"
</script>

<header
  class="fixed left-0 right-0 top-0 z-40 border-b border-[#3a3a3a] bg-[#1a1a1a]/95 backdrop-blur"
>
  <div class="mx-auto flex max-w-lg items-center justify-between px-3 py-3">
    <a use:link href="/" class="text-lg font-semibold text-[#ff8c42]">CODE:BLACK</a>
    <span class="text-xs text-[#a0a0a0]">Bar Shop</span>
  </div>
</header>
