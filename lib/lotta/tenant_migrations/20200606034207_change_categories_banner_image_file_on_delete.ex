defmodule Lotta.Repo.TenantMigrations.ChangeCategoriesBannerImageFileOnDelete do
  @moduledoc false

  use Ecto.Migration

  def up do
    drop(constraint(:categories, "categories_banner_image_file_id_fkey"))

    alter table(:categories) do
      modify(:banner_image_file_id, references(:files, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:categories, "categories_banner_image_file_id_fkey"))

    alter table(:categories) do
      modify(:banner_image_file_id, references(:files, on_delete: :nothing))
    end
  end
end
