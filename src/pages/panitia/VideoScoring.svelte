<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import { toastStore } from '../../lib/toast.svelte';
  import type { Database } from '../../lib/types/database.types';
  
  type Candidate = Database['public']['Tables']['candidates']['Row']
  type VideoScore = Database['public']['Tables']['video_scores']['Row']
  
  interface CandidateWithVideoScore extends Candidate {
    videoScore: number | null
    tempScore: string
  }
  
  let candidates = $state<CandidateWithVideoScore[]>([]);
  let loading = $state(true);
  let isSubmitting = $state(false);
  let searchQuery = $state('');

  let filteredCandidates = $derived(
    candidates.filter(c => 
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.class.toLowerCase().includes(searchQuery.toLowerCase())
    )
  );

  async function loadCandidates() {
    loading = true;
    
    const [candidatesRes, videoScoresRes] = await Promise.all([
      supabase.from('candidates').select('*').order('name'),
      supabase.from('video_scores').select('*')
    ]);

    if (candidatesRes.data) {
      const videoScoreMap = new Map(
        videoScoresRes.data?.map(vs => [vs.candidate_id, vs.score]) || []
      );
      
      candidates = candidatesRes.data.map(c => ({
        ...c,
        videoScore: videoScoreMap.get(c.id) ?? null,
        tempScore: videoScoreMap.get(c.id)?.toString() ?? ''
      }));
    }
    
    loading = false;
  }

  onMount(() => {
    loadCandidates();
  });

  function getGrade(score: number): { letter: string; color: string } {
    if (score >= 96) return { letter: 'S', color: 'text-yellow-600' };
    if (score >= 85) return { letter: 'A', color: 'text-green-600' };
    if (score >= 73) return { letter: 'B', color: 'text-blue-600' };
    if (score >= 63) return { letter: 'C', color: 'text-orange-500' };
    return { letter: 'D/E', color: 'text-red-500' };
  }

  async function saveScore(candidate: CandidateWithVideoScore) {
    const score = parseFloat(candidate.tempScore);
    if (isNaN(score) || score < 0 || score > 100) {
      toastStore.error('Nilai harus antara 0-100');
      return;
    }

    isSubmitting = true;
    
    const { error } = await supabase
      .from('video_scores')
      .upsert({
        candidate_id: candidate.id,
        score: score
      }, { onConflict: 'candidate_id' });

    if (!error) {
      candidates = candidates.map(c => 
        c.id === candidate.id 
          ? { ...c, videoScore: score }
          : c
      );
      toastStore.success(`Nilai video ${candidate.name} berhasil disimpan!`);
    } else {
      toastStore.error('Gagal menyimpan nilai: ' + error.message);
    }
    
    isSubmitting = false;
  }

  async function handleLogout() {
    await supabase.auth.signOut();
    navigate('/');
  }
</script>

<svelte:head>
  <title>Penilaian Video | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Penilaian Video</h1>
        <p class="text-body-sm text-ash mt-1">Berikan nilai untuk video presentasi kandidat.</p>
      </div>
      <button onclick={handleLogout} class="px-5 py-2.5 rounded-xl border border-mist bg-white text-charcoal text-body-sm font-bold hover:border-fog hover:bg-gray-50 active:scale-95 transition-all shadow-sm flex items-center gap-2">
        <svg class="w-4 h-4 text-ash" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path></svg>
        Keluar
      </button>
    </header>

    <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden">
      <div class="p-6 border-b border-mist bg-linen/50">
        <div class="flex flex-col md:flex-row md:justify-between md:items-center gap-4">
          <h2 class="text-subheading text-graphite font-serif">Daftar Kandidat</h2>
          <input 
            type="text" 
            bind:value={searchQuery} 
            placeholder="Cari nama atau kelas..." 
            class="w-full md:w-72 bg-white border border-mist rounded-xl px-4 py-2.5 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-1 focus:ring-nawa-accent transition-all"
          />
        </div>
      </div>

      {#if loading}
        <div class="p-12 text-center text-ash text-body-sm">Memuat data kandidat...</div>
      {:else if filteredCandidates.length === 0}
        <div class="p-12 text-center text-ash text-body-sm">Tidak ada kandidat ditemukan.</div>
      {:else}
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-linen/50 text-ash text-caption">
                <th class="px-6 py-4 font-medium border-b border-mist w-12">No</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Nama</th>
                <th class="px-6 py-4 font-medium border-b border-mist">Kelas</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-center">Nilai Video (0-100)</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-center">Nilai Mutu</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-center">Status</th>
                <th class="px-6 py-4 font-medium border-b border-mist text-right">Aksi</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-mist">
              {#each filteredCandidates as candidate, i}
                {@const grade = candidate.videoScore !== null ? getGrade(candidate.videoScore) : null}
                <tr class="hover:bg-linen/30 transition-colors {candidate.videoScore !== null ? 'bg-green-50/20' : ''}">
                  <td class="px-6 py-4 text-ash font-medium text-center">{i + 1}</td>
                  <td class="px-6 py-4 text-charcoal text-body-sm font-medium">{candidate.name}</td>
                  <td class="px-6 py-4 text-ash text-body-sm">{candidate.class}</td>
                  <td class="px-6 py-4">
                    <div class="flex justify-center">
                      <input 
                        type="number" 
                        inputmode="numeric"
                        min="0"
                        max="100"
                        step="1"
                        placeholder="0-100"
                        bind:value={candidate.tempScore}
                        class="w-24 bg-white border border-mist rounded-lg text-charcoal px-3 py-2 text-center text-body-sm font-bold focus:outline-none focus:border-nawa-accent focus:ring-2 focus:ring-nawa-accent/10 transition-all"
                      />
                    </div>
                  </td>
                  <td class="px-6 py-4 text-center">
                    {#if grade}
                      <span class="inline-flex items-center gap-1">
                        <span class="text-subheading font-serif font-bold {grade.color}">{grade.letter}</span>
                        <span class="text-caption text-ash font-sans font-normal">({candidate.videoScore} pt)</span>
                      </span>
                    {:else}
                      <span class="text-ash/50">-</span>
                    {/if}
                  </td>
                  <td class="px-6 py-4 text-center">
                    {#if candidate.videoScore !== null}
                      <span class="px-3 py-1 rounded-full text-caption border border-green-200 bg-green-50 text-green-700">✓ Terisi</span>
                    {:else}
                      <span class="px-3 py-1 rounded-full text-caption border border-yellow-200 bg-yellow-50 text-yellow-700">Belum</span>
                    {/if}
                  </td>
                  <td class="px-6 py-4 text-right">
                    <button 
                      onclick={() => saveScore(candidate)}
                      disabled={isSubmitting || candidate.tempScore === '' || candidate.tempScore === (candidate.videoScore?.toString() ?? '')}
                      class="px-4 py-2 rounded-lg bg-twilight text-white text-caption font-bold hover:bg-dusk active:scale-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      Simpan
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
