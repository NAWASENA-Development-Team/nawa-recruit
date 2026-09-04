-- supabase/migrations/00010_video_scores.sql

-- 1. Create video_scores table
CREATE TABLE public.video_scores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    candidate_id UUID NOT NULL REFERENCES public.candidates(id) ON DELETE CASCADE,
    score NUMERIC NOT NULL CHECK (score >= 0 AND score <= 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(candidate_id)
);

-- 2. Enable RLS
ALTER TABLE public.video_scores ENABLE ROW LEVEL SECURITY;

-- 3. Panitia can do everything
CREATE POLICY "Panitia full access on video_scores"
    ON public.video_scores
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid() AND users.role = 'panitia'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid() AND users.role = 'panitia'
        )
    );

-- 4. Penguji can only read
CREATE POLICY "Penguji read access on video_scores"
    ON public.video_scores
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid() AND users.role = 'penguji'
        )
    );

-- 5. Update leaderboard_view to include video score
-- Harus DROP dulu karena kolom berubah
DROP VIEW IF EXISTS public.leaderboard_view;

CREATE OR REPLACE VIEW public.leaderboard_view AS
SELECT 
    c.id,
    c.name,
    c.class,
    COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 1), 0) AS score_stage_1,
    COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 2), 0) AS score_stage_2,
    COALESCE(vs.score, 0) AS score_video,
    (
        COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 1), 0) + 
        COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 2), 0)
    ) / 2 AS avg_stage_1_2,
    (
        (
            COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 1), 0) + 
            COALESCE(SUM(s.score * sc.weight) FILTER (WHERE st.stage_order = 2), 0)
        ) / 2
    ) + COALESCE(vs.score, 0) AS final_score,
    COUNT(s.criteria_id) FILTER (WHERE st.stage_order IN (1, 2)) > 0 AS is_complete
FROM 
    public.candidates c
LEFT JOIN 
    public.scores s ON c.id = s.candidate_id
LEFT JOIN 
    public.scoring_criteria sc ON s.criteria_id = sc.id
LEFT JOIN
    public.stages st ON s.stage_id = st.id
LEFT JOIN
    public.video_scores vs ON c.id = vs.candidate_id
GROUP BY 
    c.id, c.name, c.class, vs.score
ORDER BY 
    final_score DESC;

GRANT SELECT ON public.leaderboard_view TO authenticated;

-- 6. Enable realtime for video_scores
ALTER PUBLICATION supabase_realtime ADD TABLE public.video_scores;
