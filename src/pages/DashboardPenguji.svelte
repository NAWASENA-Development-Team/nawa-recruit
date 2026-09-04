<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../lib/supabase/client';
  import { toastStore } from '../lib/toast.svelte';
  import type { Database } from '../lib/types/database.types';
  
  type StageRoomAssignment = Database['public']['Tables']['stage_room_assignments']['Row'] & {
    stage: Database['public']['Tables']['stages']['Row'] | null
    room: Database['public']['Tables']['rooms']['Row'] | null
  }
  type ScoringCriteria = Database['public']['Tables']['scoring_criteria']['Row']
  type Candidate = Database['public']['Tables']['candidates']['Row']
  
  let user: { id: string; email?: string } | null = $state(null);
  let assignments = $state<StageRoomAssignment[]>([]);
  let candidates = $state<Candidate[]>([]);
  let scoringCriteria = $state<ScoringCriteria[]>([]);
  let loading = $state(true);
  
  let selectedCandidate = $state<Candidate | null>(null);
  let scores = $state<Record<string, number | string>>({});
  let isSubmitting = $state(false);
  
  let isAllScoresFilled = $derived(
    scoringCriteria.length > 0 &&
    scoringCriteria.every(crit => scores[crit.id] !== '' && scores[crit.id] !== null && scores[crit.id] !== undefined)
  );
  
  let realtimeChannel: ReturnType<typeof supabase.channel> | null = null;

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
        const { data: existingScores } = await supabase
          .from('scores')
          .select('candidate_id')
          .eq('stage_id', activeAssignment.stage_id);
          
        const gradedIds = new Set(existingScores?.map(s => s.candidate_id) || []);
        candidates = roomCandidates
          .map((c) => c.candidate as unknown as Candidate)
          .filter((c): c is Candidate => c !== null && !gradedIds.has(c.id));
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
  
  function selectCandidate(c: Candidate) {
    selectedCandidate = c;
    scores = {};
    scoringCriteria.forEach(crit => {
      scores[crit.id] = '';
    });
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
      score: parseFloat(String(scores[criteriaId]))
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

<div class="min-h-screen bg-parchment p-3 sm:p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-6 md:mb-10">
      <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Ruang Penilaian</h1>
      <button onclick={handleLogout} class="px-3 py-2 md:px-5 md:py-2.5 rounded-xl border border-twilight text-twilight text-caption md:text-body-sm font-medium hover:bg-twilight hover:text-white active:scale-95 transition-all shadow-sm">
        Keluar
      </button>
    </header>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
      
      <!-- Info & List Kandidat (Sembunyikan di mobile jika sedang menilai) -->
      <div class={`lg:col-span-1 space-y-5 md:space-y-6 ${selectedCandidate ? 'hidden lg:block' : 'block'}`}>
        {#if assignments.length > 0}
          <div class="bg-paper rounded-2xl p-5 border border-mist shadow-sm border-t-4 border-t-nawa-accent relative overflow-hidden">
            <!-- Decorative background element -->
            <div class="absolute -right-6 -top-6 w-24 h-24 bg-blue-50 rounded-full opacity-50 pointer-events-none"></div>
            
            <h2 class="text-body-sm text-graphite font-bold mb-3 relative z-10">Informasi Sesi</h2>
            <div class="space-y-2.5 text-caption relative z-10">
              <div class="flex items-center justify-between border-b border-mist/60 pb-2">
                <span class="text-ash flex items-center gap-1.5">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                  Tahap
                </span>
                <span class="font-bold text-charcoal">{assignments[0].stage?.name}</span>
              </div>
              <div class="flex items-center justify-between pt-0.5">
                <span class="text-ash flex items-center gap-1.5">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                  Ruangan
                </span>
                <span class="font-bold text-charcoal bg-linen px-2 py-0.5 rounded border border-mist">{assignments[0].room?.name}</span>
              </div>
            </div>
          </div>
          
          <div class="bg-paper rounded-2xl p-0 md:p-5 border border-mist shadow-sm flex flex-col h-[calc(100vh-220px)] lg:h-[600px] overflow-hidden">
            <div class="p-5 md:p-0 pb-3 md:pb-4 border-b border-mist md:border-0 bg-linen/50 md:bg-transparent">
              <h2 class="text-subheading text-graphite font-serif flex items-center gap-2">
                Antrean Kandidat
                <span class="px-2 py-0.5 rounded-full bg-blue-50 text-nawa-accent text-[11px] font-bold border border-blue-100">{candidates.length}</span>
              </h2>
            </div>
            
            <div class="overflow-y-auto flex-grow p-4 md:p-0 md:pr-2 space-y-3 bg-white md:bg-transparent">
              {#if candidates.length === 0}
                <div class="flex flex-col items-center justify-center h-full text-center p-6">
                  <div class="w-16 h-16 bg-green-50 rounded-full flex items-center justify-center mb-4">
                    <svg class="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                  </div>
                  <h3 class="text-body-sm font-bold text-graphite mb-1">Tugas Selesai!</h3>
                  <p class="text-caption text-ash">Semua kandidat di ruangan ini sudah Anda nilai.</p>
                </div>
              {:else}
                {#each candidates as candidate (candidate.id)}
                  <button 
                    onclick={() => selectCandidate(candidate)}
                    class={`group w-full flex items-center justify-between text-left px-4 py-3.5 rounded-xl border active:scale-[0.98] transition-all ${selectedCandidate?.id === candidate.id ? 'border-nawa-accent bg-blue-50/40 ring-1 ring-nawa-accent/20 shadow-sm' : 'border-mist hover:border-fog bg-white hover:shadow-subtle'}`}
                  >
                    <div>
                      <div class="font-bold text-charcoal text-body-sm group-hover:text-nawa-accent transition-colors">{candidate.name}</div>
                      <div class="text-caption text-ash mt-0.5 flex items-center gap-1.5">
                        <svg class="w-3.5 h-3.5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"></path></svg>
                        {candidate.class}
                      </div>
                    </div>
                    <div class={`transition-transform ${selectedCandidate?.id === candidate.id ? 'text-nawa-accent translate-x-1' : 'text-mist group-hover:text-nawa-accent group-hover:translate-x-1'}`}>
                      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                    </div>
                  </button>
                {/each}
              {/if}
            </div>
          </div>
        {:else if !loading}
          <div class="bg-paper rounded-2xl p-8 border border-mist shadow-sm text-center">
            <div class="w-16 h-16 bg-linen rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-ash" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            </div>
            <h2 class="text-subheading text-graphite font-serif mb-2">Belum Ada Penugasan</h2>
            <p class="text-caption text-ash">Panitia belum menugaskan Anda ke ruangan manapun pada sesi ini. Silakan hubungi panitia.</p>
          </div>
        {/if}
      </div>
      
      <!-- Panel Input Nilai (Hanya muncul di mobile jika ada kandidat yg dipilih) -->
      <div class={`lg:col-span-2 h-full ${!selectedCandidate ? 'hidden lg:block' : 'block'}`}>
        <div class="bg-paper rounded-2xl border border-mist shadow-sm overflow-hidden h-[calc(100vh-120px)] lg:h-[750px] flex flex-col">
          {#if !selectedCandidate}
            <div class="flex flex-col items-center justify-center h-full p-12 text-center text-ash bg-linen/20">
              <div class="w-20 h-20 rounded-full bg-white shadow-sm border border-mist flex items-center justify-center mb-6">
                <svg class="w-10 h-10 text-fog" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
              </div>
              <h2 class="text-subheading text-graphite font-serif mb-2">Lembar Penilaian CBT</h2>
              <p class="text-body-sm max-w-xs mx-auto">Pilih kandidat dari daftar antrean di sebelah kiri untuk mulai memberikan nilai.</p>
            </div>
          {:else}
            <!-- Header Panel -->
            <div class="p-4 md:p-6 border-b border-mist bg-white flex-shrink-0 z-10 shadow-sm relative">
              <!-- Mobile Back Button -->
              <button onclick={backToList} class="lg:hidden mb-4 text-charcoal hover:text-nawa-accent text-caption font-bold inline-flex items-center active:scale-95 transition-all bg-linen px-3.5 py-2 rounded-lg border border-mist shadow-sm">
                <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
                Kembali ke Antrean
              </button>
              
              <div class="flex justify-between items-start gap-4">
                <div>
                  <h2 class="text-heading-sm text-graphite font-serif mb-2 leading-tight">{selectedCandidate.name}</h2>
                  <div class="inline-flex items-center px-2.5 py-1 rounded-md bg-linen border border-mist text-caption text-ash font-medium">
                    <svg class="w-3.5 h-3.5 mr-1.5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"></path></svg>
                    Kelas {selectedCandidate.class}
                  </div>
                </div>
                <span class="px-3 py-1.5 rounded-full text-[11px] uppercase tracking-wider font-bold border border-nawa-accent text-nawa-accent bg-blue-50 flex-shrink-0 shadow-sm flex items-center gap-1.5">
                  <span class="w-1.5 h-1.5 rounded-full bg-nawa-accent animate-pulse"></span>
                  Proses Nilai
                </span>
              </div>
            </div>
            
            <form onsubmit={submitScores} class="flex-grow flex flex-col overflow-hidden bg-linen/20">
              <div class="p-4 md:p-6 flex-grow overflow-y-auto space-y-6 md:space-y-8">
                {#if scoringCriteria.length === 0}
                  <div class="bg-yellow-50 text-yellow-700 p-5 rounded-xl text-body-sm border border-yellow-200 flex items-start gap-3">
                    <svg class="w-5 h-5 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                    <div>
                      <p class="font-bold mb-1">Kriteria Belum Diatur</p>
                      <p class="text-caption opacity-90">Panitia belum menentukan komponen soal/kriteria untuk tahap ini. Anda tidak bisa memberikan nilai.</p>
                    </div>
                  </div>
                {:else}
                  {#each scoringCriteria as criteria, i}
                    <div class="bg-white p-5 md:p-6 rounded-2xl border border-mist shadow-sm relative overflow-hidden transition-all hover:shadow-md">
                      <!-- Left indicator accent -->
                      <div class="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-nawa-accent/40 to-transparent"></div>
                      
                      <div class="flex gap-3 md:gap-4 items-start mb-5 md:mb-6">
                        <div class="w-7 h-7 md:w-8 md:h-8 rounded-full bg-twilight text-white flex items-center justify-center font-bold text-caption md:text-body-sm flex-shrink-0 shadow-sm mt-0.5">
                          {i + 1}
                        </div>
                        <div class="text-body-sm text-charcoal font-medium leading-relaxed whitespace-pre-wrap flex-grow">
                          {criteria.name}
                        </div>
                      </div>
                      
                      <div class="ml-10 md:ml-12 flex flex-col sm:flex-row items-stretch sm:items-center gap-3 md:gap-4">
                        <div class="w-full sm:w-36 relative group">
                          <input 
                            id={`crit-${criteria.id}`}
                            type="number" 
                            inputmode="numeric"
                            min="0"
                            max="100"
                            step="1"
                            placeholder="0-100"
                            bind:value={scores[criteria.id]}
                            required
                            class="w-full bg-white border border-mist rounded-xl text-charcoal px-4 py-3.5 pr-12 text-subheading font-bold focus:outline-none focus:border-nawa-accent focus:ring-4 focus:ring-nawa-accent/10 transition-all shadow-inner hover:border-fog"
                          />
                          <span class="absolute right-4 top-1/2 -translate-y-1/2 text-caption text-ash font-medium pointer-events-none group-focus-within:text-nawa-accent transition-colors">Pt</span>
                        </div>
                        
                        <div class="w-full sm:w-auto px-5 py-3.5 rounded-xl border border-mist bg-linen flex items-center justify-between sm:justify-start gap-3 shadow-sm flex-grow sm:flex-grow-0">
                          <span class="text-caption font-medium text-ash uppercase tracking-wider text-[10px]">Nilai Mutu</span>
                          <span class="text-subheading font-serif font-bold text-graphite">
                            {#if scores[criteria.id] === '' || scores[criteria.id] === undefined} <span class="text-ash/50">-</span>
                            {:else if scores[criteria.id] >= 96} <span class="text-yellow-600">S</span> <span class="text-caption text-yellow-600/70 font-sans font-normal">(Khusus)</span>
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
              
              <div class="p-4 md:p-6 border-t border-mist bg-white flex-shrink-0 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)] relative z-20">
                <button 
                  type="submit" 
                  disabled={isSubmitting || !isAllScoresFilled}
                  class="w-full flex items-center justify-center gap-2 rounded-xl bg-twilight text-white py-4 font-bold text-body-sm hover:bg-dusk active:scale-[0.98] transition-all shadow-md disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100 disabled:shadow-none"
                >
                  {#if isSubmitting}
                    <svg class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Menyimpan Nilai...
                  {:else}
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                    Kirim Lembar Penilaian
                  {/if}
                </button>
                {#if !isAllScoresFilled && scoringCriteria.length > 0}
                  <p class="text-center text-[11px] text-red-500 font-medium mt-3">⚠️ Harap isi semua nilai (0-100) sebelum mengirim.</p>
                {/if}
              </div>
            </form>
          {/if}
        </div>
      </div>
    </div>
  </div>
</div>
