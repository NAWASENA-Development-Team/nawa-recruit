export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          name: string
          role: 'panitia' | 'penguji'
          created_at: string
        }
        Insert: {
          id: string
          name: string
          role?: 'panitia' | 'penguji'
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          role?: 'panitia' | 'penguji'
          created_at?: string
        }
      }
      candidates: {
        Row: {
          id: string
          name: string
          class: string
          track: 'pengurus_biasa' | 'anggota_inti'
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          class: string
          track: 'pengurus_biasa' | 'anggota_inti'
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          class?: string
          track?: 'pengurus_biasa' | 'anggota_inti'
          created_at?: string
        }
      }
      stages: {
        Row: {
          id: string
          name: string
          stage_order: number
          applicable_tracks: ('pengurus_biasa' | 'anggota_inti')[]
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          stage_order: number
          applicable_tracks: ('pengurus_biasa' | 'anggota_inti')[]
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          stage_order?: number
          applicable_tracks?: ('pengurus_biasa' | 'anggota_inti')[]
          created_at?: string
        }
      }
      rooms: {
        Row: {
          id: string
          name: string
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          created_at?: string
        }
      }
      stage_room_assignments: {
        Row: {
          id: string
          stage_id: string
          room_id: string
          tester_1_id: string
          tester_2_id: string
          created_at: string
        }
        Insert: {
          id?: string
          stage_id: string
          room_id: string
          tester_1_id: string
          tester_2_id: string
          created_at?: string
        }
        Update: {
          id?: string
          stage_id?: string
          room_id?: string
          tester_1_id?: string
          tester_2_id?: string
          created_at?: string
        }
      }
      candidate_room_assignments: {
        Row: {
          id: string
          candidate_id: string
          stage_id: string
          room_id: string
          created_at: string
        }
        Insert: {
          id?: string
          candidate_id: string
          stage_id: string
          room_id: string
          created_at?: string
        }
        Update: {
          id?: string
          candidate_id?: string
          stage_id?: string
          room_id?: string
          created_at?: string
        }
      }
      scoring_criteria: {
        Row: {
          id: string
          stage_id: string
          name: string
          weight: number
          created_at: string
        }
        Insert: {
          id?: string
          stage_id: string
          name: string
          weight: number
          created_at?: string
        }
        Update: {
          id?: string
          stage_id?: string
          name?: string
          weight?: number
          created_at?: string
        }
      }
      scores: {
        Row: {
          id: string
          candidate_id: string
          stage_id: string
          criteria_id: string
          scorer_user_id: string
          score: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          candidate_id: string
          stage_id: string
          criteria_id: string
          scorer_user_id: string
          score: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          candidate_id?: string
          stage_id?: string
          criteria_id?: string
          scorer_user_id?: string
          score?: number
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      leaderboard_view: {
        Row: {
          id: string
          name: string
          class: string
          score_stage_1: number
          score_stage_2: number
          final_score: number
          is_complete: boolean
        }
      }
      leaderboard_stage_3_view: {
        Row: {
          id: string
          name: string
          class: string
          score_stage_3: number
          is_complete: boolean
        }
      }
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      user_role: 'panitia' | 'penguji'
      candidate_track: 'pengurus_biasa' | 'anggota_inti'
    }
  }
}
