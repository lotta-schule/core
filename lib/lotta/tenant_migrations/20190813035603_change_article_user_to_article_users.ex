defmodule Lotta.Repo.TenantMigrations.ChangeArticleUserToArticleUsers do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:articles) do
      remove(:user_id)
    end
  end
end
