-- Run this in your Supabase SQL Editor to create the gallery table

CREATE TABLE IF NOT EXISTS club_gallery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  title TEXT,
  uploaded_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE club_gallery ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "gallery_public_read"
  ON club_gallery FOR SELECT
  USING (true);

-- Allow club admins to insert
CREATE POLICY "gallery_admin_insert"
  ON club_gallery FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM club_members
      WHERE user_id = auth.uid()
        AND club_id = club_gallery.club_id
        AND role IN ('president', 'secretary', 'founding_admin')
    )
  );
  
-- Allow club admins to delete
CREATE POLICY "gallery_admin_delete"
  ON club_gallery FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM club_members
      WHERE user_id = auth.uid()
        AND club_id = club_gallery.club_id
        AND role IN ('president', 'secretary', 'founding_admin')
    )
  );
