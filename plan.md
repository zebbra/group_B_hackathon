# Big Oak — Position Check-in

## Context

`big_oak_prototype.html` is a 2.6 MB self-unpacking design bundle. Decoded, it contains a single
screen — **"Position check-in"**:

- Five named positions (`Big Oak`, `River Meadow`, `Sunny Field`, `Rock Hill`, `The Green Corner`)
  rendered as large tap targets.
- Each shows a live occupant count (`ph-users` icon + number) and a bar whose width is the count
  relative to the busiest position.
- Tapping a position checks you in there; you hold **at most one** position at a time, so tapping a
  different one moves you.
- A **Clear position** button checks you out.
- A **Today** list of recent check-ins (name + `HH:MM`), capped at 8 entries.
- The prototype also computes a `"Since 14:32 · 23 min"` label (refreshed on a 15 s timer) that its
  markup never renders — we render it.

The prototype fakes everything: occupant counts are a hardcoded `OTHERS` map, state lives in
`localStorage`, there is one browser and no server.

The repo is the pristine `BigOak` Phoenix 1.8 + Ash 3 template — one Ash domain (`BigOak.Accounts`),
one LiveView (`/` → `Live.Start`, a "Landing" placeholder), no PubSub usage, no Presence, empty
`docs/PROJECT.md`.

**Goal:** make the prototype real. Positions, occupancy and history become Ash resources backed by
Postgres; counts are true counts across everyone connected and update live via PubSub. Anyone who
opens the app in a browser becomes a distinct participant with **no sign-in** — identity is an
opaque token in the Phoenix session cookie, so it survives reloads and server restarts.

Decisions already taken with the user:

| | |
|---|---|
| **Identity** | Anonymous per browser, session-cookie token → `Participant` record. Magic-link/OIDC auth stays wired but unused. |
| **Positions** | Fixed set, seeded from `priv/repo/seeds.exs`. No management UI. |
| **Look** | Project daisyUI theming + core components (not a port of the prototype's "Nocturne" palette). Theme toggle and locale switcher keep working. |
| **Today list** | **Global** activity feed (everyone's check-ins), live-updating — not the prototype's private per-user list. |

---

## 1. Domain layer — new `BigOak.Positions` domain

New files under `lib/big_oak/positions/`. Follow `lib/big_oak/accounts/user.ex` and
`token.ex` for block shape; **never hand-order the DSL sections** — the Spark formatter
`section_order` at `config/config.exs:142-171` rewrites them on `mix format`.

### `lib/big_oak/positions.ex` — `Ash.Domain`

Mirrors `lib/big_oak/accounts.ex:1-11`. Register all three resources.

Then add it to the domain list: `config/config.exs:130` →
`ash_domains: [BigOak.Accounts, BigOak.Positions]`. This list is also what
`lib/big_oak/application.ex:31-34` feeds to `AshOban.config/2`, so it must be updated there and
nowhere else.

### `lib/big_oak/positions/position.ex`

`AshPostgres.DataLayer`, `authorizers: [Ash.Policy.Authorizer]`, table `positions`.

- **attributes** — `uuid_primary_key :id`; `name :string` (required, public); `sort_order :integer`
  (required, default `0`, public); `create_timestamp`/`update_timestamp`.
- **identities** — `identity :unique_name, [:name]`.
- **relationships** — `has_many :check_ins, BigOak.Positions.CheckIn`.
- **aggregates** — `count :occupant_count, :check_ins do filter expr(is_nil(checked_out_at)) end`.
- **actions** — `defaults [:read]`; `create :seed` (accepts `[:name, :sort_order]`, `upsert? true`,
  `upsert_identity :unique_name`, `upsert_fields [:sort_order]`) so seeding is idempotent;
  `read :board` with `prepare build(sort: [sort_order: :asc, name: :asc], load: [:occupant_count])`.
- **code_interface** — `define :board, action: :board`, `define :seed, action: :seed`.
- **policies** — the board is public: `policy action_type(:read) do authorize_if always() end`;
  restrict `:seed` to `authorize_if always()` and call it with `authorize?: false` from seeds
  (matching how `test/support/fixtures/accounts_fixtures.ex:75` calls real actions).

### `lib/big_oak/positions/participant.ex`

The anonymous browser identity. Table `participants`.

- **attributes** — `uuid_primary_key :id`; `session_token :string` (required, `sensitive? true`,
  not public); `display_name :string` (required, public); `last_seen_at :utc_datetime_usec`;
  timestamps.
- **identities** — `identity :unique_session_token, [:session_token]`.
- **relationships** — `has_many :check_ins, BigOak.Positions.CheckIn`.
- **actions** — a single upsert is the whole lifecycle and avoids a find-or-create race:

  ```
  create :ensure do
    accept [:session_token]
    upsert? true
    upsert_identity :unique_session_token
    upsert_fields [:last_seen_at]
    change set_attribute(:last_seen_at, &DateTime.utc_now/0)
    change BigOak.Positions.Changes.GenerateDisplayName   # only when display_name is nil
  end
  ```
  plus `defaults [:read]` and `read :get_by_session_token do get_by :session_token end`.
- **code_interface** — `define :ensure, action: :ensure`.
- **policies** — `authorize_if always()` (there is no actor; the token in the cookie *is* the
  credential, and it never leaves the server after mount).

**`lib/big_oak/positions/changes/generate_display_name.ex`** — an `Ash.Resource.Change` that picks a
friendly two-word handle (adjective + animal, e.g. `"Quiet Fox"`) from small module-attribute word
lists, with a numeric suffix on collision. Keep the word lists untranslated: they are identifiers,
not UI copy, so they stay out of gettext.

### `lib/big_oak/positions/check_in.ex`

An open/closed interval — one row per visit. Table `check_ins`.

- **attributes** — `uuid_primary_key :id`; `checked_in_at :utc_datetime_usec` (required, default
  `&DateTime.utc_now/0`, public); `checked_out_at :utc_datetime_usec` (nullable, public).
- **relationships** — `belongs_to :participant, Participant` (required);
  `belongs_to :position, Position` (required).
- **postgres** — `references do reference :participant, on_delete: :delete; reference :position,
  on_delete: :delete end` (pattern from `lib/big_oak/accounts/user_identity.ex:17-24`), plus the
  invariant as a partial unique index:

  ```
  custom_indexes do
    index [:participant_id],
      unique: true,
      where: "checked_out_at IS NULL",
      name: "check_ins_one_active_per_participant_index"
  end
  ```
- **actions**
  - `read :active_for_participant` — `argument :participant_id, :uuid`, `get? true`,
    `filter expr(participant_id == ^arg(:participant_id) and is_nil(checked_out_at))`.
  - `create :check_in` — arguments `participant_id`, `position_id`. A `change` module
    (`Changes.CloseOpenCheckIn`) hooks `Ash.Changeset.before_action/2` to stamp `checked_out_at` on
    the participant's currently-open row, so the switch is atomic inside the create's transaction
    and the partial index can never be violated. Idempotent: if the open row is already at
    `position_id`, return it untouched rather than churning `checked_in_at`.
  - `update :check_out` — `change set_attribute(:checked_out_at, &DateTime.utc_now/0)`, guarded by a
    validation that `checked_out_at` is still nil.
  - `read :todays_feed` — `argument :since, :utc_datetime_usec`, `argument :limit, :integer`
    (default 8), `filter expr(checked_in_at >= ^arg(:since))`,
    `prepare build(sort: [checked_in_at: :desc], load: [:participant, :position], limit: ...)`.
- **code_interface** — `define :check_in`, `define :check_out`, `define :active_for_participant`,
  `define :todays_feed`.
- **pub_sub** — this is the live-update engine. Add `Ash.Notifier.PubSub` to `notifiers:` and:

  ```
  pub_sub do
    module BigOakWeb.Endpoint
    prefix "check_ins"
    publish_all :create, ["updated"]
    publish_all :update, ["updated"]
  end
  ```
  Every check-in/check-out broadcasts on `"check_ins:updated"`. One coarse topic is right here: the
  board shows *all* positions, so every change is relevant to every viewer.
- **policies** — `authorize_if always()`. Ownership is enforced structurally: the LiveView only ever
  passes `@current_participant.id`, which comes from the server-side session, never from the client.

### Migrations + seeds

- `mix ash.codegen add_positions` → commit both `priv/repo/migrations/*` and
  `priv/resource_snapshots/repo/{positions,participants,check_ins}/*.json`. `mix lint` runs
  `ash.codegen --check`, so an uncommitted snapshot fails CI.
- `priv/repo/seeds.exs` — currently just the stock comment block. Append an idempotent seed over the
  five prototype names via `Position.seed(%{name: ..., sort_order: i}, authorize?: false)`. `mix
  setup` already runs it.

---

## 2. Anonymous identity plumbing (web layer)

Two small pieces. The cookie can only be written by a plug (a LiveView cannot set cookies), and the
LiveView reads it from the session snapshot it receives at mount.

**`lib/big_oak_web/plugs/participant_session.ex`** — mint a token on first visit:

```elixir
def call(conn, _opts) do
  if get_session(conn, "participant_token"),
    do: conn,
    else: put_session(conn, "participant_token", Ash.UUID.generate())
end
```

**`lib/big_oak_web/router.ex`** — a dedicated pipeline rather than widening `:browser` (which is
also used by `/dev`, `/oban` and the mailbox preview, none of which want participant rows):

```elixir
pipeline :participant do
  plug BigOakWeb.Plugs.ParticipantSession
end

scope "/", BigOakWeb.Live do
  pipe_through [:locale, :browser, :participant]

  ash_authentication_live_session :authenticated_routes, on_mount: [LiveLocale] do
    live "/", CheckIn
  end
end
```

**`lib/big_oak_web/hooks/live_participant.ex`** — `on_mount` hook next to the existing
`hooks/live_user_auth.ex` and `hooks/live_locale.ex`:

```elixir
def on_mount(:default, _params, session, socket) do
  participant =
    case session["participant_token"] do
      token when is_binary(token) -> Participant.ensure!(%{session_token: token}, authorize?: false)
      _ -> nil
    end

  {:cont, assign(socket, :current_participant, participant)}
end
```

Declared in the LiveView module itself (the template's convention — see `live/start.ex:8` and the
router comment at `router.ex:69-79`), not in the `live_session`.

Two notes for whoever implements this:

- `mount/3` runs twice (static render, then connected). The upsert runs twice; it is idempotent and
  only refreshes `last_seen_at`, so this is harmless — do **not** guard it behind `connected?/1`,
  because the static render needs the participant to show the right active position.
- A nil token (cookies disabled, or a `ConnCase` test that never went through the plug) assigns
  `nil`. The template must render the board read-only in that case and show a `~t` notice, rather
  than crashing.

---

## 3. LiveView — `lib/big_oak_web/live/check_in.ex`

Replaces the `Live.Start` placeholder at `/`. Delete `lib/big_oak_web/live/start.ex` and
`test/big_oak_web/live/start_test.exs`, porting that test's locale-switcher assertions
(`start_test.exs:35-42`) into the new LiveView test.

Copy the exact shape of `live/start.ex`: `use BigOakWeb, :live_view`, `@impl` + `@spec` on every
callback (`.doctor.exs` demands 100 % moduledoc coverage and dialyzer is configured), `|> ok()` /
`|> noreply()` from `BigOakWeb.Helpers`, `~t` on every user-visible string, and the whole template
inside `<Layouts.app flash={@flash} current_user={@current_user} socket={@socket}>`. Its
`max-w-2xl` container matches the prototype's 520 px column — no layout change needed.

```elixir
on_mount {BigOakWeb.Hooks.LiveUserAuth, :live_user_optional}
on_mount {BigOakWeb.Hooks.LiveParticipant, :default}
```

**mount/3**

- `if connected?(socket) do BigOakWeb.Endpoint.subscribe("check_ins:updated") end`
- `if connected?(socket) do :timer.send_interval(15_000, self(), :tick) end` — drives the
  `"Since … · 23 min"` label exactly like the prototype's `setInterval`.
- `assign(:page_title, ~t"Position check-in")`, then `load_board/1`.

**`load_board/1`** (private) assigns, in one place so `mount` and `handle_info` share it:

- `:positions` — `Position.board!()` (sorted, `occupant_count` loaded)
- `:max_count` — `Enum.max_by(...)` floored at 1, for the bar widths
- `:active_check_in` — `CheckIn.active_for_participant!(participant.id)` or `nil`
- `:feed` — `CheckIn.todays_feed!(%{since: start_of_today_utc(), limit: 8})`
- `:now` — `DateTime.utc_now()`

**Events**

- `handle_event("select", %{"id" => id}, socket)` → `CheckIn.check_in!(%{participant_id: ...,
  position_id: id})`, then `load_board/1`. No-op when `@current_participant` is nil.
- `handle_event("clear", _, socket)` → `CheckIn.check_out!(active)` when one exists.

**Messages**

- `handle_info(%Phoenix.Socket.Broadcast{topic: "check_ins:updated"}, socket)` → `load_board/1`.
  The acting client also receives its own broadcast; reloading twice is cheap and keeps one code
  path.
- `handle_info(:tick, socket)` → `assign(:now, DateTime.utc_now())`.

### Template

daisyUI + core components only — **no hand-rolled primitives** (`AGENTS.md`), and no interpolated
class names (`"btn-#{x}"` is invisible to Tailwind's scanner): branch with complete literals.

```
Position check-in            ← uppercase tracked eyebrow + hairline divider
Since 14:32 · 23 min         ← only when @active_check_in

[ Big Oak                 👥 4 ]   ← <button phx-click="select" phx-value-id>
  ▓▓▓▓▓▓▓▓░░░░░░░░░░                 <progress class="progress progress-primary">
[ River Meadow            👥 1 ]
  ▓▓░░░░░░░░░░░░░░░░
…

[ ⊗  Clear position           ]   ← <.button>, full width, disabled when not checked in

TODAY
Quiet Fox        → Big Oak      14:32
Brisk Heron      → Sunny Field  14:05
```

- Position tiles: `<button type="button" phx-click="select" phx-value-id={p.id}>` carrying
  `card`/`border`/`rounded-box` classes; the active one swaps to
  `border-primary bg-primary/10 ring-1 ring-primary` via a `case`/`if` returning literal strings.
  Icon: `<.icon name="tabler-users" class="size-4" />` (Tabler replaces the prototype's Phosphor
  `ph-users`; `tabler-users-group` for the active state).
- Occupancy bar: `<progress class="progress progress-primary" value={count} max={@max_count} />` —
  a native element, so no inline `style` and nothing for the CSP nonce plug to worry about.
- Add `transition-colors duration-150` and `hover:border-primary` for the prototype's
  micro-interaction feel.
- Every string through `~t`; position names and participant display names come from the DB and stay
  as-is. Run `mix gettext.extract --merge` afterwards — `mix lint` fails on a stale catalogue.

### Times and the "Today" boundary

The repo has **no timezone database** (no `tzdata`/`tz` in `mix.lock`), so `DateTime` is UTC-only
today. Add `{:tz, "~> 0.28"}` to `mix.exs` and `config :elixir, :time_zone_database,
Tz.TimeZoneDatabase`, plus `config :big_oak, :display_time_zone, "Europe/Zurich"`. A small
`BigOakWeb.Live.CheckIn` private helper converts `checked_in_at` into that zone and renders it with
`BigOakWeb.Cldr.DateTime.to_string!(dt, format: :hm)` so `HH:MM` follows the active locale;
`start_of_today_utc/0` derives the feed cutoff from the same zone. If the team would rather not take
the dependency, drop both and use UTC — but then "Today" rolls over at the wrong hour.

---

## 4. Docs

`docs/PROJECT.md` is an unfilled placeholder and `AGENTS.md` points agents at it. Fill in the
product context this feature establishes: what the app is (a shared, sign-in-free board showing who
is standing where), the audiences, and the vocabulary — **position**, **participant**, **check-in**,
**active**, **feed** — so later work uses the same words as the code.

---

## 5. Tests

Follow the existing patterns exactly: `use BigOak.DataCase, async: true` for the domain,
`use BigOakWeb.ConnCase` + `import Phoenix.LiveViewTest` for the LiveView, and fixtures that go
through **real Ash actions** with `authorize?: false` rather than `Repo.insert` (the model is
`test/support/fixtures/accounts_fixtures.ex:69-77`).

- **`test/support/fixtures/positions_fixtures.ex`** — `position_fixture/1`, `participant_fixture/1`,
  `check_in_fixture/2`.
- **`test/big_oak/positions/check_in_test.exs`**
  - checking in creates an open row and bumps the position's `occupant_count`
  - checking into a second position closes the first (exactly one open row remains)
  - re-tapping the current position is a no-op (`checked_in_at` unchanged)
  - `check_out` stamps `checked_out_at` and drops the count back
  - the partial unique index rejects a hand-crafted second open row
- **`test/big_oak/positions/participant_test.exs`** — `ensure` is idempotent per token, mints
  distinct participants for distinct tokens, refreshes `last_seen_at`, assigns a display name once.
- **`test/big_oak_web/live/check_in_test.exs`**
  - a fresh `conn` mounting `/` creates exactly one participant, and a reload reuses it
  - clicking a position renders the incremented count and the "Since …" label
  - **cross-client liveness**: mount two LiveViews from two separate conns/sessions, click in one,
    assert the *other* re-renders with the new count (this is the requirement's core — it proves
    both the distinct-participant rule and the PubSub wiring)
  - "Clear position" removes the active state
  - the ported locale-switcher assertions from `start_test.exs`

---

## Verification

```bash
mix ash.setup                     # create DB + run the new migration
mix run priv/repo/seeds.exs       # five positions
mix test
mix precommit                     # gettext + format + credo + sobelow + codegen check + tests
```

Then the manual check that actually demonstrates the requirement (the `tidewave` MCP server failed
to connect this session, so this is a browser check):

1. `mix phx.server`
2. Open <http://localhost:4000> in a normal window **and** a private window — two cookies, so two
   participants. Confirm the navbar still shows the locale switcher, theme toggle and "Sign in".
3. Click **Big Oak** in window A → its count goes to 1 and **window B updates without a reload**.
4. Click **River Meadow** in window B → Big Oak stays at 1, River Meadow shows 1, both windows agree.
5. Click **Sunny Field** in window A → Big Oak drops to 0 in both windows (the switch closed A's
   previous check-in).
6. Reload window A → it is still checked in at Sunny Field with its original "Since" time, proving
   identity survives a reload.
7. **Clear position** in window A → count drops in both windows; the Today feed keeps both
   participants' entries.
8. Toggle the theme and switch locale to `de`/`fr` → the chrome translates, position names stay.