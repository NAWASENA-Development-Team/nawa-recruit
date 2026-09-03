<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import { toastStore } from '../../lib/toast.svelte';
  
  let stages = $state<any[]>([]);
  let rooms = $state<any[]>([]);
  let testers = $state<any[]>([]);
  let assignments = $state<any[]>([]);
  let loading = $state(true);
  
  let selectedStageId = $state('');
  let selectedRoomId = $state('');
  let selectedTester1Id = $state('');
  let selectedTester2Id = $state('');
  let isSubmitting = $state(false);

  async function loadData() {
    loading = true;
    
    const [stagesRes, roomsRes, testersRes, assignmentsRes] = await Promise.all([
      supabase.from('stages').select('*').order('stage_order'),
      supabase.from('rooms').select('*').order('name'),
      supabase.from('users').select('*').eq('role', 'penguji').order('name'),
      supabase.from('stage_room_assignments').select(`
        *,
        stage:stages(name),
        room:rooms(name),
        tester1:users!tester_1_id(name),
        tester2:users!tester_2_id(name)
      `).order('created_at', { ascending: false })
    ]);

    if (stagesRes.data) stages = stagesRes.data;
    if (roomsRes.data) rooms = roomsRes.data;
    if (testersRes.data) testers = testersRes.data;
    if (assignmentsRes.data) assignments = assignmentsRes.data;
    
    loading = false;
  }

  onMount(() => {
    loadData();
  });

  async function assignTesters(e: Event) {
    e.preventDefault();
    if (!selectedStageId || !selectedRoomId || !selectedTester1Id || !selectedTester2Id) return;
    
    if (selectedTester1Id === selectedTester2Id) {
      toastStore.error("Penguji tidak boleh orang yang sama di dalam satu ruangan.");
      return;
    }
    
    isSubmitting = true;
    
    const { data, error } = await supabase
      .from('stage_room_assignments')
      .upsert({
        stage_id: selectedStageId,
        room_id: selectedRoomId,
        tester_1_id: selectedTester1Id,
        tester_2_id: selectedTester2Id
      }, { onConflict: 'stage_id,room_id' })
      .select(`
        *,
        stage:stages(name),
        room:rooms(name),
        tester1:users!tester_1_id(name),
        tester2:users!tester_2_id(name)
      `);

    if (!error && data) {
      // Refresh assignments
      assignments = assignments.filter(a => !(a.stage_id === selectedStageId && a.room_id === selectedRoomId));
      assignments = [data[0], ...assignments];
      
      // Reset form but keep stage
      selectedRoomId = '';
      selectedTester1Id = '';
      selectedTester2Id = '';
      toastStore.success('Jadwal penguji berhasil disimpan!');
    } else {
      toastStore.error("Terjadi kesalahan: " + (error?.message || ""));
    }
    isSubmitting = false;
  }
</script>

<svelte:head>
  <title>Jadwal & Penugasan | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Jadwal & Penugasan</h1>
      </div>
    </header>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Form Penugasan -->
      <div class="lg:col-span-1">
        <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle sticky top-8">
          <h2 class="text-subheading text-graphite font-serif mb-6">Assign Penguji</h2>
          
          <form onsubmit={assignTesters} class="space-y-6">
            <div class="space-y-1">
              <label for="stage" class="text-caption text-charcoal font-medium font-sans">Tahap Seleksi</label>
              <select 
                id="stage"
                bind:value={selectedStageId}
                required
                class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none"
              >
                <option value="" disabled>Pilih Tahap</option>
                {#each stages as stage}
                  <option value={stage.id}>{stage.name}</option>
                {/each}
              </select>
            </div>
            
            <div class="space-y-1">
              <label for="room" class="text-caption text-charcoal font-medium font-sans">Ruangan</label>
              <select 
                id="room"
                bind:value={selectedRoomId}
                required
                class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none"
              >
                <option value="" disabled>Pilih Ruangan</option>
                {#each rooms as room}
                  <option value={room.id}>{room.name}</option>
                {/each}
              </select>
            </div>

            <div class="space-y-1">
              <label for="tester1" class="text-caption text-charcoal font-medium font-sans">Penguji 1</label>
              <select 
                id="tester1"
                bind:value={selectedTester1Id}
                required
                class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none"
              >
                <option value="" disabled>Pilih Penguji 1</option>
                {#each testers as tester}
                  <option value={tester.id}>{tester.name}</option>
                {/each}
              </select>
            </div>

            <div class="space-y-1">
              <label for="tester2" class="text-caption text-charcoal font-medium font-sans">Penguji 2</label>
              <select 
                id="tester2"
                bind:value={selectedTester2Id}
                required
                class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none"
              >
                <option value="" disabled>Pilih Penguji 2</option>
                {#each testers as tester}
                  <option value={tester.id}>{tester.name}</option>
                {/each}
              </select>
            </div>
            
            <button 
              type="submit" 
              disabled={isSubmitting}
              class="w-full flex items-center justify-center rounded-lg border border-nawa-accent text-nawa-accent py-3 px-4 font-medium text-body-sm hover:bg-blue-50 transition-colors disabled:opacity-50"
            >
              {isSubmitting ? 'Menyimpan...' : 'Tugaskan Penguji'}
            </button>
          </form>
        </div>
      </div>
      
      <!-- List Penugasan -->
      <div class="lg:col-span-2">
        <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden">
          <div class="p-6 border-b border-mist">
            <h2 class="text-subheading text-graphite font-serif">Data Penugasan Saat Ini</h2>
          </div>
          
          {#if loading}
            <div class="p-8 text-center text-ash text-body-sm">Memuat data...</div>
          {:else if assignments.length === 0}
            <div class="p-12 text-center text-ash text-body-sm">
              Belum ada penugasan penguji.
            </div>
          {:else}
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-linen/50 text-ash text-caption">
                    <th class="px-6 py-4 font-medium border-b border-mist">Tahap</th>
                    <th class="px-6 py-4 font-medium border-b border-mist">Ruangan</th>
                    <th class="px-6 py-4 font-medium border-b border-mist">Penguji Bertugas</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-mist">
                  {#each assignments as assignment}
                    <tr class="hover:bg-linen/30 transition-colors">
                      <td class="px-6 py-4 text-charcoal text-body-sm font-medium">{assignment.stage?.name || '-'}</td>
                      <td class="px-6 py-4 text-charcoal text-body-sm">{assignment.room?.name || '-'}</td>
                      <td class="px-6 py-4 text-body-sm text-ash">
                        <div class="flex flex-col gap-1">
                          <span class="inline-flex items-center gap-2">
                            <span class="w-2 h-2 rounded-full bg-nawa-accent"></span> {assignment.tester1?.name || '-'}
                          </span>
                          <span class="inline-flex items-center gap-2">
                            <span class="w-2 h-2 rounded-full bg-twilight"></span> {assignment.tester2?.name || '-'}
                          </span>
                        </div>
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
  </div>
</div>
