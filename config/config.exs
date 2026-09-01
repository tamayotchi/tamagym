# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :tamagym,
  namespace: Tamagym,
  ecto_repos: [Tamagym.Repo],
  media_dir: Path.expand("../media", __DIR__),
  secure_cookies: false,
  ai_models: [],
  ai_client: Tamagym.AI.ReqLLM,
  generators: [timestamp_type: :utc_datetime_usec]

# Configures the endpoint
config :esbuild,
  version: "0.25.4",
  tamagym: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/img/* --external:/gif/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tamagym, TamagymWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TamagymWeb.ErrorHTML, json: TamagymWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Tamagym.PubSub,
  live_view: [signing_salt: "iZSv9ANH"]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
