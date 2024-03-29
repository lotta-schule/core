defmodule Lotta.Repo.TenantMigrations.ChangePreviewAndBannerImageFilesOnDeleteToNothing do
  @moduledoc false

  use Ecto.Migration

  def up do
    drop(constraint(:categories, "categories_banner_image_file_id_fkey"))

    alter table(:categories) do
      modify(:banner_image_file_id, references(:files, on_delete: :nilify_all))
    end

    drop(constraint(:articles, "articles_preview_image_file_id_fkey"))

    alter table(:articles) do
      modify(:preview_image_file_id, references(:files, on_delete: :nilify_all))
    end
  end

  def down do
    drop(constraint(:categories, "categories_banner_image_file_id_fkey"))

    alter table(:categories) do
      modify(:banner_image_file_id, references(:files, on_delete: :delete_all))
    end

    drop(constraint(:articles, "articles_preview_image_file_id_fkey"))

    alter table(:articles) do
      modify(:preview_image_file_id, references(:files, on_delete: :delete_all))
    end
  end
end
