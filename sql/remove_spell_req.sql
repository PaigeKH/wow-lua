-- Reset all first_spell_id values to match spell_id
-- This makes every spell its own root in the rank chain.

UPDATE spell_ranks
SET first_spell_id = spell_id;
