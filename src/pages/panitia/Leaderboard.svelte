<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  
  let candidates = $state<any[]>([]);
  let loading = $state(true);
  let isUpdating = $state(false);
  let realtimeChannel: any;
  let debounceTimer: any;
  
  async function fetchLeaderboard(silent = false) {
    if (!silent) {
      loading = true;
    } else {
      isUpdating = true;
    }
    
    // Langsung ambil data matang dari Database View! Beban 0 di browser.
    const { data: candidatesData, error: cErr } = await supabase
      .from('leaderboard_view')
      .select('*')
      .order('total_score', { ascending: false });
      
    if (!cErr && candidatesData) {
      // Map untuk memastikan totalScore bisa dibaca untyped (meski columnnya total_score)
      candidates = candidatesData.map((c: any) => ({
        ...c,
        totalScore: Number(c.total_score),
        isComplete: c.is_complete
      }));
    }
    
    if (!silent) {
      loading = false;
    } else {
      isUpdating = false;
    }
  }

  function handleRealtimeUpdate() {
    // Gunakan debounce agar tidak spam fetch jika ada insert massal (misal 5 kriteria diisi bersamaan)
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      fetchLeaderboard(true);
    }, 1000);
  }

  onMount(() => {
    fetchLeaderboard();
    
    // Subscribe ke perubahan di tabel scores
    realtimeChannel = supabase.channel('leaderboard-live')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'scores' },
        () => handleRealtimeUpdate()
      )
      .subscribe();
  });
  
  onDestroy(() => {
    if (realtimeChannel) supabase.removeChannel(realtimeChannel);
    clearTimeout(debounceTimer);
  });
</script>

<svelte:head>
  <title>Leaderboard | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <div class="flex items-center gap-3">
          <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Leaderboard & Ranking</h1>
          {#if isUpdating}
            <div class="flex items-center gap-1.5 px-2.5 py-1 bg-green-50 border border-green-200 rounded-full shadow-sm animate-pulse">
              <span class="w-2 h-2 rounded-full bg-green-500 animate-ping"></span>
              <span class="text-[10px] uppercase font-bold text-green-700 tracking-wider">Live Sync</span>
            </div>
          {/if}
        </div>
      </div>
    </header>
    
    <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden">
      {#if loading}
        <div class="p-12 text-center text-ash text-body-sm">Mengkalkulasi ranking...</div>
      {:else if candidates.length === 0}
        <div class="p-12 text-center text-ash text-body-sm">Belum ada data kandidat.</div>
      {:else}
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-linen/50 text-ash text-caption">
                <th class="px-6 py-4 font-medium border-b border-mist w-16 text-center">Rank</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Nama Kandidat</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Kelas</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Status Penilaian</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-right">Skor Total</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-mist">
              {#each candidates as candidate, i}
                <tr class="hover:bg-linen/30 transition-colors">
                  <td class="px-6 py-4 text-center">
                    {#if i === 0}
                      <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-yellow-100 text-yellow-700 font-bold text-body-sm">1</span>
                    {:else if i === 1}
                      <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-gray-100 text-gray-700 font-bold text-body-sm">2</span>
                    {:else if i === 2}
                      <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-orange-50 text-orange-700 font-bold text-body-sm">3</span>
                    {:else}
                      <span class="text-ash font-medium">{i + 1}</span>
                    {/if}
                  </td>
                  <td class="px-6 py-4 text-charcoal text-body-sm font-medium">{candidate.name}</td>
                  <td class="px-6 py-4 text-ash text-body-sm">{candidate.class}</td>
                  <td class="px-6 py-4">
                    {#if candidate.isComplete}
                      <span class="px-3 py-1 rounded-full text-caption border border-green-200 bg-green-50 text-green-700">Lengkap</span>
                    {:else}
                      <span class="px-3 py-1 rounded-full text-caption border border-yellow-200 bg-yellow-50 text-yellow-700">Menunggu</span>
                    {/if}
                  </td>
                  <td class="px-6 py-4 text-right">
                    <span class="text-subheading font-serif text-graphite">{candidate.totalScore.toFixed(2)}</span>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {/if}
    </div>
  </div>
</div>
