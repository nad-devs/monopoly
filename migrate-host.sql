-- Run this once in Supabase → SQL Editor.
-- Adds a host (whoever made the game) and a started flag so the host's
-- tap moves everyone's screen at once, instead of each phone starting itself.

alter table games add column if not exists host_id    uuid;
alter table games add column if not exists started_at timestamptz;

-- Existing games: hand the host seat to whoever joined first, and treat any
-- game with money already on the table as started.
update games g set host_id = (
  select p.id from players p where p.code = g.code order by p.seat limit 1
) where g.host_id is null;

update games g set started_at = now()
where g.started_at is null
  and exists (select 1 from entries e where e.code = g.code);
