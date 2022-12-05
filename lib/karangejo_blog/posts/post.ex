defmodule KarangejoBlog.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :name, :string
    field :content, :string
    field :date, :date

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:content, :name, :date])
    |> validate_required([:content, :name, :date])
  end
end
