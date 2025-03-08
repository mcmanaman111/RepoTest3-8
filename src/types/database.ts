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
      notes: {
        Row: {
          id: string
          user_id: string
          content: string
          question_id: string
          test_id: string
          topic: string
          sub_topic: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          content: string
          question_id: string
          test_id: string
          topic: string
          sub_topic: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          content?: string
          question_id?: string
          test_id?: string
          topic?: string
          sub_topic?: string
          created_at?: string
          updated_at?: string
        }
      }
      question_feedback: {
        Row: {
          id: string
          user_id: string
          question_id: string
          test_id: string
          message: string
          rating: number
          difficulty: string
          status: string
          admin_response: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          question_id: string
          test_id: string
          message: string
          rating: number
          difficulty: string
          status?: string
          admin_response?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          question_id?: string
          test_id?: string
          message?: string
          rating?: number
          difficulty?: string
          status?: string
          admin_response?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      notifications: {
        Row: {
          id: string
          user_id: string
          type: string
          title: string
          message: string
          link: string | null
          read: boolean
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          type: string
          title: string
          message: string
          link?: string | null
          read?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          type?: string
          title?: string
          message?: string
          link?: string | null
          read?: boolean
          created_at?: string
        }
      }
    }
  }
}