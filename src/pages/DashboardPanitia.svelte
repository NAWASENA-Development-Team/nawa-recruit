<script lang="ts">
  import { navigate } from 'svelte-routing';
  import { supabase } from '../lib/supabase/client';
  
  async function handleLogout() {
    await supabase.auth.signOut();
    navigate('/');
  }
</script>

<svelte:head>
  <title>Dashboard Panitia | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-8 md:mb-12">
      <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Dashboard Panitia</h1>
      <button onclick={handleLogout} class="px-3 py-2 md:px-4 rounded-lg border border-twilight text-twilight text-caption md:text-body-sm font-medium hover:bg-gray-50 active:scale-95 transition-transform">
        Keluar
      </button>
    </header>
    
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <!-- Manajemen Kandidat -->
      <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle flex flex-col h-full">
        <h2 class="text-subheading text-graphite font-serif mb-2">Manajemen Kandidat</h2>
        <p class="text-caption text-ash mb-6 flex-grow">Kelola data peserta oprec.</p>
        <button onclick={() => navigate('/panitia/kandidat')} class="w-full text-center rounded-lg border border-nawa-accent text-nawa-accent py-2 px-4 font-medium text-body-sm hover:bg-blue-50 active:scale-95 transition-all">
          Buka Data →
        </button>
      </div>
      
      <!-- Bank Soal -->
      <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle flex flex-col h-full">
        <h2 class="text-subheading text-graphite font-serif mb-2">Bank Soal (CBT)</h2>
        <p class="text-caption text-ash mb-6 flex-grow">Kelola soal atau import file Word.</p>
        <button onclick={() => navigate('/panitia/soal')} class="w-full text-center rounded-lg border border-nawa-accent text-nawa-accent py-2 px-4 font-medium text-body-sm hover:bg-blue-50 active:scale-95 transition-all">
          Kelola Soal →
        </button>
      </div>

      <!-- Penempatan Kandidat -->
      <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle flex flex-col h-full">
        <h2 class="text-subheading text-graphite font-serif mb-2">Alokasi Ruangan</h2>
        <p class="text-caption text-ash mb-6 flex-grow">Arahkan kandidat ke ruangan per tahap.</p>
        <button onclick={() => navigate('/panitia/penempatan')} class="w-full text-center rounded-lg border border-nawa-accent text-nawa-accent py-2 px-4 font-medium text-body-sm hover:bg-blue-50 transition-colors">
          Atur Penempatan →
        </button>
      </div>

      <!-- Jadwal & Ruangan -->
      <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle flex flex-col h-full">
        <h2 class="text-subheading text-graphite font-serif mb-2">Jadwal & Ruangan</h2>
        <p class="text-caption text-ash mb-6 flex-grow">Atur rotasi penguji.</p>
        <button onclick={() => navigate('/panitia/jadwal')} class="w-full text-center rounded-lg border border-nawa-accent text-nawa-accent py-2 px-4 font-medium text-body-sm hover:bg-blue-50 transition-colors">
          Atur Penugasan →
        </button>
      </div>

      <!-- Leaderboard -->
      <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle border-t-4 border-t-nawa-accent flex flex-col h-full">
        <h2 class="text-subheading text-graphite font-serif mb-2">Leaderboard</h2>
        <p class="text-caption text-ash mb-6 flex-grow">Pantau ranking live.</p>
        <button onclick={() => navigate('/panitia/leaderboard')} class="w-full text-center rounded-lg border border-twilight bg-twilight text-white py-2 px-4 font-medium text-body-sm hover:bg-dusk transition-colors">
          Lihat Ranking →
        </button>
      </div>
    </div>
  </div>
</div>
