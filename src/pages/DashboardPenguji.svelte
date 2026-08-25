<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../lib/supabase/client';
  import { toastStore } from '../lib/toast.svelte';
  
  let user: any = $state(null);
  let assignments = $state<any[]>([]);
  let candidates = $state<any[]>([]);
  let scoringCriteria = $state<any[]>([]);
  let loading = $state(true);
  
  let selectedCandidate = $state<any>(null);
  let scores = $state<Record<string, number>>({});
  let isSubmitting = $state(false);
  
  let realtimeChannel: any;

  async function loadDashboard() {
    loading = true;
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user) {
      navigate('/');
      return;
    }
    user = session.user;
    
    const { data: myAssignments } = await supabase
      .from('stage_room_assignments')
      .select(`*, stage:stages(id, name), room:rooms(name)`)
      .or(`tester_1_id.eq.${user.id},tester_2_id.eq.${user.id}`);
      
    if (myAssignments && myAssignments.length > 0) {
      assignments = myAssignments;
      const activeAssignment = myAssignments[0];
      
      const { data: criteria } = await supabase
        .from('scoring_criteria')
        .select('*')
        .eq('stage_id', activeAssignment.stage_id);
      if (criteria) scoringCriteria = criteria;
      
      const { data: roomCandidates } = await supabase
        .from('candidate_room_assignments')
        .select(`candidate_id, candidate:candidates(id, name, class)`)
        .eq('stage_id', activeAssignment.stage_id)
        .eq('room_id', activeAssignment.room_id);
      if (roomCandidates) {
        // Filter out candidates that have already been graded in this stage
        // Fetch existing scores for this stage
        const { data: existingScores } = await supabase
          .from('scores')
          .select('candidate_id')
          .eq('stage_id', activeAssignment.stage_id);
          
        const gradedIds = new Set(existingScores?.map(s => s.candidate_id) || []);
        candidates = roomCandidates.map((c: any) => c.candidate).filter(c => !gradedIds.has(c.id));
      }
      
      // Setup Realtime Subscription
      setupRealtime(activeAssignment.stage_id);
    }
    loading = false;
  }
  
  function setupRealtime(stageId: string) {
    realtimeChannel = supabase.channel('scores-updates')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'scores', filter: `stage_id=eq.${stageId}` },
        (payload) => {
          const gradedCandidateId = payload.new.candidate_id;
          
          // Hapus kandidat dari antrean secara reaktif tanpa me-refresh halaman!
          candidates = candidates.filter(c => c.id !== gradedCandidateId);
        }
      )
      .subscribe();
  }

  onMount(() => {
    loadDashboard();
  });
  
  onDestroy(() => {
    if (realtimeChannel) {
      supabase.removeChannel(realtimeChannel);
    }
  });
  
  function selectCandidate(c: any) {
    selectedCandidate = c;
    scores = {};
    scoringCriteria.forEach(crit => {
      scores[crit.id] = 0; // initialize
    });
    // Scroll to top automatically on mobile when a candidate is selected
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function backToList() {
    selectedCandidate = null;
  }

  async function submitScores(e: Event) {
    e.preventDefault();
    if (!selectedCandidate || !assignments[0]) return;
    isSubmitting = true;
    
    const stageId = assignments[0].stage_id;
    const inserts = Object.keys(scores).map(criteriaId => ({
      candidate_id: selectedCandidate.id,
      stage_id: stageId,
      criteria_id: criteriaId,
      scorer_user_id: user.id,
      // @ts-ignore
      score: parseFloat(scores[criteriaId])
    }));
    
    const { error } = await supabase
      .from('scores')
      .upsert(inserts, { onConflict: 'candidate_id,stage_id,criteria_id,scorer_user_id' });
      
    if (!error) {
      toastStore.success('Nilai berhasil disimpan!');
      
      const gradedCandidateId = selectedCandidate.id;
      selectedCandidate = null;
      scores = {};
      
      candidates = candidates.filter(c => c.id !== gradedCandidateId);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      toastStore.error("Gagal menyimpan nilai: " + error.message);
    }
    isSubmitting = false;
  }

  async function handleLogout() {
    await supabase.auth.signOut();
    navigate('/');
  }
</script>

<svelte:head>
  <title>Dashboard Penguji | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-6 md:mb-12">
      <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Ruang Penilaian</h1>
      <button onclick={handleLogout} class="px-3 py-2 md:px-4 rounded-lg border border-twilight text-twilight text-caption md:text-body-sm font-medium hover:bg-gray-50 active:scale-95 transition-transform">
        Keluar
      </button>
    </header>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
      
      <!-- Info & List Kandidat (Sembunyikan di mobile jika sedang menilai) -->
      <div class={`lg:col-span-1 space-y-6 ${selectedCandidate ? 'hidden lg:block' : 'block'}`}>
        {#if assignments.length > 0}
          <div class="bg-paper rounded-2xl p-5 border border-mist shadow-subtle border-t-4 border-t-twilight">
            <h2 class="text-body-sm text-graphite font-serif mb-1">Status Penugasan</h2>
            <div class="space-y-1 text-caption">
              <div class="flex justify-between border-b border-mist pb-1">
                <span class="text-ash">Tahap:</span>
                <span class="font-medium text-charcoal">{assignments[0].stage?.name}</span>
              </div>
              <div class="flex justify-between pt-1">
                <span class="text-ash">Ruangan:</span>
                <span class="font-medium text-charcoal">{assignments[0].room?.name}</span>
              </div>
            </div>
          </div>
          
          <div class="bg-paper rounded-2xl p-5 border border-mist shadow-subtle flex flex-col h-[600px]">
            <h2 class="text-subheading text-graphite font-serif mb-4">Antrean Kandidat</h2>
            
            <div class="overflow-y-auto flex-grow space-y-3 pr-2">
              {#if candidates.length === 0}
                <div class="text-center py-8">
                  <span class="text-2xl opacity-50 mb-2 block">🎉</span>
                  <p class="text-caption text-ash">Semua kandidat sudah dinilai!</p>
                </div>
              {:else}
                {#each candidates as candidate}
                  <button 
                    onclick={() => selectCandidate(candidate)}
                    class={`w-full text-left px-4 py-3 rounded-xl border active:scale-[0.98] transition-all shadow-sm ${selectedCandidate?.id === candidate.id ? 'border-nawa-accent bg-blue-50/50' : 'border-mist hover:border-fog bg-white'}`}
                  >
                    <div class="font-medium text-charcoal text-body-sm">{candidate.name}</div>
                    <div class="text-caption text-ash mt-1">{candidate.class}</div>
                  </button>
                {/each}
              {/if}
            </div>
          </div>
        {:else if !loading}
          <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle">
            <h2 class="text-subheading text-graphite font-serif mb-2">Belum Ada Penugasan</h2>
            <p class="text-caption text-ash">Panitia belum menugaskan Anda ke ruangan manapun pada sesi ini.</p>
          </div>
        {/if}
      </div>
      
      <!-- Panel Input Nilai (Hanya muncul di mobile jika ada kandidat yg dipilih) -->
      <div class={`lg:col-span-2 h-full ${!selectedCandidate ? 'hidden lg:block' : 'block'}`}>
        <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden h-[730px] flex flex-col">
          {#if !selectedCandidate}
            <div class="flex flex-col items-center justify-center h-full p-12 text-center text-ash min-h-[400px]">
              <div class="w-16 h-16 rounded-full bg-linen flex items-center justify-center mb-4">
                <span class="text-2xl opacity-50">📋</span>
              </div>
              <h2 class="text-subheading text-graphite font-serif mb-2">Lembar Penilaian CBT</h2>
              <p class="text-body-sm">Pilih kandidat dari daftar untuk mulai memberikan nilai.</p>
            </div>
          {:else}
            <!-- Header Panel -->
            <div class="p-5 md:p-6 border-b border-mist bg-linen/30 flex-shrink-0 z-10 shadow-sm">
              <button onclick={backToList} class="lg:hidden mb-4 text-nawa-accent text-caption font-medium inline-flex items-center active:scale-95 transition-transform">
                ← Kembali ke Antrean
              </button>
              <div class="flex justify-between items-start gap-4">
                <div>
                  <h2 class="text-heading-sm text-graphite font-serif mb-1 leading-tight">{selectedCandidate.name}</h2>
                  <p class="text-caption text-ash">{selectedCandidate.class}</p>
                </div>
                <span class="px-3 py-1 rounded-full text-caption border border-nawa-accent text-nawa-accent bg-white flex-shrink-0">
                  Sedang Dinilai
                </span>
              </div>
            </div>
            
            <form onsubmit={submitScores} class="flex-grow flex flex-col overflow-hidden">
              <div class="p-5 md:p-6 flex-grow overflow-y-auto space-y-8 bg-white">
                {#if scoringCriteria.length === 0}
                  <div class="bg-yellow-50 text-yellow-700 p-4 rounded-lg text-body-sm">
                    Panitia belum menentukan soal untuk tahap ini.
                  </div>
                {:else}
                  {#each scoringCriteria as criteria, i}
                    <div class="bg-parchment/30 p-6 rounded-2xl border border-mist shadow-sm">
                      <div class="flex gap-4 items-start mb-6">
                        <div class="w-8 h-8 rounded-full bg-twilight text-white flex items-center justify-center font-serif text-body-sm flex-shrink-0 mt-0.5">
                          {i + 1}
                        </div>
                        <div class="text-body-sm text-charcoal font-medium leading-relaxed whitespace-pre-wrap flex-grow">
                          {criteria.name}
                        </div>
                      </div>
                      
                      <div class="ml-12 pl-4 border-l-2 border-nawa-accent/20 flex flex-col sm:flex-row items-center gap-4">
                        <div class="w-full sm:w-32 relative">
                          <input 
                            id={`crit-${criteria.id}`}
                            type="number" 
                            min="0"
                            max="100"
                            step="1"
                            placeholder="0-100"
                            bind:value={scores[criteria.id]}
                            required
                            class="w-full bg-white border border-mist rounded-xl text-charcoal px-4 py-3 pr-12 text-subheading font-medium focus:outline-none focus:border-nawa-accent focus:ring-1 focus:ring-nawa-accent transition-all shadow-inner"
                          />
                          <span class="absolute right-4 top-1/2 -translate-y-1/2 text-caption text-ash font-medium">Pt</span>
                        </div>
                        
                        <div class="w-full sm:w-auto px-4 py-3 rounded-xl border border-mist bg-linen/50 flex items-center gap-3 shadow-subtle-2">
                          <span class="text-caption text-ash">Nilai Mutu:</span>
                          <span class="text-subheading font-serif font-bold text-graphite">
                            {#if scores[criteria.id] >= 96} <span class="text-yellow-600">S</span> (Khusus)
                            {:else if scores[criteria.id] >= 85} <span class="text-green-600">A</span>
                            {:else if scores[criteria.id] >= 73} <span class="text-blue-600">B</span>
                            {:else if scores[criteria.id] >= 63} <span class="text-orange-500">C</span>
                            {:else} <span class="text-red-500">D/E</span>
                            {/if}
                          </span>
                        </div>
                      </div>
                    </div>
                  {/each}
                {/if}
              </div>
              
              <div class="p-5 md:p-6 border-t border-mist bg-linen/30 flex-shrink-0">
                <button 
                  type="submit" 
                  disabled={isSubmitting || scoringCriteria.length === 0}
                  class="w-full flex items-center justify-center rounded-xl bg-twilight text-white py-4 font-medium text-body-sm hover:bg-dusk active:scale-[0.98] transition-all shadow-sm disabled:opacity-50"
                >
                  {isSubmitting ? 'Menyimpan...' : 'Kirim Lembar Penilaian'}
                </button>
              </div>
            </form>
          {/if}
        </div>
      </div>
    </div>
  </div>
</div>
