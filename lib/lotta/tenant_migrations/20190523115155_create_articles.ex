defmodule Lotta.Repo.TenantMigrations.CreateArticles do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:articles) do
      add(:title, :string)
      add(:preview, :string)
      add(:page_name, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:articles, [:user_id]))
  end
end
