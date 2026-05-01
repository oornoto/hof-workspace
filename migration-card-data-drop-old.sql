-- =============================================================================
-- Drop old source tables after card_data migration is verified
-- Date: 2026-05-01
--
-- Drops:
--   collection_planner.player_appearances  (has FK → collection_planner.sets,
--                                           so must be dropped first)
--   collection_planner.sets
--
-- Does NOT touch:
--   collection_planner.decisions   (FK already re-pointed to card_data.sets)
--   collection_planner.custom_data (unrelated to this migration)
--
-- Prerequisites before running:
--   - card_data.sets row count verified (778)
--   - card_data.player_appearances row count verified (1617)
--   - Collection Planner frontend verified working against card_data
-- =============================================================================

BEGIN;

DROP TABLE collection_planner.player_appearances;
DROP TABLE collection_planner.sets;

COMMIT;
