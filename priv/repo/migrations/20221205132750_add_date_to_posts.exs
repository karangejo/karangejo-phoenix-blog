defmodule KarangejoBlog.Repo.Migrations.AddDateToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :date, :date
    end
  end
end
