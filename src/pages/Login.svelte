<script lang="ts">
  import { navigate } from 'svelte-routing';
  import { supabase } from '../lib/supabase/client';
  import { toastStore } from '../lib/toast.svelte';

  let email = $state('');
  let password = $state('');
  let loading = $state(false);

  async function handleLogin(e: Event) {
    e.preventDefault();
    loading = true;

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      toastStore.error(error.message);
      loading = false;
      return;
    }

    if (data.user) {
      // Cek role
      const { data: userData } = await supabase
        .from('users')
        .select('role')
        .eq('id', data.user.id)
        .single();
        
      if (userData) {
        if (userData.role === 'panitia') {
          navigate('/panitia/dashboard');
        } else {
          navigate('/penguji/dashboard');
        }
      }
    }
    loading = false;
  }
</script>

<svelte:head>
  <title>Masuk | Nawa-Recruit</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-parchment px-4 py-8">
  <div class="max-w-md w-full bg-paper rounded-2xl shadow-subtle border border-mist p-6 sm:p-12 relative overflow-hidden">
    <!-- Subtle top accent -->
    <div class="absolute top-0 left-0 right-0 h-1 bg-nawa-accent"></div>

    <div class="mb-10 text-center">
      <h1 class="text-heading-sm mb-2 text-graphite tracking-tight font-serif">Nawa-Recruit</h1>
      <p class="text-body-sm text-ash font-sans">Sistem Penilaian Oprec OSIS Nawasena</p>
    </div>

    <form class="space-y-6" onsubmit={handleLogin}>
      <div class="space-y-1">
        <label for="email" class="text-caption text-charcoal font-medium font-sans ml-1">Email</label>
        <input 
          id="email" 
          type="email" 
          bind:value={email}
          placeholder="penguji@nawasena.org"
          required
          class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors"
        />
      </div>

      <div class="space-y-1">
        <label for="password" class="text-caption text-charcoal font-medium font-sans">Password</label>
        <input 
          id="password"
          type="password" 
          bind:value={password}
          placeholder="••••••••"
          required
          class="w-full bg-linen border-b border-charcoal text-charcoal px-4 py-3 text-body-sm focus:outline-none focus:border-nawa-accent focus:ring-0 transition-colors"
        />
      </div>

      <button 
        type="submit" 
        disabled={loading}
        class="w-full mt-4 flex items-center justify-center rounded-lg border border-nawa-accent text-nawa-accent py-3 px-4 font-medium text-body-sm hover:bg-blue-50 transition-colors disabled:opacity-50"
      >
        {loading ? 'Memproses...' : 'Masuk →'}
      </button>
    </form>
    
    <div class="mt-8 text-center">
      <p class="text-caption text-ash">
        Gunakan kredensial yang diberikan oleh Panitia Inti
      </p>
    </div>
  </div>
</div>
