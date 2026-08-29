<script lang="ts">
  import { onMount } from "svelte";
  import { Router, Route, navigate } from "svelte-routing";
  import { supabase } from "./lib/supabase/client";
  import Login from "./pages/Login.svelte";
  import DashboardPanitia from "./pages/DashboardPanitia.svelte";
  import DashboardPenguji from "./pages/DashboardPenguji.svelte";
  import PanitiaKandidat from "./pages/panitia/Kandidat.svelte";
  import PanitiaJadwal from "./pages/panitia/Jadwal.svelte";
  import PanitiaLeaderboard from "./pages/panitia/Leaderboard.svelte";
  import PanitiaLeaderboardFinal from "./pages/panitia/LeaderboardFinal.svelte";
  import PanitiaPenempatan from "./pages/panitia/Penempatan.svelte";
  import PanitiaSoal from "./pages/panitia/Soal.svelte";
  import ToastContainer from "./components/ToastContainer.svelte";

  let { url = "" } = $props();
  
  let sessionChecked = $state(false);

  onMount(async () => {
    // Cek sesi aktif
    const { data } = await supabase.auth.getSession();
    
    // Jika tidak ada sesi dan user tidak di halaman login, tendang ke login
    if (!data.session?.user && window.location.pathname !== '/') {
      navigate("/", { replace: true });
    }

    // Dengarkan perubahan status login (logout otomatis dll)
    supabase.auth.onAuthStateChange((_event, session) => {
      if (!session?.user && window.location.pathname !== '/') {
        navigate("/", { replace: true });
      }
    });

    sessionChecked = true;
  });
</script>

<ToastContainer />

{#if !sessionChecked}
  <div class="min-h-screen bg-parchment flex items-center justify-center">
    <div class="animate-pulse text-ash text-body-sm font-medium font-sans">
      Memverifikasi akses...
    </div>
  </div>
{:else}
  <Router {url}>
    <Route path="/"><Login /></Route>
    <Route path="/panitia/dashboard"><DashboardPanitia /></Route>
    <Route path="/panitia/kandidat"><PanitiaKandidat /></Route>
    <Route path="/panitia/soal"><PanitiaSoal /></Route>
    <Route path="/panitia/jadwal"><PanitiaJadwal /></Route>
    <Route path="/panitia/penempatan"><PanitiaPenempatan /></Route>
    <Route path="/panitia/leaderboard"><PanitiaLeaderboard /></Route>
    <Route path="/panitia/leaderboard-final"><PanitiaLeaderboardFinal /></Route>
    <Route path="/penguji/dashboard"><DashboardPenguji /></Route>
  </Router>
{/if}
