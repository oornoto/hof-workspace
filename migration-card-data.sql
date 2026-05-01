-- =============================================================================
-- Schema Reorganization: Introduce card_data shared schema
-- Date: 2026-05-01
--
-- What moves:
--   collection_planner.sets              → card_data.sets
--   collection_planner.player_appearances → card_data.player_appearances
--
-- What stays:
--   collection_planner.decisions         (FK re-pointed to card_data.sets)
--   collection_planner.custom_data       (unchanged)
--   card_gallery.*                       (unchanged)
--
-- Source tables are NOT dropped here. Drop them separately after:
--   1. Row counts verified
--   2. RLS verified
--   3. Frontend verified loading correctly
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Create shared schema and grant access to Supabase roles
-- ---------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS card_data;

GRANT USAGE ON SCHEMA card_data TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Create card_data.sets and copy data
-- ---------------------------------------------------------------------------

CREATE TABLE card_data.sets (
    id              integer          NOT NULL,
    name            text             NOT NULL,
    type            text             NOT NULL,
    type_mult       double precision NOT NULL,
    vintage_sampler boolean          NOT NULL,
    topps_sampler   boolean          NOT NULL,
    CONSTRAINT sets_pkey PRIMARY KEY (id)
);

INSERT INTO card_data.sets
SELECT * FROM collection_planner.sets;

ALTER TABLE card_data.sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read sets"
    ON card_data.sets
    FOR SELECT
    TO authenticated
    USING (true);

GRANT SELECT ON card_data.sets TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Create card_data.player_appearances and copy data
--    FK points to card_data.sets (not collection_planner.sets)
-- ---------------------------------------------------------------------------

CREATE TABLE card_data.player_appearances (
    id          integer NOT NULL,
    player_name text    NOT NULL,
    war_rank    integer,
    set_id      integer NOT NULL,
    tier        text    NOT NULL,
    first_tcs   boolean NOT NULL DEFAULT false,
    CONSTRAINT player_appearances_pkey PRIMARY KEY (id),
    CONSTRAINT player_appearances_set_id_fkey
        FOREIGN KEY (set_id) REFERENCES card_data.sets (id)
);

INSERT INTO card_data.player_appearances
SELECT * FROM collection_planner.player_appearances;

ALTER TABLE card_data.player_appearances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read player appearances"
    ON card_data.player_appearances
    FOR SELECT
    TO authenticated
    USING (true);

GRANT SELECT ON card_data.player_appearances TO anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. Re-point collection_planner.decisions.set_id → card_data.sets
--    (decisions stays in collection_planner; its FK moves to the new schema)
-- ---------------------------------------------------------------------------

ALTER TABLE collection_planner.decisions
    DROP CONSTRAINT decisions_set_id_fkey;

ALTER TABLE collection_planner.decisions
    ADD CONSTRAINT decisions_set_id_fkey
        FOREIGN KEY (set_id) REFERENCES card_data.sets (id);

COMMIT;

-- =============================================================================
-- POST-MIGRATION VERIFICATION (run these after COMMIT, before touching anything else)
-- Expected: card_data counts match collection_planner counts exactly
--           sets = 778, player_appearances = 1617
-- =============================================================================

-- SELECT 'card_data.sets'                        AS tbl, COUNT(*) FROM card_data.sets
-- UNION ALL
-- SELECT 'card_data.player_appearances'           AS tbl, COUNT(*) FROM card_data.player_appearances
-- UNION ALL
-- SELECT 'collection_planner.sets'               AS tbl, COUNT(*) FROM collection_planner.sets
-- UNION ALL
-- SELECT 'collection_planner.player_appearances'  AS tbl, COUNT(*) FROM collection_planner.player_appearances;
