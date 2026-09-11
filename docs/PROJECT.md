# Project

A shared, sign-in-free board that shows who is standing at which position right now.

## What this application does

A group agrees on a fixed set of six named **zones** (e.g. "Big Oak", "River Meadow", "Home").
Anyone who opens the app sees, live, how many people are in each zone. Tapping a zone checks you in
there; you hold at most one zone at a time, so tapping another moves you. Every browser sees every
change without reloading.

## Audiences

- **Participant** — anyone who opens the app. No sign-in needed: an opaque token in the session
  cookie identifies the browser and maps to a `Participant` record with a generated display name.
- **User** — a signed-in account (magic link, OIDC, or a seeded password user). A signed-in user
  always maps to the same participant, whatever the cookie.
- **Admin** — the template's authenticated user with the `admin` role; only needed for `/oban` and
  `/dev`. Magic-link/OIDC auth is wired but unused by the board.

## Domain vocabulary

- **Position / zone** — a fixed, seeded place people can check into (`MyApp.Positions.Position`).
  The UI and conversations say "zone"; the code says "position".
- **Participant** — an anonymous browser identity (`MyApp.Positions.Participant`).
- **Check-in** — one visit: a participant at a position from `checked_in_at` until
  `checked_out_at` (`MyApp.Positions.CheckIn`).
- **Active** — a check-in with `checked_out_at` nil. A participant has at most one.
- **Occupant count** — number of active check-ins at a position.

## Business rules worth knowing

- At most one active check-in per participant, enforced by a partial unique index; switching
  positions closes the previous check-in in the same transaction.
- Re-tapping the current position is a no-op (the open check-in is returned untouched).
- Every check-in/check-out broadcasts on the `check_ins:updated` PubSub topic; the board reloads on it.
- Positions are seeded by `priv/repo/seeds.exs` (upsert on name); there is no management UI.
- Seeds also create 100 users (`user1..100@example.com`, password `password123`), each checked
  into a zone. Password registration is disabled in the UI; only sign-in is exposed.
