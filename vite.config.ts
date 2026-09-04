import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tailwindcss(),
    svelte(),
  ],
  build: {
    target: 'es2022',
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules/@supabase/supabase-js')) {
            return 'supabase';
          }
          if (id.includes('node_modules/xlsx')) {
            return 'xlsx';
          }
          if (id.includes('node_modules/mammoth')) {
            return 'mammoth';
          }
        },
      },
    },
  },
  server: {
    host: true,
  },
})
