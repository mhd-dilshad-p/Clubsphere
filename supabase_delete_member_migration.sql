-- ============================================================
-- SQL MIGRATION: ALLOW ADMINS TO DELETE MISTAKEN MEMBERS
-- Run this in Supabase Dashboard -> SQL Editor -> New Query
-- ============================================================

-- Allow Secretary, President, and Founding Admin to delete members
CREATE POLICY "admin_delete_members"
  ON club_members FOR DELETE
  USING (
    has_role(club_id, ARRAY['secretary', 'president', 'founding_admin']::member_role[])
  );
