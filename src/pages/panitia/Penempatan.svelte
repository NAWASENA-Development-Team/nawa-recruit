<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import { toastStore } from '../../lib/toast.svelte';
  import type { Database } from '../../lib/types/database.types';
  
  type Stage = Database['public']['Tables']['stages']['Row']
  type Room = Database['public']['Tables']['rooms']['Row']
  type Candidate = Database['public']['Tables']['candidates']['Row']
  type CandidateRoomAssignment = Database['public']['Tables']['candidate_room_assignments']['Row']
  
  let stages = $state<Stage[]>([]);
  let rooms = $state<Room[]>([]);
  let candidates = $state<Candidate[]>([]);
  let assignments = $state<CandidateRoomAssignment[]>([]);
  let loading = $state(true);
  
  let selectedStageId = $state('');
  let selectedRoomId = $state('');
  
  let selectedToAssign = $state<string[]>([]);
  let selectedToRemove = $state<string[]>([]);
  
  let isSubmitting = $state(false);
  let searchQuery = $state('');

  async function loadInitialData() {
    loading = true;
    const [stagesRes, roomsRes, candidatesRes] = await Promise.all([
      supabase.from('stages').select('*').order('stage_order'),
      supabase.from('rooms').select('*').order('name'),
      supabase.from('candidates').select('*').order('name')
    ]);

    if (stagesRes.data) stages = stagesRes.data;
    if (roomsRes.data) rooms = roomsRes.data;
    if (candidatesRes.data) candidates = candidatesRes.data;
    
    if (stages.length > 0) selectedStageId = stages[0].id;
    if (rooms.length > 0) selectedRoomId = rooms[0].id;
    
    if (selectedStageId) {
      await loadAssignmentsForStage(selectedStageId);
    }
    loading = false;
  }

  async function loadAssignmentsForStage(stageId: string) {
    const { data, error } = await supabase
      .from('candidate_room_assignments')
      .select('candidate_id, room_id, stage_id')
      .eq('stage_id', stageId);
      
    if (data) assignments = data;
    
    // Reset selections
    selectedToAssign = [];
    selectedToRemove = [];
  }

  // Effect to reload assignments when stage changes
  $effect(() => {
    if (selectedStageId && !loading) {
      loadAssignmentsForStage(selectedStageId);
    }
  });

  // Derived state for the two buckets based on selectedStageId and selectedRoomId
  let unassignedCandidates = $derived(
    candidates.filter(c => {
      // Find if candidate is assigned to ANY room in this stage
      const assignment = assignments.find(a => a.candidate_id === c.id);
      const matchesSearch = c.name.toLowerCase().includes(searchQuery.toLowerCase());
      return !assignment && matchesSearch; // unassigned completely for this stage
    })
  );

  let assignedToCurrentRoom = $derived(
    candidates.filter(c => {
      const assignment = assignments.find(a => a.candidate_id === c.id);
      const matchesSearch = c.name.toLowerCase().includes(searchQuery.toLowerCase());
      return assignment && assignment.room_id === selectedRoomId && matchesSearch;
    })
  );

  let allVisibleSelectedAssign = $derived(
    unassignedCandidates.length > 0 && 
    unassignedCandidates.every(c => selectedToAssign.includes(c.id))
  );

  let allVisibleSelectedRemove = $derived(
    assignedToCurrentRoom.length > 0 && 
    assignedToCurrentRoom.every(c => selectedToRemove.includes(c.id))
  );

  onMount(() => {
    loadInitialData();
  });

  async function assignSelected() {
    if (selectedToAssign.length === 0 || !selectedStageId || !selectedRoomId) return;
    isSubmitting = true;
    
    const inserts = selectedToAssign.map(cId => ({
      candidate_id: cId,
      stage_id: selectedStageId,
      room_id: selectedRoomId
    }));

    const { error } = await supabase
      .from('candidate_room_assignments')
      .upsert(inserts, { onConflict: 'candidate_id,stage_id' });

    if (!error) {
      // Update local state without refetching for speed
      inserts.forEach(ins => assignments.push(ins));
      selectedToAssign = [];
      toastStore.success(`Berhasil mengalokasikan ${inserts.length} kandidat!`);
    } else {
      toastStore.error("Gagal memindahkan: " + error.message);
    }
    isSubmitting = false;
  }

  async function removeSelected() {
    if (selectedToRemove.length === 0 || !selectedStageId || !selectedRoomId) return;
    isSubmitting = true;
    
    // We must delete these rows
    const { error } = await supabase
      .from('candidate_room_assignments')
      .delete()
      .eq('stage_id', selectedStageId)
      .in('candidate_id', selectedToRemove);

    if (!error) {
      // Update local state
      assignments = assignments.filter(a => !(a.stage_id === selectedStageId && selectedToRemove.includes(a.candidate_id)));
      selectedToRemove = [];
      toastStore.success("Berhasil mengeluarkan kandidat dari ruangan.");
    } else {
      toastStore.error("Gagal mengeluarkan: " + error.message);
    }
    isSubmitting = false;
  }
  
  function toggleAssign(id: string, checked: boolean) {
    if (checked) {
      if (!selectedToAssign.includes(id)) selectedToAssign = [...selectedToAssign, id];
    } else {
      selectedToAssign = selectedToAssign.filter(x => x !== id);
    }
  }

  function toggleRemove(id: string, checked: boolean) {
    if (checked) {
      if (!selectedToRemove.includes(id)) selectedToRemove = [...selectedToRemove, id];
    } else {
      selectedToRemove = selectedToRemove.filter(x => x !== id);
    }
  }

  function selectAllToAssign() {
    const visibleIds = unassignedCandidates.map(c => c.id);
    const allVisibleSelected = visibleIds.length > 0 && visibleIds.every(id => selectedToAssign.includes(id));
    
    if (allVisibleSelected) {
      selectedToAssign = selectedToAssign.filter(id => !visibleIds.includes(id));
    } else {
      const newSelections = visibleIds.filter(id => !selectedToAssign.includes(id));
      selectedToAssign = [...selectedToAssign, ...newSelections];
    }
  }
  
  function selectAllToRemove() {
    const visibleIds = assignedToCurrentRoom.map(c => c.id);
    const allVisibleSelected = visibleIds.length > 0 && visibleIds.every(id => selectedToRemove.includes(id));
    
    if (allVisibleSelected) {
      selectedToRemove = selectedToRemove.filter(id => !visibleIds.includes(id));
    } else {
      const newSelections = visibleIds.filter(id => !selectedToRemove.includes(id));
      selectedToRemove = [...selectedToRemove, ...newSelections];
    }
  }
</script>

<svelte:head>
  <title>Alokasi Ruangan | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Alokasi Ruangan</h1>
      </div>
    </header>
    
    <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle mb-8 flex flex-col md:flex-row gap-4">
      <div class="w-full md:w-1/2">
        <label for="stageFilter" class="block text-caption text-charcoal font-medium font-sans mb-2">1. Pilih Tahap Seleksi</label>
        <select 
          id="stageFilter"
          bind:value={selectedStageId}
          class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none"
        >
          {#each stages as stage}
            <option value={stage.id}>{stage.name}</option>
          {/each}
        </select>
      </div>
      
      <div class="w-full md:w-1/2">
        <label for="roomFilter" class="block text-caption text-charcoal font-medium font-sans mb-2">2. Pilih Ruangan (Grup)</label>
        <select 
          id="roomFilter"
          bind:value={selectedRoomId}
          class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none"
        >
          {#each rooms as room}
            <option value={room.id}>{room.name}</option>
          {/each}
        </select>
      </div>
    </div>
    
    {#if !loading && selectedStageId && selectedRoomId}
      <div class="mb-6">
        <input 
          type="text" 
          bind:value={searchQuery} 
          placeholder="Cari nama kandidat..." 
          class="w-full bg-paper border border-mist rounded-xl px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-1 focus:ring-nawa-accent transition-all shadow-subtle"
        />
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
        
        <!-- Left Side: Unassigned -->
        <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden flex flex-col h-[600px]">
          <div class="p-4 border-b border-mist bg-linen/50 flex justify-between items-center">
            <h2 class="text-body-sm text-graphite font-medium">Belum Dialokasikan ({unassignedCandidates.length})</h2>
            <button onclick={selectAllToAssign} class="text-caption text-nawa-accent hover:underline">
              {allVisibleSelectedAssign ? 'Deselect All' : 'Select All'}
            </button>
          </div>
          <div class="overflow-y-auto flex-grow p-2">
            {#if unassignedCandidates.length === 0}
              <div class="p-8 text-center text-ash text-caption">Semua kandidat sudah masuk ruangan.</div>
            {/if}
            {#each unassignedCandidates as candidate}
              <label class="flex items-center gap-3 p-3 hover:bg-linen/50 rounded-lg cursor-pointer border border-transparent hover:border-mist transition-colors">
                <input type="checkbox" checked={selectedToAssign.includes(candidate.id)} onchange={(e) => toggleAssign(candidate.id, e.currentTarget.checked)} class="w-4 h-4 text-nawa-accent border-fog rounded focus:ring-nawa-accent" />
                <div>
                  <div class="text-body-sm text-charcoal font-medium">{candidate.name}</div>
                  <div class="text-caption text-ash">{candidate.class}</div>
                </div>
              </label>
            {/each}
          </div>
          <div class="p-4 border-t border-mist bg-linen/30">
            <button 
              onclick={assignSelected}
              disabled={isSubmitting || selectedToAssign.length === 0}
              class="w-full py-3 rounded-lg bg-twilight text-white font-medium text-body-sm hover:bg-dusk transition-colors disabled:opacity-50 active:scale-[0.98] flex justify-center items-center gap-2"
            >
              Masukkan ke Ruangan <span class="hidden lg:inline">→</span>
              {#if selectedToAssign.length > 0}
                <span class="bg-white/20 px-2 py-0.5 rounded-full text-xs">{selectedToAssign.length}</span>
              {/if}
            </button>
          </div>
        </div>
        
        <!-- Right Side: Assigned -->
        <div class="bg-paper rounded-2xl border border-nawa-accent shadow-subtle overflow-hidden flex flex-col h-[600px]">
          <div class="p-4 border-b border-mist bg-blue-50/30 flex justify-between items-center">
            <h2 class="text-body-sm text-graphite font-medium">Di Ruangan Ini ({assignedToCurrentRoom.length})</h2>
            <button onclick={selectAllToRemove} class="text-caption text-red-500 hover:underline">
              {allVisibleSelectedRemove ? 'Deselect All' : 'Select All'}
            </button>
          </div>
          <div class="overflow-y-auto flex-grow p-2">
            {#if assignedToCurrentRoom.length === 0}
              <div class="p-8 text-center text-ash text-caption">Belum ada kandidat di ruangan ini.</div>
            {/if}
            {#each assignedToCurrentRoom as candidate}
              <label class="flex items-center gap-3 p-3 hover:bg-red-50/50 rounded-lg cursor-pointer border border-transparent hover:border-red-100 transition-colors">
                <input type="checkbox" checked={selectedToRemove.includes(candidate.id)} onchange={(e) => toggleRemove(candidate.id, e.currentTarget.checked)} class="w-4 h-4 text-red-500 border-fog rounded focus:ring-red-500" />
                <div>
                  <div class="text-body-sm text-charcoal font-medium">{candidate.name}</div>
                  <div class="text-caption text-ash">{candidate.class}</div>
                </div>
              </label>
            {/each}
          </div>
          <div class="p-4 border-t border-mist bg-linen/30">
            <button 
              onclick={removeSelected}
              disabled={isSubmitting || selectedToRemove.length === 0}
              class="w-full py-3 rounded-lg border border-red-200 bg-white text-red-600 font-medium text-body-sm hover:bg-red-50 transition-colors disabled:opacity-50 active:scale-[0.98] flex justify-center items-center gap-2"
            >
              <span class="hidden lg:inline">←</span> Keluarkan dari Ruangan
              {#if selectedToRemove.length > 0}
                <span class="bg-red-100 px-2 py-0.5 rounded-full text-xs">{selectedToRemove.length}</span>
              {/if}
            </button>
          </div>
        </div>

      </div>
    {:else if loading}
      <div class="p-12 text-center text-ash text-body-sm">Memuat data...</div>
    {/if}
  </div>
</div>
