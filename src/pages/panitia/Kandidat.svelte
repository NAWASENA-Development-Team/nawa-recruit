<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../../lib/supabase/client';
  import { toastStore } from '../../lib/toast.svelte';
  import type { Database } from '../../lib/types/database.types';
  
  type Candidate = Database['public']['Tables']['candidates']['Row']
  
  let candidates = $state<Candidate[]>([]);
  let loading = $state(true);
  
  // Form state
  let newName = $state('');
  let newClass = $state('');
  let isSubmitting = $state(false);

  async function fetchCandidates() {
    loading = true;
    const { data, error } = await supabase
      .from('candidates')
      .select('*')
      .order('created_at', { ascending: false });
      
    if (!error && data) {
      candidates = data;
    }
    loading = false;
  }

  onMount(() => {
    fetchCandidates();
  });

  async function addCandidate(e: Event) {
    e.preventDefault();
    if (!newName || !newClass) return;
    
    isSubmitting = true;
    const { data, error } = await supabase
      .from('candidates')
      .insert([
        { name: newName, class: newClass }
      ])
      .select();

    if (!error && data) {
      candidates = [data[0], ...candidates];
      newName = '';
      newClass = '';
      toastStore.success(`Kandidat ${data[0].name} berhasil ditambahkan!`);
    } else if (error) {
      toastStore.error("Gagal menambahkan: " + error.message);
    }
    isSubmitting = false;
  }

  let isImporting = $state(false);
  
  async function handleImport(e: Event) {
    const target = e.target as HTMLInputElement;
    const file = target.files?.[0];
    if (!file) return;

    isImporting = true;
    try {
      // Menggunakan SheetJS (xlsx) yang jauh lebih stabil di Vite
      const XLSX = await import('xlsx');
      const buffer = await file.arrayBuffer();
      const workbook = XLSX.read(buffer, { type: 'array' });
      const firstSheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[firstSheetName];
      const rows: (string | number | boolean | null)[][] = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
      
      if (rows.length <= 1) {
        toastStore.error("File Excel kosong atau hanya berisi header.");
        isImporting = false;
        target.value = '';
        return;
      }
      
      // Hapus header
      rows.shift();
      
      const inserts = rows.map((row) => {
        const name = String(row[0] || '').trim();
        const classStr = String(row[1] || '').trim();
        
        return {
          name,
          class: classStr
        };
      }).filter(item => item.name !== '');

      if (inserts.length === 0) {
        toastStore.error("Tidak ada data valid yang ditemukan.");
        isImporting = false;
        target.value = '';
        return;
      }

      const { data, error } = await supabase
        .from('candidates')
        .insert(inserts)
        .select();

      if (!error && data) {
        toastStore.success(`Berhasil mengimpor ${data.length} kandidat!`);
        candidates = [...data, ...candidates];
      } else {
        toastStore.error("Gagal mengimpor: " + error?.message);
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unknown error';
      toastStore.error("Gagal membaca file Excel. Error: " + message);
    }
    
    isImporting = false;
    target.value = '';
  }
</script>

<svelte:head>
  <title>Manajemen Kandidat | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-page mx-auto">
    <header class="flex justify-between items-center mb-8 md:mb-12">
      <div>
        <button onclick={() => navigate('/panitia/dashboard')} class="text-ash text-caption hover:text-charcoal mb-2 inline-flex items-center active:scale-95 transition-transform">
          ← Kembali ke Dashboard
        </button>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight">Manajemen Kandidat</h1>
      </div>
    </header>
    
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Sidebar Form -->
      <div class="lg:col-span-1">
        <div class="bg-paper rounded-2xl p-6 border border-mist shadow-subtle sticky top-8">
          <h2 class="text-subheading text-graphite font-serif mb-6">Tambah Kandidat</h2>
          
          <form onsubmit={addCandidate} class="space-y-6">
            <div class="space-y-1">
              <label for="name" class="text-caption text-charcoal font-medium font-sans">Nama Lengkap</label>
              <input 
                id="name"
                type="text" 
                bind:value={newName}
                required
                class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors"
              />
            </div>
            
            <div class="space-y-1">
              <label for="classStr" class="text-caption text-charcoal font-medium font-sans">Kelas</label>
              <input 
                id="classStr"
                type="text" 
                bind:value={newClass}
                placeholder="Mis: X MIPA 1"
                required
                class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors"
              />
            </div>
            
            <button 
              type="submit" 
              disabled={isSubmitting}
              class="w-full flex items-center justify-center rounded-lg border border-nawa-accent text-nawa-accent py-3 px-4 font-medium text-body-sm hover:bg-blue-50 transition-colors disabled:opacity-50 active:scale-[0.98]"
            >
              {isSubmitting ? 'Menyimpan...' : 'Tambah Kandidat'}
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
          
          <!-- Tombol Import XLSX -->
          <div class="space-y-2">
            <label 
              for="excel-upload"
              class={`w-full flex items-center justify-center gap-2 rounded-lg bg-linen text-charcoal border border-fog border-dashed py-3 px-4 font-medium text-body-sm cursor-pointer hover:bg-white hover:border-nawa-accent transition-colors active:scale-[0.98] ${isImporting ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              <span>📊</span>
              <span>{isImporting ? 'Memproses...' : 'Impor dari Excel (.xlsx)'}</span>
            </label>
            <input 
              id="excel-upload"
              type="file" 
              accept=".xlsx, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
              onchange={handleImport}
              disabled={isImporting}
              class="hidden"
            />
            <p class="text-xs text-ash text-center mt-1">Format: Kolom A (Nama), Kolom B (Kelas)</p>
          </div>
        </div>
      </div>
      
      <!-- List Kandidat -->
      <div class="lg:col-span-2">
        <div class="bg-paper rounded-2xl border border-mist shadow-subtle overflow-hidden">
          <div class="p-6 border-b border-mist">
            <h2 class="text-subheading text-graphite font-serif">Daftar Kandidat</h2>
          </div>
          
          {#if loading}
            <div class="p-8 text-center text-ash text-body-sm">Memuat data...</div>
          {:else if candidates.length === 0}
            <div class="p-12 text-center text-ash text-body-sm">
              Belum ada kandidat. Silakan tambah di form sebelah kiri.
            </div>
          {:else}
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-linen/50 text-ash text-caption">
                    <th class="px-6 py-4 font-medium border-b border-mist">Nama</th>
                    <th class="px-6 py-4 font-medium border-b border-mist">Kelas</th>
                    <th class="px-6 py-4 font-medium border-b border-mist text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-mist">
                  {#each candidates as candidate}
                    <tr class="hover:bg-linen/30 transition-colors">
                      <td class="px-6 py-4 text-charcoal text-body-sm font-medium">{candidate.name}</td>
                      <td class="px-6 py-4 text-ash text-body-sm">{candidate.class}</td>
                      <td class="px-6 py-4 text-right">
                        <button class="text-nawa-accent hover:text-signal-blue text-caption font-medium">Hapus</button>
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
