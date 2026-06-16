-- Add media_type to club_gallery
ALTER TABLE club_gallery ADD COLUMN IF NOT EXISTS media_type TEXT NOT NULL DEFAULT 'image';
