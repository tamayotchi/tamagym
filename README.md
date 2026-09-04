# tamagym

A Phoenix LiveView gym and body-weight tracker with SQLite persistence, email/password accounts, and an optional local-only mode.

## Included

- Phoenix 1.8 and LiveView
- Ecto with SQLite
- Email/password accounts with bcrypt password hashes
- Encrypted, HTTP-only session cookies and CSRF protection
- Local-only use without creating an account
- Routines, weekly plans, and recurring sports with start times and durations
- Active workouts with editable weight, reps, and sets
- Workout history, training totals, and body-weight tracking
- Built-in exercise catalogue with images and animations
- Custom exercises and profile settings
- Optional AI-generated seven-day plans and exercise alternatives
- English and Spanish interfaces
- PWA installation in supported browsers

The browser code under `assets/` contains only the small hooks LiveView needs for local-only persistence, elapsed time, screen wake lock, theme preferences, and PWA registration. Application rendering and state transitions live in Phoenix.

## Run locally

Requirements:

- Elixir 1.19+
- Erlang/OTP 28+
- Git, for the automatic exercise-media download

Run the one-time setup:

```bash
mix setup
```

Start the application:

```bash
mix phx.server
```

Open <http://localhost:4000>.

The server applies pending SQLite migrations, checks the exercise media, builds the LiveView assets, and starts Phoenix. Development data is stored in `tamagym_dev.db`.

## AI planning (optional)

AI calls use [ReqLLM](https://hex.pm/packages/req_llm), so Tamagym is not tied to one provider. Enable one or more model specifications with a comma-separated environment variable and provide the corresponding provider credentials:

```bash
AI_MODELS="openai:gpt-4o-mini,anthropic:claude-haiku-4-5"
OPENAI_API_KEY="..."
ANTHROPIC_API_KEY="..."
```

`AI_MODEL` is accepted as a shorthand when only one model is enabled. ReqLLM also supports Google, OpenRouter, Groq, Ollama-compatible services, and other providers; use their documented model specification and credential variables.

Each account—or each local-only browser—can choose one of the enabled models in Settings. API keys remain server-side and are never saved in user gym data. The feature is hidden when no AI model is configured. Generating a plan sends the selected goal, compact exercise catalogue, current plan, and recent four-week workout history to the selected provider. Generated plans use complete commercial-gym sessions and, after review and approval, update both the next seven exact dates and the recurring weekly schedule. A weekday can also generate a new routine from one to three selected muscle groups. The planner can optionally prescribe a drop-set on the last set of one suitable exercise; the technique is shown in the preview and stored in the routine. Applying either kind of plan creates new routines and never deletes existing user or AI routines.

## Exercise media

The media check runs before `mix phx.server`. Missing catalogue files are downloaded automatically. You can also run:

```bash
mix media.setup
```

Exercise metadata and instruction text come from `hasaneyldrm/exercises-dataset` under MIT. Images and animations are © Gym visual and are downloaded under that dataset's terms. See [NOTICE.md](NOTICE.md).

## Commands

```bash
mix setup          # dependencies, database, and LiveView assets
mix phx.server     # migrate, ensure media, build assets, and start Phoenix
mix assets.build   # build assets once
mix assets.deploy  # minified production assets and digest
mix media.setup    # check/download exercise media
mix test           # Phoenix, LiveView, account, and persistence tests
mix precommit      # compile, format, and run all tests
```

To reset local development accounts and gym data:

```bash
mix ecto.reset
```

## Architecture

The authenticated LiveView loads and saves each account through `Tamagym.Gym`. Training data remains relational:

```text
users
├── user_settings
├── routines
├── day_overrides
├── workouts
├── body_weights
└── custom_exercises
```

Local-only mode uses the same state transformations but stores the document in browser `localStorage`; it does not call the account data API. The existing JSON API remains available for integrations and backwards compatibility.

The built-in exercise catalogue lives at `priv/catalogue/exercises.json` and is exposed through `Tamagym.Gym.Catalogue`.

License: AGPL-3.0-or-later.
