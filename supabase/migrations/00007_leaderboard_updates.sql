-- supabase/migrations/00007_leaderboard_updates.sql

-- 1. Update leaderboard_view for Stage 1 and Stage 2
DROP VIEW IF EXISTS public.leaderboard_view;

CREATE OR REPLACE VIEW public.leaderboard_view AS
SELECT 
    c.id,
    c.name,
    c.class,
    COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 1), 0) AS score_stage_1,
    COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 2), 0) AS score_stage_2,
    (
        COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 1), 0) + 
        COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 2), 0)
    ) / 2 AS final_score,
    COUNT(s.criteria_id) FILTER (WHERE st.stage_order IN (1, 2)) > 0 AS is_complete
FROM 
    public.candidates c
LEFT JOIN 
    public.scores s ON c.id = s.candidate_id
LEFT JOIN 
    public.scoring_criteria sc ON s.criteria_id = sc.id
LEFT JOIN
    public.stages st ON s.stage_id = st.id
GROUP BY 
    c.id, c.name, c.class
ORDER BY 
    final_score DESC;

GRANT SELECT ON public.leaderboard_view TO authenticated;

-- 2. Create a new view for Stage 3
CREATE OR REPLACE VIEW public.leaderboard_stage_3_view AS
SELECT 
    c.id,
    c.name,
    c.class,
    COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 3), 0) AS score_stage_3,
    COUNT(s.criteria_id) FILTER (WHERE st.stage_order = 3) > 0 AS is_complete
FROM 
    public.candidates c
LEFT JOIN 
    public.scores s ON c.id = s.candidate_id
LEFT JOIN 
    public.scoring_criteria sc ON s.criteria_id = sc.id
LEFT JOIN
    public.stages st ON s.stage_id = st.id
GROUP BY 
    c.id, c.name, c.class
ORDER BY 
    score_stage_3 DESC;

GRANT SELECT ON public.leaderboard_stage_3_view TO authenticated;
