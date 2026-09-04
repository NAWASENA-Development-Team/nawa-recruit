<script lang="ts">
  import { onMount } from 'svelte';
  import { navigate } from 'svelte-routing';
  import { supabase } from '../lib/supabase/client';
  
  let userEmail = $state<string>('');
  let stats = $state({ candidates: 0, penguji: 0, rooms: 0 });
  let loadingStats = $state(true);

  onMount(async () => {
    const { data: { session } } = await supabase.auth.getSession();
    if (session?.user) {
      userEmail = session.user.email || 'Panitia';
    }

    // Fetch quick stats
    const [candRes, userRes, roomRes] = await Promise.all([
      supabase.from('candidates').select('id', { count: 'exact', head: true }),
      supabase.from('users').select('id', { count: 'exact', head: true }).eq('role', 'penguji'),
      supabase.from('rooms').select('id', { count: 'exact', head: true })
    ]);
    
    stats = {
      candidates: candRes.count || 0,
      penguji: userRes.count || 0,
      rooms: roomRes.count || 0
    };
    loadingStats = false;
  });

  async function handleLogout() {
    await supabase.auth.signOut();
    navigate('/');
  }
</script>

<svelte:head>
  <title>Dashboard Panitia | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen bg-parchment p-4 md:p-8">
  <div class="max-w-[1200px] mx-auto">
    <!-- Header Area -->
    <header class="flex flex-col md:flex-row md:justify-between md:items-end gap-6 mb-10">
      <div>
        <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-blue-50 border border-blue-100 text-nawa-accent text-caption font-bold mb-4 shadow-sm">
          <span class="w-2 h-2 rounded-full bg-nawa-accent animate-pulse"></span>
          Control Panel (Admin)
        </div>
        <h1 class="text-heading-sm md:text-heading text-graphite font-serif tracking-tight mb-2">
          Dashboard Panitia
        </h1>
        <p class="text-body-sm text-ash">Kelola seluruh tahapan seleksi, kandidat, dan penguji dari satu tempat.</p>
      </div>
      <button onclick={handleLogout} class="px-5 py-2.5 rounded-xl border border-mist bg-white text-charcoal text-body-sm font-bold hover:border-fog hover:bg-gray-50 active:scale-95 transition-all shadow-sm flex items-center gap-2">
        <svg class="w-4 h-4 text-ash" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path></svg>
        Keluar Sesi
      </button>
    </header>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-10">
      <div class="bg-white rounded-2xl p-5 border border-mist shadow-sm flex items-center gap-5">
        <div class="w-12 h-12 rounded-full bg-blue-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-6 h-6 text-nawa-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
        </div>
        <div>
          <p class="text-caption text-ash font-medium mb-0.5">Total Kandidat</p>
          {#if loadingStats}
            <div class="h-6 w-16 bg-mist animate-pulse rounded"></div>
          {:else}
            <p class="text-2xl font-bold text-graphite font-serif">{stats.candidates}</p>
          {/if}
        </div>
      </div>
      
      <div class="bg-white rounded-2xl p-5 border border-mist shadow-sm flex items-center gap-5">
        <div class="w-12 h-12 rounded-full bg-indigo-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-6 h-6 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
        </div>
        <div>
          <p class="text-caption text-ash font-medium mb-0.5">Penguji Terdaftar</p>
          {#if loadingStats}
            <div class="h-6 w-16 bg-mist animate-pulse rounded"></div>
          {:else}
            <p class="text-2xl font-bold text-graphite font-serif">{stats.penguji}</p>
          {/if}
        </div>
      </div>

      <div class="bg-white rounded-2xl p-5 border border-mist shadow-sm flex items-center gap-5">
        <div class="w-12 h-12 rounded-full bg-orange-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-6 h-6 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
        </div>
        <div>
          <p class="text-caption text-ash font-medium mb-0.5">Total Ruangan</p>
          {#if loadingStats}
            <div class="h-6 w-16 bg-mist animate-pulse rounded"></div>
          {:else}
            <p class="text-2xl font-bold text-graphite font-serif">{stats.rooms}</p>
          {/if}
        </div>
      </div>
    </div>
    
    <!-- Main Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      
      <!-- Group: Data Master -->
      <div class="lg:col-span-3 mb-2 mt-4 flex items-center gap-4">
        <div class="h-px bg-mist flex-grow"></div>
        <span class="text-caption font-bold text-ash uppercase tracking-wider">Persiapan & Master Data</span>
        <div class="h-px bg-mist flex-grow"></div>
      </div>

      <button type="button" class="group bg-white rounded-2xl p-6 border border-mist shadow-sm hover:shadow-md hover:border-fog transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-left w-full" onclick={() => navigate('/panitia/kandidat')}>
        <div class="absolute right-0 top-0 w-24 h-24 bg-gradient-to-bl from-blue-50 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-linen rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
          <svg class="w-6 h-6 text-nawa-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
        </div>
        <h2 class="text-subheading text-graphite font-serif mb-2 group-hover:text-nawa-accent transition-colors">Manajemen Kandidat</h2>
        <p class="text-caption text-ash mb-8 flex-grow leading-relaxed">Kelola data peserta oprec, tambah, edit, atau lihat detail per individu.</p>
        <div class="flex items-center text-nawa-accent text-body-sm font-bold">
          Buka Data Master
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>
      
      <button type="button" class="group bg-white rounded-2xl p-6 border border-mist shadow-sm hover:shadow-md hover:border-fog transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-left w-full" onclick={() => navigate('/panitia/soal')}>
        <div class="absolute right-0 top-0 w-24 h-24 bg-gradient-to-bl from-indigo-50 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-linen rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
          <svg class="w-6 h-6 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
        </div>
        <h2 class="text-subheading text-graphite font-serif mb-2 group-hover:text-indigo-600 transition-colors">Bank Kriteria (Soal)</h2>
        <p class="text-caption text-ash mb-8 flex-grow leading-relaxed">Kelola kriteria penilaian dan bobot untuk setiap tahap seleksi CBT.</p>
        <div class="flex items-center text-indigo-600 text-body-sm font-bold">
          Atur Kriteria
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>

      <!-- Group: Alokasi & Operasional -->
      <div class="lg:col-span-3 mb-2 mt-4 flex items-center gap-4">
        <div class="h-px bg-mist flex-grow"></div>
        <span class="text-caption font-bold text-ash uppercase tracking-wider">Alokasi & Penugasan</span>
        <div class="h-px bg-mist flex-grow"></div>
      </div>

      <button type="button" class="group bg-white rounded-2xl p-6 border border-mist shadow-sm hover:shadow-md hover:border-fog transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-left w-full" onclick={() => navigate('/panitia/penempatan')}>
        <div class="absolute right-0 top-0 w-24 h-24 bg-gradient-to-bl from-orange-50 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-linen rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
          <svg class="w-6 h-6 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"></path></svg>
        </div>
        <h2 class="text-subheading text-graphite font-serif mb-2 group-hover:text-orange-600 transition-colors">Penempatan Kandidat</h2>
        <p class="text-caption text-ash mb-8 flex-grow leading-relaxed">Arahkan peserta ke ruangan ujian yang tepat untuk tiap tahap seleksi.</p>
        <div class="flex items-center text-orange-600 text-body-sm font-bold">
          Atur Penempatan
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>

      <button type="button" class="group bg-white rounded-2xl p-6 border border-mist shadow-sm hover:shadow-md hover:border-fog transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-left w-full" onclick={() => navigate('/panitia/jadwal')}>
        <div class="absolute right-0 top-0 w-24 h-24 bg-gradient-to-bl from-purple-50 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-linen rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
          <svg class="w-6 h-6 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z"></path></svg>
        </div>
        <h2 class="text-subheading text-graphite font-serif mb-2 group-hover:text-purple-600 transition-colors">Penugasan Penguji</h2>
        <p class="text-caption text-ash mb-8 flex-grow leading-relaxed">Kelola rotasi dan tentukan ruangan mana yang dijaga oleh masing-masing penguji.</p>
        <div class="flex items-center text-purple-600 text-body-sm font-bold">
          Atur Jadwal Penguji
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>
      
      <!-- Group: Hasil & Pemantauan -->
      <div class="lg:col-span-3 mb-2 mt-4 flex items-center gap-4">
        <div class="h-px bg-mist flex-grow"></div>
        <span class="text-caption font-bold text-ash uppercase tracking-wider">Hasil & Seleksi</span>
        <div class="h-px bg-mist flex-grow"></div>
      </div>

      <button type="button" class="group bg-twilight rounded-2xl p-6 border border-dusk shadow-md hover:shadow-lg transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-white text-left w-full" onclick={() => navigate('/panitia/leaderboard')}>
        <div class="absolute right-0 top-0 w-32 h-32 bg-gradient-to-bl from-white/10 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform border border-white/5">
          <svg class="w-6 h-6 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
        </div>
        <h2 class="text-subheading font-serif mb-2 text-white">Live Leaderboard</h2>
        <p class="text-caption text-mist mb-8 flex-grow leading-relaxed">Pantau ranking peserta secara real-time untuk Tahap Penyisihan (I & II).</p>
        <div class="flex items-center text-yellow-400 text-body-sm font-bold">
          Lihat Ranking
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>

      <button type="button" class="group bg-white rounded-2xl p-6 border border-mist shadow-sm hover:shadow-md hover:border-fog transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-left w-full" onclick={() => navigate('/panitia/seleksi-tahap-3')}>
        <div class="absolute right-0 top-0 w-24 h-24 bg-gradient-to-bl from-green-50 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-linen rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
          <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"></path></svg>
        </div>
        <h2 class="text-subheading text-graphite font-serif mb-2 group-hover:text-green-600 transition-colors">Seleksi Tahap III</h2>
        <p class="text-caption text-ash mb-8 flex-grow leading-relaxed">Tentukan kandidat dari penyisihan yang berhak lolos ke Tahap III.</p>
        <div class="flex items-center text-green-600 text-body-sm font-bold">
          Saring Kandidat
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>

      <button type="button" class="group bg-white rounded-2xl p-6 border border-mist shadow-sm hover:shadow-md hover:border-fog transition-all flex flex-col h-full cursor-pointer relative overflow-hidden text-left w-full" onclick={() => navigate('/panitia/penilaian-video')}>
        <div class="absolute right-0 top-0 w-24 h-24 bg-gradient-to-bl from-pink-50 to-transparent rounded-bl-full opacity-50 pointer-events-none"></div>
        <div class="w-12 h-12 bg-linen rounded-xl flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
          <svg class="w-6 h-6 text-pink-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"></path></svg>
        </div>
        <h2 class="text-subheading text-graphite font-serif mb-2 group-hover:text-pink-600 transition-colors">Penilaian Video</h2>
        <p class="text-caption text-ash mb-8 flex-grow leading-relaxed">Beri nilai untuk video presentasi kandidat. Nilai ini akan diakumulasi ke perhitungan akhir.</p>
        <div class="flex items-center text-pink-600 text-body-sm font-bold">
          Beri Nilai Video
          <svg class="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
        </div>
      </button>

    </div>
  </div>
</div>
