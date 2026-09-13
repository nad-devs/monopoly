-- Paste this into Supabase → SQL Editor → Run.
-- Two tables. No auth. Anyone with the 4-letter code can play.

create table if not exists games (
  code        text primary key,
  created_at  timestamptz not null default now(),
  host_id     uuid,           -- whoever made the game; only they can start it
  started_at  timestamptz,    -- set by the host's tap, moves every phone at once
  ended_at    timestamptz
);

create table if not exists players (
  id          uuid primary key default gen_random_uuid(),
  code        text not null references games(code) on delete cascade,
  name        text not null,
  seat        int  not null,
  is_out      boolean not null default false,
  nfc_id      text,            -- the slug on that person's sticker. Survives games; id does not.
  created_at  timestamptz not null default now()
);

-- For a database made before stickers existed.
alter table players add column if not exists nfc_id text;

-- Append-only ledger. Balance = 1500 + sum(deltas). Never updated, only inserted/deleted.
create table if not exists entries (
  id          bigserial primary key,
  code        text not null references games(code) on delete cascade,
  from_id     uuid,            -- null = the Bank
  to_id       uuid,            -- null = the Bank
  amount      int  not null,
  note        text,            -- 'payout', 'bust', etc. null for a plain payment
  created_at  timestamptz not null default now()
);

create index if not exists entries_code_idx on entries(code, id);
create index if not exists players_code_idx on players(code);

-- Realtime: every client watches its own game.
-- `add table` throws if the table is already in the publication, so this file
-- could only ever be run once. Skip the ones already there.
do $$
declare t text;
begin
  foreach t in array array['players', 'entries', 'games'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Open access. It's a party game on a shared wifi, not a bank.
alter table games   enable row level security;
alter table players enable row level security;
alter table entries enable row level security;

drop policy if exists "open" on games;
drop policy if exists "open" on players;
drop policy if exists "open" on entries;

create policy "open" on games   for all using (true) with check (true);
create policy "open" on players for all using (true) with check (true);
create policy "open" on entries for all using (true) with check (true);
