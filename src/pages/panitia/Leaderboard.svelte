<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import type { Database } from '../../lib/types/database.types';
  
  type LeaderboardRow = Database['public']['Views']['leaderboard_view']['Row']
  
  interface CandidateWithScores extends LeaderboardRow {
    scoreStage1: number
    scoreStage2: number
    finalScore: number
    isComplete: boolean
  }
  
  let candidates = $state<CandidateWithScores[]>([]);
  let loading = $state(true);
  let isUpdating = $state(false);
  let realtimeChannel: ReturnType<typeof supabase.channel> | null = null;
  let debounceTimer: ReturnType<typeof setTimeout> | null = null;
  
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
      .order('final_score', { ascending: false });
      
    if (!cErr && candidatesData) {
      candidates = candidatesData.map((c) => ({
        ...c,
        scoreStage1: Number(c.score_stage_1),
        scoreStage2: Number(c.score_stage_2),
        finalScore: Number(c.final_score),
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
  <title>Leaderboard Penyisihan | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <div class="flex items-center gap-3">
          <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Leaderboard Penyisihan (I & II)</h1>
          {#if isUpdating}
            <div class="flex items-center gap-1.5 px-2.5 py-1 bg-green-50 border border-green-200 rounded-full shadow-sm animate-pulse">
              <span class="w-2 h-2 rounded-full bg-green-500 animate-ping"></span>
              <span class="text-[10px] uppercase font-bold text-green-700 tracking-wider">Live Sync</span>
            </div>
          {/if}
        </div>
      </div>
      <div class="flex gap-4">
        <button onclick={() => navigate('/panitia/leaderboard-final')} class="px-6 py-2 rounded-full border border-nawa-accent text-nawa-accent font-medium text-body-sm hover:bg-blue-50 transition-colors active:scale-95">
          Lihat Leaderboard Tahap III →
        </button>
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
                <th class="px-6 py-4 font-medium border-b border-mist text-right">Tahap I</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-right">Tahap II</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-right">Nilai Akhir</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-center">Status</th>
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
                  <td class="px-6 py-4 text-right">
                    <span class="text-body-sm text-graphite">{candidate.scoreStage1.toFixed(2)}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <span class="text-body-sm text-graphite">{candidate.scoreStage2.toFixed(2)}</span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <span class="text-subheading font-serif text-nawa-accent">{candidate.finalScore.toFixed(2)}</span>
                  </td>
                  <td class="px-6 py-4 text-center">
                    {#if candidate.scoreStage1 > 0 && candidate.scoreStage2 > 0}
                      <span class="px-3 py-1 rounded-full text-caption border border-green-200 bg-green-50 text-green-700">Tuntas</span>
                    {:else if candidate.scoreStage1 > 0}
                      <span class="px-3 py-1 rounded-full text-caption border border-yellow-200 bg-yellow-50 text-yellow-700">Menunggu</span>
                    {:else}
                      <span class="px-3 py-1 rounded-full text-caption border border-gray-200 bg-gray-50 text-gray-700">Belum</span>
                    {/if}
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
