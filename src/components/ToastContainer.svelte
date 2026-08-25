<script lang="ts">
  import { toastStore } from '../lib/toast.svelte';
  import { fly, fade } from 'svelte/transition';
</script>

<div class="fixed top-4 right-4 z-50 flex flex-col gap-2 w-full max-w-sm pointer-events-none px-4 md:px-0">
  {#each toastStore.toasts as toast (toast.id)}
    <div 
      in:fly={{ y: -20, duration: 300 }} 
      out:fade={{ duration: 200 }}
      class={`pointer-events-auto flex items-start gap-3 p-4 rounded-xl shadow-lg border backdrop-blur-sm ${
        toast.type === 'error' ? 'bg-red-50/90 border-red-200 text-red-800' : 
        toast.type === 'success' ? 'bg-green-50/90 border-green-200 text-green-800' : 
        'bg-paper/90 border-mist text-graphite'
      }`}
    >
      <div class="flex-shrink-0 mt-0.5">
        {#if toast.type === 'error'}
          <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        {:else if toast.type === 'success'}
          <svg class="w-5 h-5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        {:else}
          <svg class="w-5 h-5 text-nawa-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        {/if}
      </div>
      <p class="text-body-sm font-medium leading-relaxed flex-grow">{toast.message}</p>
      <button 
        aria-label="Tutup notifikasi"
        onclick={() => toastStore.remove(toast.id)} 
        class="flex-shrink-0 opacity-50 hover:opacity-100 transition-opacity"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
      </button>
    </div>
  {/each}
</div>
