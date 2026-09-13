-- Paste this into Supabase → SQL Editor → Run.
-- Two tables. No auth. Anyone with the 4-letter code can play.

create table if not exists games (
  code        text primary key,
  created_at  timestamptz not null default now(),
  ended_at    timestamptz
);

create table if not exists players (
  id          uuid primary key default gen_random_uuid(),
  code        text not null references games(code) on delete cascade,
  name        text not null,
  seat        int  not null,
  is_out      boolean not null default false,
  created_at  timestamptz not null default now()
);

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
alter publication supabase_realtime add table players;
alter publication supabase_realtime add table entries;
alter publication supabase_realtime add table games;

-- Open access. It's a party game on a shared wifi, not a bank.
alter table games   enable row level security;
alter table players enable row level security;
alter table entries enable row level security;

create policy "open" on games   for all using (true) with check (true);
create policy "open" on players for all using (true) with check (true);
create policy "open" on entries for all using (true) with check (true);
