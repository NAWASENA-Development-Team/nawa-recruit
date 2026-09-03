-- supabase/migrations/00009_revert_wawancara.sql

-- Revert policy to original 2 testers
DROP POLICY IF EXISTS "Penguji can insert/update their own scores" ON public.scores;

-- Revert to 2 testers per room
ALTER TABLE public.stage_room_assignments DROP COLUMN IF EXISTS tester_3_id;

CREATE POLICY "Penguji can insert/update their own scores" ON public.scores
  FOR ALL USING (
    auth.uid() = scorer_user_id
    AND EXISTS (
      SELECT 1 FROM public.candidate_room_assignments cra
      JOIN public.stage_room_assignments sra 
        ON cra.stage_id = sra.stage_id AND cra.room_id = sra.room_id
      WHERE cra.candidate_id = scores.candidate_id
        AND cra.stage_id = scores.stage_id
        AND (sra.tester_1_id = auth.uid() OR sra.tester_2_id = auth.uid())
    )
  );

-- Revert to 4 rooms
TRUNCATE public.rooms CASCADE;
INSERT INTO public.rooms (id, name) VALUES 
  (gen_random_uuid(), 'Ruang 1'),
  (gen_random_uuid(), 'Ruang 2'),
  (gen_random_uuid(), 'Ruang 3'),
  (gen_random_uuid(), 'Ruang 4');
