-- ============================================================
-- CLUBSPHERE — COMPLETE DATABASE SQL
-- Verified & Successfully Executed
-- Run in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================
 
 
-- ============================================================
-- STEP 1: ENUMS
-- ============================================================
CREATE TYPE club_category AS ENUM (
  'arts','sports','arts_and_sports','cultural','social_welfare','educational','religious','other'
);
CREATE TYPE member_role AS ENUM (
  'member','secretary','treasurer','president','founding_admin'
);
CREATE TYPE club_leadership_model AS ENUM ('fixed','rotating');
CREATE TYPE verification_status   AS ENUM ('pending','verified','rejected','suspended');
CREATE TYPE finance_type          AS ENUM ('income','expenditure');
CREATE TYPE finance_status        AS ENUM ('pending_approval','approved','rejected');
CREATE TYPE election_status       AS ENUM (
  'scheduled','voting_open','tallying','pending_president_confirm','completed','extended'
);
CREATE TYPE notification_type AS ENUM (
  'event','finance_update','election_start','election_result',
  'welfare_program','member_added','system','payment_request'
);
CREATE TYPE program_category AS ENUM (
  'event','welfare','fundraiser','meeting','competition','other'
);
 
 
-- ============================================================
-- STEP 2: SHARED TRIGGER FUNCTION (define before any table uses it)
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
 
-- ============================================================
-- STEP 3: CLUBS
-- ============================================================
CREATE TABLE clubs (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  register_number      TEXT UNIQUE NOT NULL,
  name                 TEXT NOT NULL,
  category             club_category NOT NULL,
  email                TEXT,
  phone                TEXT,
  address_line1        TEXT NOT NULL,
  address_line2        TEXT,
  area                 TEXT,
  city                 TEXT NOT NULL,
  district             TEXT NOT NULL,
  state                TEXT NOT NULL,
  pin_code             TEXT NOT NULL,
  latitude             DOUBLE PRECISION,
  longitude            DOUBLE PRECISION,
  logo_url             TEXT,
  description          TEXT,
  founding_date        DATE,
  leadership_model     club_leadership_model NOT NULL DEFAULT 'rotating',
  term_duration_months INT NOT NULL DEFAULT 12,
  verification_status  verification_status NOT NULL DEFAULT 'pending',
  verified_at          TIMESTAMPTZ,
  verified_by          UUID REFERENCES auth.users(id),
  rejection_reason     TEXT,
  is_active            BOOLEAN NOT NULL DEFAULT true,
  total_members        INT NOT NULL DEFAULT 0,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE OR REPLACE FUNCTION generate_register_number()
RETURNS TRIGGER AS $$
DECLARE
  seq_num    INT;
  state_code TEXT;
BEGIN
  SELECT COUNT(*) + 1 INTO seq_num FROM clubs WHERE state = NEW.state;
  state_code := UPPER(LEFT(REPLACE(NEW.state, ' ', ''), 2));
  NEW.register_number := 'CS-' || state_code || '-'
    || EXTRACT(YEAR FROM now())::TEXT || '-'
    || LPAD(seq_num::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER set_register_number
  BEFORE INSERT ON clubs
  FOR EACH ROW EXECUTE FUNCTION generate_register_number();
 
CREATE TRIGGER clubs_updated_at
  BEFORE UPDATE ON clubs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
 
 
-- ============================================================
-- STEP 4: CLUB MEMBERS
-- ============================================================
CREATE TABLE club_members (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id            UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  user_id            UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  role               member_role NOT NULL DEFAULT 'member',
  full_name          TEXT NOT NULL,
  email              TEXT,
  phone              TEXT,
  avatar_url         TEXT,
  address            TEXT,
  date_of_birth      DATE,
  join_date          DATE NOT NULL DEFAULT CURRENT_DATE,
  member_number      TEXT NOT NULL,
  is_active          BOOLEAN NOT NULL DEFAULT true,
  role_valid_from    TIMESTAMPTZ DEFAULT now(),
  role_valid_until   TIMESTAMPTZ,
  invite_token       TEXT UNIQUE,
  invite_sent_at     TIMESTAMPTZ,
  invite_accepted_at TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(club_id, email),
  UNIQUE(club_id, phone),
  UNIQUE(club_id, member_number)
);
 
CREATE OR REPLACE FUNCTION generate_member_number()
RETURNS TRIGGER AS $$
DECLARE seq_num INT;
BEGIN
  SELECT COUNT(*) + 1 INTO seq_num
  FROM club_members WHERE club_id = NEW.club_id;
  NEW.member_number := 'MBR-' || LPAD(seq_num::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER set_member_number
  BEFORE INSERT ON club_members
  FOR EACH ROW EXECUTE FUNCTION generate_member_number();
 
CREATE TRIGGER members_updated_at
  BEFORE UPDATE ON club_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
 
 
-- ============================================================
-- STEP 5: FINANCE ENTRIES
-- ============================================================
CREATE TABLE finance_entries (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id               UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  type                  finance_type NOT NULL,
  category              TEXT NOT NULL,
  amount                DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  description           TEXT NOT NULL,
  receipt_url           TEXT,
  transaction_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  reference_number      TEXT,
  submitted_by          UUID NOT NULL REFERENCES club_members(id),
  status                finance_status NOT NULL DEFAULT 'approved',
  approved_by           UUID REFERENCES club_members(id),
  approved_at           TIMESTAMPTZ,
  rejection_note        TEXT,
  requires_approval     BOOLEAN NOT NULL DEFAULT false,
  is_visible_to_members BOOLEAN NOT NULL DEFAULT false,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE OR REPLACE FUNCTION set_finance_approval_rules()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.amount >= 5000 THEN
    NEW.requires_approval     := true;
    NEW.status                := 'pending_approval';
    NEW.is_visible_to_members := false;
  ELSE
    NEW.requires_approval     := false;
    NEW.status                := 'approved';
    NEW.is_visible_to_members := true;
    NEW.approved_at           := now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER finance_approval_rules
  BEFORE INSERT ON finance_entries
  FOR EACH ROW EXECUTE FUNCTION set_finance_approval_rules();
 
CREATE OR REPLACE FUNCTION finance_on_approve()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    NEW.is_visible_to_members := true;
    NEW.approved_at           := now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER finance_approval_update
  BEFORE UPDATE ON finance_entries
  FOR EACH ROW EXECUTE FUNCTION finance_on_approve();
 
CREATE TRIGGER finance_updated_at
  BEFORE UPDATE ON finance_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
 
 
-- ============================================================
-- STEP 6: PROGRAMS
-- ============================================================
CREATE TABLE programs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id          UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  category         program_category NOT NULL,
  title            TEXT NOT NULL,
  description      TEXT,
  venue            TEXT,
  start_datetime   TIMESTAMPTZ NOT NULL,
  end_datetime     TIMESTAMPTZ,
  budget           DECIMAL(12,2),
  target_amount    DECIMAL(12,2),
  collected_amount DECIMAL(12,2) DEFAULT 0,
  created_by       UUID NOT NULL REFERENCES club_members(id),
  is_published     BOOLEAN NOT NULL DEFAULT false,
  notify_members   BOOLEAN NOT NULL DEFAULT true,
  attachment_url   TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TRIGGER programs_updated_at
  BEFORE UPDATE ON programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
 
 
-- ============================================================
-- STEP 7: WELFARE CONTRIBUTIONS
-- ============================================================
CREATE TABLE welfare_contributions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  club_id     UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  member_id   UUID NOT NULL REFERENCES club_members(id),
  amount      DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  payment_ref TEXT,
  paid_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes       TEXT
);
 
 
-- ============================================================
-- STEP 8: ELECTIONS & VOTING
-- ============================================================
CREATE TABLE election_sessions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id          UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  position         member_role NOT NULL,
  status           election_status NOT NULL DEFAULT 'scheduled',
  voting_opens_at  TIMESTAMPTZ NOT NULL,
  voting_closes_at TIMESTAMPTZ NOT NULL,
  confirm_deadline TIMESTAMPTZ,
  term_start       TIMESTAMPTZ,
  term_end         TIMESTAMPTZ,
  winner_id        UUID REFERENCES club_members(id),
  confirmed_by     UUID REFERENCES club_members(id),
  auto_confirmed   BOOLEAN DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE election_nominations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id   UUID NOT NULL REFERENCES election_sessions(id) ON DELETE CASCADE,
  nominee_id   UUID NOT NULL REFERENCES club_members(id),
  nominated_by UUID NOT NULL REFERENCES club_members(id),
  nominated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(session_id, nominee_id)
);
 
CREATE TABLE election_votes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES election_sessions(id) ON DELETE CASCADE,
  voter_id   UUID NOT NULL REFERENCES club_members(id),
  nominee_id UUID NOT NULL REFERENCES club_members(id),
  voted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(session_id, voter_id)
);
 
 
-- ============================================================
-- STEP 9: MEETING MINUTES
-- ============================================================
CREATE TABLE meeting_minutes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id      UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  meeting_date DATE NOT NULL,
  content      TEXT,
  file_url     TEXT,
  uploaded_by  UUID NOT NULL REFERENCES club_members(id),
  is_published BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
 
-- ============================================================
-- STEP 10: NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id      UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  type         notification_type NOT NULL,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  data         JSONB DEFAULT '{}',
  sent_by      UUID REFERENCES club_members(id),
  target_roles member_role[] DEFAULT NULL,
  is_sent      BOOLEAN NOT NULL DEFAULT false,
  sent_at      TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE TABLE notification_reads (
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  member_id       UUID NOT NULL REFERENCES club_members(id),
  read_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY(notification_id, member_id)
);
 
 
-- ============================================================
-- STEP 11: SUPER ADMINS
-- ============================================================
CREATE TABLE super_admins (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name  TEXT NOT NULL DEFAULT 'Super Admin',
  email      TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
 
-- ============================================================
-- STEP 12: ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE clubs                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_members          ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance_entries       ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs              ENABLE ROW LEVEL SECURITY;
ALTER TABLE welfare_contributions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE election_sessions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE election_nominations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE election_votes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_minutes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications         ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads    ENABLE ROW LEVEL SECURITY;
ALTER TABLE super_admins          ENABLE ROW LEVEL SECURITY;
 
-- RLS Helper
CREATE OR REPLACE FUNCTION has_role(club UUID, roles member_role[])
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM club_members
    WHERE user_id = auth.uid()
      AND club_id = club
      AND role = ANY(roles)
      AND is_active = true
  );
$$ LANGUAGE sql SECURITY DEFINER;
 
-- Clubs policies
CREATE POLICY "clubs_read_verified"
  ON clubs FOR SELECT
  USING (verification_status = 'verified');
 
CREATE POLICY "clubs_insert_auth"
  ON clubs FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
 
CREATE POLICY "clubs_update_founding"
  ON clubs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM club_members
      WHERE club_id = clubs.id
        AND user_id = auth.uid()
        AND role = 'founding_admin'
    )
  );
 
-- RLS Helper to check if user is in a club (bypasses RLS to avoid infinite recursion)
CREATE OR REPLACE FUNCTION is_club_member(club UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM club_members
    WHERE user_id = auth.uid()
      AND club_id = club
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Club members policies
CREATE POLICY "members_read_own_club"
  ON club_members FOR SELECT
  USING (
    is_club_member(club_id)
  );
 
CREATE POLICY "secretary_insert_members"
  ON club_members FOR INSERT
  WITH CHECK (
    has_role(club_id, ARRAY['secretary','founding_admin']::member_role[])
  );
 
-- Finance policies
CREATE POLICY "finance_approved_read"
  ON finance_entries FOR SELECT
  USING (
    is_visible_to_members = true
    AND has_role(club_id, ARRAY['member','secretary','treasurer','president','founding_admin']::member_role[])
  );
 
CREATE POLICY "finance_roles_read_all"
  ON finance_entries FOR SELECT
  USING (
    has_role(club_id, ARRAY['treasurer','president','founding_admin']::member_role[])
  );
 
CREATE POLICY "finance_treasurer_insert"
  ON finance_entries FOR INSERT
  WITH CHECK (
    has_role(club_id, ARRAY['treasurer','founding_admin']::member_role[])
  );
 
CREATE POLICY "finance_president_update"
  ON finance_entries FOR UPDATE
  USING (
    has_role(club_id, ARRAY['president','founding_admin']::member_role[])
  );
 
-- Election policies
CREATE POLICY "elections_members_read"
  ON election_sessions FOR SELECT
  USING (
    has_role(club_id, ARRAY['member','secretary','treasurer','president','founding_admin']::member_role[])
  );
 
CREATE POLICY "votes_member_insert"
  ON election_votes FOR INSERT
  WITH CHECK (
    has_role(
      (SELECT club_id FROM election_sessions WHERE id = session_id),
      ARRAY['member','secretary','treasurer','president','founding_admin']::member_role[]
    )
  );
 
-- Meeting minutes policies
CREATE POLICY "minutes_members_read"
  ON meeting_minutes FOR SELECT
  USING (
    is_published = true
    AND has_role(club_id, ARRAY['member','secretary','treasurer','president','founding_admin']::member_role[])
  );
 
CREATE POLICY "minutes_secretary_write"
  ON meeting_minutes FOR ALL
  USING (
    has_role(club_id, ARRAY['secretary','founding_admin']::member_role[])
  );
 
-- Notifications policy
CREATE POLICY "notif_members_read"
  ON notifications FOR SELECT
  USING (
    has_role(club_id, ARRAY['member','secretary','treasurer','president','founding_admin']::member_role[])
  );
 
-- Super admins policy
CREATE POLICY "super_admins_read"
  ON super_admins FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- FIX: Allow Super Admins to read ALL Clubs and Club Members
-- ============================================================
CREATE POLICY "super_admins_read_all_clubs"
  ON clubs FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM super_admins WHERE id = auth.uid())
  );

CREATE POLICY "super_admins_update_all_clubs"
  ON clubs FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM super_admins WHERE id = auth.uid())
  );

CREATE POLICY "super_admins_delete_all_clubs"
  ON clubs FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM super_admins WHERE id = auth.uid())
  );

CREATE POLICY "super_admins_read_all_members"
  ON club_members FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM super_admins WHERE id = auth.uid())
  );

-- ============================================================
-- STEP 13: pg_cron ELECTION AUTOMATION JOBS
-- Requires: pg_cron extension enabled in Dashboard → Extensions
-- ============================================================
SELECT cron.schedule('open-voting', '30 18 * * *', $$
  INSERT INTO election_sessions (
    club_id, position, status, voting_opens_at, voting_closes_at, confirm_deadline
  )
  SELECT
    cm.club_id,
    cm.role,
    'voting_open'::election_status,
    now(),
    now() + INTERVAL '5 days',
    now() + INTERVAL '6 days'
  FROM club_members cm
  JOIN clubs c ON c.id = cm.club_id
  WHERE c.leadership_model = 'rotating'
    AND cm.role IN ('president','secretary','treasurer')
    AND cm.role_valid_until IS NOT NULL
    AND cm.role_valid_until - now() <= INTERVAL '6 days'
    AND cm.role_valid_until > now()
    AND NOT EXISTS (
      SELECT 1 FROM election_sessions es
      WHERE es.club_id = cm.club_id
        AND es.position = cm.role
        AND es.status NOT IN ('completed','extended')
    )
    AND c.verification_status = 'verified';
$$);
 
SELECT cron.schedule('tally-votes', '35 18 * * *', $$
  UPDATE election_sessions es
  SET
    status           = 'pending_president_confirm'::election_status,
    winner_id        = (
      SELECT nominee_id FROM election_votes
      WHERE session_id = es.id
      GROUP BY nominee_id ORDER BY COUNT(*) DESC LIMIT 1
    ),
    confirm_deadline = now() + INTERVAL '12 hours'
  WHERE es.status = 'voting_open'
    AND es.voting_closes_at <= now()
    AND EXISTS (SELECT 1 FROM election_votes WHERE session_id = es.id);
$$);
 
SELECT cron.schedule('auto-confirm-elections', '40 18 * * *', $$
  WITH confirmed AS (
    UPDATE election_sessions
    SET status = 'completed'::election_status, auto_confirmed = true
    WHERE status = 'pending_president_confirm'
      AND confirm_deadline <= now()
    RETURNING id, club_id, position, winner_id
  )
  UPDATE club_members cm
  SET
    role             = confirmed.position,
    role_valid_from  = now(),
    role_valid_until = now() + (
      SELECT (term_duration_months || ' months')::INTERVAL
      FROM clubs WHERE id = confirmed.club_id
    )
  FROM confirmed
  WHERE cm.id = confirmed.winner_id;
$$);
 
SELECT cron.schedule('extend-empty-elections', '45 18 * * *', $$
  WITH extended AS (
    UPDATE election_sessions
    SET status = 'extended'::election_status
    WHERE status = 'voting_open'
      AND voting_closes_at <= now()
      AND NOT EXISTS (
        SELECT 1 FROM election_votes WHERE session_id = election_sessions.id
      )
    RETURNING id, club_id, position
  )
  UPDATE club_members cm
  SET role_valid_until = role_valid_until + INTERVAL '30 days'
  FROM extended
  WHERE extended.club_id  = cm.club_id
    AND extended.position = cm.role;
$$);
 
 
-- ============================================================
-- STEP 14: AUTH SYSTEM PREREQUISITES
-- Run these before starting the app
-- ============================================================
-- Add vice_president role (missing from original schema)
-- Note: In PostgreSQL, adding an enum value and using it in the same transaction causes an error.
-- The COMMIT; ensures it's saved before the policies use it.
ALTER TYPE member_role ADD VALUE IF NOT EXISTS 'vice_president' AFTER 'president';
COMMIT;

-- Add enabled_roles column to clubs
ALTER TABLE clubs 
  ADD COLUMN IF NOT EXISTS enabled_roles member_role[] 
  NOT NULL DEFAULT ARRAY['president','secretary','treasurer']::member_role[];

-- Add role_term_months per role per club
CREATE TABLE IF NOT EXISTS club_role_terms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id     UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  role        member_role NOT NULL,
  duration_months INT NOT NULL DEFAULT 12,
  UNIQUE(club_id, role)
);

-- Add club_code column (set by admin on approval)
ALTER TABLE clubs 
  ADD COLUMN IF NOT EXISTS club_code TEXT UNIQUE;

-- Add tv_session table for QR-based TV auth
CREATE TABLE IF NOT EXISTS tv_sessions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id     UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  qr_token    TEXT UNIQUE NOT NULL,
  member_id   UUID REFERENCES club_members(id),
  is_verified BOOLEAN NOT NULL DEFAULT false,
  expires_at  TIMESTAMPTZ NOT NULL DEFAULT now() + INTERVAL '5 minutes',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on new tables
ALTER TABLE club_role_terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE tv_sessions     ENABLE ROW LEVEL SECURITY;

CREATE POLICY "role_terms_club_read" ON club_role_terms FOR SELECT
  USING (has_role(club_id, ARRAY['member','secretary','treasurer','vice_president','president','founding_admin']::member_role[]));

CREATE POLICY "tv_sessions_insert" ON tv_sessions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "tv_sessions_read" ON tv_sessions FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- ============================================================
-- STEP 15: INSERT YOUR SUPER ADMIN
-- Replace the UUID and details with your actual Supabase auth user ID
-- ============================================================
-- INSERT INTO super_admins (id, full_name, email)
-- VALUES (
--   'your-auth-user-uuid-here',
--   'Your Name',
--   'your@email.com'
-- )
-- ON CONFLICT (id) DO NOTHING;

