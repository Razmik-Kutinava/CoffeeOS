import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"
import { svelte } from "@sveltejs/vite-plugin-svelte"
import tailwindcss from "@tailwindcss/vite"

const viteWatchPolling =
  process.env.VITE_USE_POLLING === "1" ||
  process.env.VITE_USE_POLLING === "true" ||
  process.cwd().replace(/\\/g, "/").startsWith("/mnt/")

export default defineConfig({
  plugins: [RubyPlugin(), tailwindcss(), svelte()],
  server: {
    watch: viteWatchPolling
      ? { usePolling: true, interval: 800 }
      : undefined
  }
})
