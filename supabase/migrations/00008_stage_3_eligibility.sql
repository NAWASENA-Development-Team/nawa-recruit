-- supabase/migrations/00008_stage_3_eligibility.sql
ALTER TABLE public.candidates ADD COLUMN is_eligible_stage_3 BOOLEAN NOT NULL DEFAULT FALSE;

-- Update the Stage 3 view to only include eligible candidates
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
WHERE
    c.is_eligible_stage_3 = TRUE
GROUP BY 
    c.id, c.name, c.class
ORDER BY 
    score_stage_3 DESC;
