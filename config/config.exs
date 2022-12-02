# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :karangejo_blog,
  ecto_repos: [KarangejoBlog.Repo]

# Configures the endpoint
config :karangejo_blog, KarangejoBlogWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GR/2qf40tnlpK1O7/i7/XMqya9V9t0ehSkrMtSs0gpy8vV/GhoA+ZMM0L/vATc/I",
  render_errors: [view: KarangejoBlogWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: KarangejoBlog.PubSub,
  live_view: [signing_salt: "FtmjrAk4"]

# Configure esbuild
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
