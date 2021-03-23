defmodule KarangejoBlog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      KarangejoBlog.Repo,
      # Start the Telemetry supervisor
      KarangejoBlogWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: KarangejoBlog.PubSub},
      # Start the Endpoint (http/https)
      KarangejoBlogWeb.Endpoint
      # Start a worker by calling: KarangejoBlog.Worker.start_link(arg)
      # {KarangejoBlog.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KarangejoBlog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    KarangejoBlogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
