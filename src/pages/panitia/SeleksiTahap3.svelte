<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import { toastStore } from '../../lib/toast.svelte';
  import type { Database } from '../../lib/types/database.types';
  
  type LeaderboardRow = Database['public']['Views']['leaderboard_view']['Row']
  
  interface CandidateWithEligibility extends LeaderboardRow {
    finalScore: number
    isEligible: boolean
  }
  
  let candidates = $state<CandidateWithEligibility[]>([]);
  let loading = $state(true);
  
  async function loadCandidates() {
    loading = true;
    
    // Ambil data dari leaderboard penyisihan untuk melihat nilai
    const { data: leaderboardData, error: lErr } = await supabase
      .from('leaderboard_view')
      .select('*')
      .order('final_score', { ascending: false });
      
    // Ambil data is_eligible_stage_3 dari tabel candidates asli
    const { data: candidatesData, error: cErr } = await supabase
      .from('candidates')
      .select('id, is_eligible_stage_3');
      
    if (!lErr && !cErr && leaderboardData && candidatesData) {
      // Gabungkan data
      const eligibilityMap = new Map(candidatesData.map(c => [c.id, c.is_eligible_stage_3]));
      
      candidates = leaderboardData.map((c) => ({
        ...c,
        finalScore: Number(c.final_score),
        isEligible: eligibilityMap.get(c.id) || false
      }));
    } else {
      toastStore.error("Gagal memuat data kandidat");
    }
    
    loading = false;
  }
  
  async function toggleEligibility(candidateId: string, currentStatus: boolean) {
    const newStatus = !currentStatus;
    
    // Optimistic UI update
    candidates = candidates.map(c => 
      c.id === candidateId ? { ...c, isEligible: newStatus } : c
    );
    
    const { error } = await supabase
      .from('candidates')
      .update({ is_eligible_stage_3: newStatus })
      .eq('id', candidateId);
      
    if (error) {
      // Revert on error
      candidates = candidates.map(c => 
        c.id === candidateId ? { ...c, isEligible: currentStatus } : c
      );
      toastStore.error("Gagal mengubah status kelayakan: " + error.message);
    } else {
      if (newStatus) {
        toastStore.success("Kandidat ditambahkan ke Tahap III");
      } else {
        toastStore.success("Kandidat dihapus dari Tahap III");
      }
    }
  }

  onMount(() => {
    loadCandidates();
  });
</script>

<svelte:head>
  <title>Seleksi Tahap III | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Seleksi Kelayakan Tahap III</h1>
        <p class="text-body-sm text-ash mt-1">Tentukan kandidat dari penyisihan yang berhak lanjut ke Tahap III.</p>
      </div>
    </header>
    
    <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden">
      {#if loading}
        <div class="p-12 text-center text-ash text-body-sm">Memuat data kandidat...</div>
      {:else if candidates.length === 0}
        <div class="p-12 text-center text-ash text-body-sm">Belum ada data kandidat dari tahap penyisihan.</div>
      {:else}
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-linen/50 text-ash text-caption">
                <th class="px-6 py-4 font-medium border-b border-mist">Rank</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Nama Kandidat</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Kelas</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-right">Nilai Akhir Penyisihan</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-center">Status Lanjut Tahap III</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-mist">
              {#each candidates as candidate, i}
                <tr class="hover:bg-linen/30 transition-colors {candidate.isEligible ? 'bg-green-50/20' : ''}">
                  <td class="px-6 py-4 text-ash font-medium text-center w-16">{i + 1}</td>
                  <td class="px-6 py-4 text-charcoal text-body-sm font-medium">{candidate.name}</td>
                  <td class="px-6 py-4 text-ash text-body-sm">{candidate.class}</td>
                  <td class="px-6 py-4 text-right">
                    <span class="text-subheading font-serif text-nawa-accent">{candidate.finalScore.toFixed(2)}</span>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <button 
                      onclick={() => toggleEligibility(candidate.id, candidate.isEligible)}
                      class={`px-4 py-1.5 rounded-full text-caption font-medium border active:scale-95 transition-all ${
                        candidate.isEligible 
                          ? 'border-green-300 bg-green-100 text-green-700 hover:bg-green-200' 
                          : 'border-mist bg-white text-ash hover:bg-gray-50'
                      }`}
                    >
                      {candidate.isEligible ? '✓ Lanjut Tahap III' : '+ Tambah ke Tahap III'}
                    </button>
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
