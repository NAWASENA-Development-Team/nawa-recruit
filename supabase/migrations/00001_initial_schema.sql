-- supabase/migrations/00001_initial_schema.sql

-- 1. Create enum types
CREATE TYPE candidate_track AS ENUM ('pengurus_biasa', 'anggota_inti');
CREATE TYPE user_role AS ENUM ('panitia', 'penguji');

-- 2. Create users table (extends Supabase Auth)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'penguji'::user_role,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Panitia can view all users" ON public.users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

-- 3. Create candidates table
CREATE TABLE public.candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  class TEXT NOT NULL,
  track candidate_track NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.candidates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to candidates" ON public.candidates
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view candidates" ON public.candidates
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

-- 4. Create stages table
CREATE TABLE public.stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  stage_order INTEGER NOT NULL,
  applicable_tracks candidate_track[] NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.stages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to stages" ON public.stages
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view stages" ON public.stages
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

-- 5. Create rooms table
CREATE TABLE public.rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to rooms" ON public.rooms
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view rooms" ON public.rooms
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

-- 6. Create stage_room_assignments table
-- Links a room, stage, and exactly 2 testers (users)
CREATE TABLE public.stage_room_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stage_id UUID REFERENCES public.stages(id) ON DELETE CASCADE NOT NULL,
  room_id UUID REFERENCES public.rooms(id) ON DELETE CASCADE NOT NULL,
  tester_1_id UUID REFERENCES public.users(id) NOT NULL,
  tester_2_id UUID REFERENCES public.users(id) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(stage_id, room_id)
);

ALTER TABLE public.stage_room_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to stage_room_assignments" ON public.stage_room_assignments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view stage_room_assignments" ON public.stage_room_assignments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

-- 7. Create candidate_room_assignments table
-- Assigns a candidate to a specific room for a specific stage
CREATE TABLE public.candidate_room_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id UUID REFERENCES public.candidates(id) ON DELETE CASCADE NOT NULL,
  stage_id UUID REFERENCES public.stages(id) ON DELETE CASCADE NOT NULL,
  room_id UUID REFERENCES public.rooms(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(candidate_id, stage_id)
);

ALTER TABLE public.candidate_room_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to candidate_room_assignments" ON public.candidate_room_assignments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view candidate_room_assignments" ON public.candidate_room_assignments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

-- 8. Create scoring_criteria table
CREATE TABLE public.scoring_criteria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stage_id UUID REFERENCES public.stages(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  weight NUMERIC NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.scoring_criteria ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to scoring_criteria" ON public.scoring_criteria
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view scoring_criteria" ON public.scoring_criteria
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

-- 9. Create scores table
CREATE TABLE public.scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id UUID REFERENCES public.candidates(id) ON DELETE CASCADE NOT NULL,
  stage_id UUID REFERENCES public.stages(id) ON DELETE CASCADE NOT NULL,
  criteria_id UUID REFERENCES public.scoring_criteria(id) ON DELETE CASCADE NOT NULL,
  scorer_user_id UUID REFERENCES public.users(id) NOT NULL,
  score NUMERIC NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(candidate_id, stage_id, criteria_id, scorer_user_id)
);

ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Panitia has full access to scores" ON public.scores
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'panitia')
  );

CREATE POLICY "Penguji can view all scores" ON public.scores
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'penguji')
  );

CREATE POLICY "Penguji can insert/update their own scores" ON public.scores
  FOR ALL USING (
    -- The scorer must be the current user
    auth.uid() = scorer_user_id
    AND EXISTS (
      -- The current user must be assigned to the room where this candidate is assigned for this stage
      SELECT 1 FROM public.candidate_room_assignments cra
      JOIN public.stage_room_assignments sra 
        ON cra.stage_id = sra.stage_id AND cra.room_id = sra.room_id
      WHERE cra.candidate_id = scores.candidate_id
        AND cra.stage_id = scores.stage_id
        AND (sra.tester_1_id = auth.uid() OR sra.tester_2_id = auth.uid())
    )
  );

-- Create a function and trigger to update `updated_at` on scores
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_scores_modtime
BEFORE UPDATE ON public.scores
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
