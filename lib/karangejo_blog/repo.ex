defmodule KarangejoBlog.Repo do
  use Ecto.Repo,
    otp_app: :karangejo_blog,
    adapter: Ecto.Adapters.Postgres
end
