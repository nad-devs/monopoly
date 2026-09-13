# Monopoly Cash

Four to six phones, one shared ledger. No banker, no play money, no property tracking.

You tap a player, type an amount, and it moves. That's the whole app.

## Setting it up

**1. Make a Supabase project** — [supabase.com](https://supabase.com), free tier, ~3 minutes.

**2. Run the schema** — open your project → SQL Editor → paste all of `supabase.sql` → Run.

**3. Paste your keys** — Supabase → Project Settings → API. Copy the Project URL and the `anon` public key into the top of `index.html`:

```js
const SUPABASE_URL = "https://xxxxx.supabase.co";
const SUPABASE_KEY = "eyJhbGci...";
```

**4. Put it somewhere phones can reach.** Any static host. GitHub Pages is easiest:

```
git remote add origin git@github.com:YOU/monopoly.git
git push -u origin main
```

Then Settings → Pages → deploy from `main` / root. Everyone opens the same URL.

For testing on one machine: `python3 -m http.server 8000` and visit `localhost:8000`.

## Playing

One person taps **New game** and reads out the 4-letter code. Everyone else types it in. Tap **Start** when the seats look right.

Everyone starts with **$1,500**.

- **Pay someone** — tap their tile, type the amount, tap Pay.
- **Pass Go / collect from the bank** — tap the gold Bank tile, type the amount, tap **Collect**.
- **Pay the bank** (tax, houses, fees) — same tile, tap **Pay bank** instead.
- **Undo** — bottom right. Removes the most recent payment, whoever made it. It names the payment before it undoes it.
- **Went bankrupt** — the `⋯` menu, scroll past the bottom, **I'm out**. It asks who takes your remaining cash, per the real rule: your property cards go to whoever bust you, by hand.
- **Ending together** — `⋯` → **Call it**. Freezes the game, shows final cash standings.

Balances can go negative. That's deliberate — mortgage and sell at the table, the app won't stop you.

## What it deliberately does not do

Property, houses, rent tables, auctions, trades. Those stay on the board where they're fast. The app only exists because counting paper money is slow.

Standings rank on **cash only**. If you end with property still in hand, settle that yourselves.

## How it works

Balances are never stored. The `entries` table is append-only, and every balance is `1500 + sum(deltas)`. So two people paying at the same moment can't clobber each other, and undo is just deleting the last row.

Your seat is kept in `localStorage` — lock your phone or close the tab and you come back to the same player.
