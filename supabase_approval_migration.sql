-- Correcting the table name to 'programs' instead of 'club_events'
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS approval_status text DEFAULT 'approved';

ALTER TABLE club_members 
ADD COLUMN IF NOT EXISTS approval_status text DEFAULT 'approved';

UPDATE programs SET approval_status = 'approved' WHERE approval_status IS NULL;
UPDATE club_members SET approval_status = 'approved' WHERE approval_status IS NULL;
