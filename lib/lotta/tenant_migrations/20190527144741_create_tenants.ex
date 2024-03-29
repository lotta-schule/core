defmodule Lotta.Repo.TenantMigrations.CreateTenants do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:tenants) do
      add(:slug, :string)
      add(:title, :string)

      timestamps()
    end
  end
end
