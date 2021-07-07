defmodule Lotta.Repo.TenantMigrations.ChangeMessagingContentFromStringToText do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify(:content, :text, from: :string)
    end
  end
end
