-- supabase/migrations/00005_leaderboard_view.sql

-- Membuat view untuk kalkulasi skor Leaderboard langsung di level database
-- Ini mengurangi beban frontend secara signifikan ketika jumlah data membengkak.

CREATE OR REPLACE VIEW public.leaderboard_view AS
SELECT 
    c.id,
    c.name,
    c.class,
    COALESCE(SUM(s.score * sc.weight), 0) AS total_score,
    COUNT(s.criteria_id) > 0 AS is_complete
FROM 
    public.candidates c
LEFT JOIN 
    public.scores s ON c.id = s.candidate_id
LEFT JOIN 
    public.scoring_criteria sc ON s.criteria_id = sc.id
GROUP BY 
    c.id, c.name, c.class
ORDER BY 
    total_score DESC;

-- Pastikan user yang login (panitia) bisa membaca view ini
GRANT SELECT ON public.leaderboard_view TO authenticated;
