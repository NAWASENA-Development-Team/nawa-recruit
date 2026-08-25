-- supabase/migrations/00003_seed_data.sql

-- 1. CLEANUP (Menghapus fitur Jalur Seleksi sesuai permintaan)
ALTER TABLE public.candidates DROP COLUMN IF EXISTS track;
ALTER TABLE public.stages DROP COLUMN IF EXISTS applicable_tracks;
DROP TYPE IF EXISTS candidate_track CASCADE;

-- 2. SEED DATA TAHAPAN (Stages)
TRUNCATE public.stages CASCADE;
INSERT INTO public.stages (id, name, stage_order) VALUES 
  (gen_random_uuid(), 'Tes Tulis', 1),
  (gen_random_uuid(), 'Wawancara', 2),
  (gen_random_uuid(), 'Debat / FGD', 3);

-- 3. SEED KRITERIA PENILAIAN (Scoring Criteria)
DO $$ 
DECLARE 
  v_stage_wawancara UUID;
  v_stage_debat UUID;
BEGIN
  SELECT id INTO v_stage_wawancara FROM public.stages WHERE name = 'Wawancara' LIMIT 1;
  SELECT id INTO v_stage_debat FROM public.stages WHERE name = 'Debat / FGD' LIMIT 1;

  INSERT INTO public.scoring_criteria (stage_id, name, weight) VALUES 
    (v_stage_wawancara, 'Public Speaking & Komunikasi', 30),
    (v_stage_wawancara, 'Problem Solving', 40),
    (v_stage_wawancara, 'Attitude & Etika', 30),
    (v_stage_debat, 'Logika & Argumentasi', 50),
    (v_stage_debat, 'Kerjasama Tim', 50);
END $$;

-- 4. SEED KANDIDAT
TRUNCATE public.candidates CASCADE;
INSERT INTO public.candidates (name, class) VALUES 
  ('Agus Pratama', 'XI MIPA 1'),
  ('Budi Santoso', 'XI MIPA 2'),
  ('Citra Lestari', 'XI IPS 1'),
  ('Dewi Kirana', 'XI IPS 2'),
  ('Eko Susilo', 'X MIPA 1'),
  ('Fajar Hidayat', 'X MIPA 3'),
  ('Gita Savitri', 'X IPS 1'),
  ('Hendra Gunawan', 'X IPS 4'),
  ('Intan Permatasari', 'XI MIPA 3'),
  ('Joko Anwar', 'X MIPA 2');
