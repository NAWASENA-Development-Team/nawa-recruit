<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import { toastStore } from '../../lib/toast.svelte';
  import type { Database } from '../../lib/types/database.types';
  
  type Stage = Database['public']['Tables']['stages']['Row']
  type ScoringCriteria = Database['public']['Tables']['scoring_criteria']['Row']
  
  let stages = $state<Stage[]>([]);
  let scoringCriteria = $state<ScoringCriteria[]>([]);
  let loading = $state(true);
  
  let selectedStageId = $state('');
  
  let newQuestion = $state('');
  let isSubmitting = $state(false);
  let isImporting = $state(false);

  async function loadInitialData() {
    loading = true;
    const { data: stagesRes } = await supabase.from('stages').select('*').order('stage_order');
    if (stagesRes) stages = stagesRes;
    
    if (stages.length > 0) {
      selectedStageId = stages[0].id;
      await loadQuestions(selectedStageId);
    }
    loading = false;
  }

  async function loadQuestions(stageId: string) {
    const { data } = await supabase
      .from('scoring_criteria')
      .select('*')
      .eq('stage_id', stageId)
      .order('created_at');
    if (data) scoringCriteria = data;
  }

  $effect(() => {
    if (selectedStageId && !loading) {
      loadQuestions(selectedStageId);
    }
  });

  onMount(() => {
    loadInitialData();
  });

  async function addQuestion(e: Event) {
    e.preventDefault();
    if (!newQuestion.trim() || !selectedStageId) return;
    
    isSubmitting = true;
    const { data, error } = await supabase
      .from('scoring_criteria')
      .insert([{ 
        stage_id: selectedStageId, 
        name: newQuestion.trim(), 
        weight: 1 // Default weight, not strictly used in CBT if we just sum them
      }])
      .select();

    if (!error && data) {
      scoringCriteria = [...scoringCriteria, data[0]];
      newQuestion = '';
      toastStore.success('Berhasil menambahkan soal!');
    } else {
      toastStore.error("Gagal menambahkan soal: " + error?.message);
    }
    isSubmitting = false;
  }

  async function deleteQuestion(id: string) {
    if (!confirm('Hapus soal ini?')) return;
    const { error } = await supabase.from('scoring_criteria').delete().eq('id', id);
    if (!error) {
      scoringCriteria = scoringCriteria.filter(q => q.id !== id);
    }
  }

  async function handleImportDocx(e: Event) {
    const target = e.target as HTMLInputElement;
    const file = target.files?.[0];
    if (!file || !selectedStageId) return;

    isImporting = true;
    try {
      // @ts-ignore
      const mammoth = (await import('mammoth/mammoth.browser.js')).default || (await import('mammoth')).default || await import('mammoth');
      const arrayBuffer = await file.arrayBuffer();
      
      // Extract raw text
      const result = await mammoth.extractRawText({ arrayBuffer });
      const text = result.value;
      
      // Split by newline and filter empty
      const lines = text.split('\n')
        .map((line) => line.trim())
        .filter((line) => line.length > 3);

      if (lines.length === 0) {
        toastStore.error("Tidak ada soal yang terdeteksi di dokumen Word.");
        isImporting = false;
        target.value = '';
        return;
      }

      const inserts = lines.map((q) => ({
        stage_id: selectedStageId,
        name: q,
        weight: 1
      }));

      const { data, error } = await supabase
        .from('scoring_criteria')
        .insert(inserts)
        .select();

      if (!error && data) {
        toastStore.success(`Berhasil mengimpor ${data.length} soal!`);
        scoringCriteria = [...scoringCriteria, ...data];
      } else {
        toastStore.error("Gagal mengimpor: " + error?.message);
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      toastStore.error("Gagal membaca file Word (.docx). Error: " + message);
    }
    
    isImporting = false;
    target.value = '';
  }
</script>

<svelte:head>
  <title>Bank Soal | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Bank Soal (CBT)</h1>
      </div>
    </header>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      
      <!-- Sidebar Form -->
      <div class="lg:col-span-1 space-y-6">
        <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle sticky top-8">
          <label for="stageFilter" class="block text-subheading text-graphite font-serif mb-4">Pilih Tahap</label>
          <select 
            id="stageFilter"
            bind:value={selectedStageId}
            class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors appearance-none mb-6"
          >
            {#each stages as stage}
              <option value={stage.id}>{stage.name}</option>
            {/each}
          </select>
          
          <h2 class="text-subheading text-graphite font-serif mb-4">Tambah Soal Manual</h2>
          <form onsubmit={addQuestion} class="space-y-4">
            <textarea 
              bind:value={newQuestion}
              required
              rows="4"
              placeholder="Tuliskan pertanyaan / soal di sini..."
              class="w-full bg-linen border border-mist rounded-lg text-charcoal p-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-1 focus:ring-nawa-accent transition-all resize-none"
            ></textarea>
            
            <button 
              type="submit" 
              disabled={isSubmitting || !selectedStageId}
              class="w-full flex items-center justify-center rounded-lg border border-nawa-accent text-nawa-accent py-3 px-4 font-medium text-body-sm hover:bg-blue-50 transition-colors disabled:opacity-50 active:scale-[0.98]"
            >
              {isSubmitting ? 'Menyimpan...' : 'Tambah Soal'}
            </button>
          </form>

          <!-- Divider -->
          <div class="relative my-6">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-mist"></div>
            </div>
            <div class="relative flex justify-center text-caption">
              <span class="bg-paper px-2 text-ash">Atau Impor Massal</span>
            </div>
          </div>
          
          <!-- Tombol Import DOCX -->
          <div class="space-y-2">
            <label 
              for="word-upload"
              class={`w-full flex items-center justify-center gap-2 rounded-lg bg-linen text-charcoal border border-fog border-dashed py-3 px-4 font-medium text-body-sm cursor-pointer hover:bg-white hover:border-nawa-accent transition-colors active:scale-[0.98] ${isImporting ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              <span>📝</span>
              <span>{isImporting ? 'Memproses...' : 'Impor dari Word (.docx)'}</span>
            </label>
            <input 
              id="word-upload"
              type="file" 
              accept=".docx, application/vnd.openxmlformats-officedocument.wordprocessingml.document"
              onchange={handleImportDocx}
              disabled={isImporting || !selectedStageId}
              class="hidden"
            />
            <p class="text-xs text-ash text-center mt-1">Setiap paragraf baru akan menjadi 1 soal terpisah.</p>
          </div>
        </div>
      </div>
      
      <!-- List Soal -->
      <div class="lg:col-span-2">
        <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden min-h-[500px] flex flex-col">
          <div class="p-6 border-b border-mist bg-linen/50">
            <h2 class="text-subheading text-graphite font-serif">Daftar Soal</h2>
          </div>
          
          <div class="p-6 space-y-4 flex-grow bg-white">
            {#if loading}
              <div class="text-center text-ash text-body-sm py-12">Memuat soal...</div>
            {:else if scoringCriteria.length === 0}
              <div class="text-center text-ash text-body-sm py-12">Belum ada soal untuk tahap ini.</div>
            {:else}
              {#each scoringCriteria as soal, i}
                <div class="p-4 border border-mist rounded-xl bg-linen/30 flex gap-4 hover:border-fog transition-colors group">
                  <div class="font-serif text-ash font-medium text-body-sm pt-0.5">{i + 1}.</div>
                  <div class="flex-grow text-body-sm text-charcoal">{soal.name}</div>
                  <button 
                    onclick={() => deleteQuestion(soal.id)}
                    class="text-red-400 hover:text-red-600 opacity-0 group-hover:opacity-100 transition-opacity"
                    title="Hapus Soal"
                  >
                    Hapus
                  </button>
                </div>
              {/each}
            {/if}
          </div>
        </div>
      </div>
      
    </div>
  </div>
</div>
