defmodule Api.Content.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :preview, :string
    field :topic, :string
    field :ready_to_publish, :boolean
    
    belongs_to :tenant, Api.Tenants.Tenant
    belongs_to :category, Api.Tenants.Category, on_replace: :nilify
    belongs_to :preview_image_file, Api.Accounts.File, on_replace: :nilify
    
    has_many :content_modules, Api.Content.ContentModule, on_replace: :delete
    many_to_many(
      :users,
      Api.Accounts.User,
      join_through: "article_users",
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> Api.Repo.preload([:category, :users, :preview_image_file, :content_modules])
    |> cast(attrs, [:title, :inserted_at, :ready_to_publish, :preview, :topic, :category_id, :tenant_id])
    |> validate_required([:title, :tenant_id])
    |> put_assoc_users(attrs)
    |> put_assoc_category(attrs)
    |> put_assoc_preview_image_file(attrs)
    |> cast_assoc(:content_modules, required: false)
  end

  defp put_assoc_users(article, %{ users: users }) do
    users = Enum.map(users, fn user -> Api.Repo.get!(Api.Accounts.User, String.to_integer(user.id)) end)
    article
    |> put_assoc(:users, users)
  end

  defp put_assoc_category(article, %{ category: %{ id: category_id } }) do
    article
    |> put_assoc(:category, Api.Repo.get(Api.Tenants.Category, String.to_integer(category_id)))
  end
  defp put_assoc_category(article, _args) do
    article
    |> put_assoc(:category, nil)
  end

  defp put_assoc_preview_image_file(article, %{ preview_image_file: %{ id: preview_image_file_id } }) do
    article
    |> put_assoc(:preview_image_file, Api.Repo.get(Api.Accounts.File, String.to_integer(preview_image_file_id)))
  end
  defp put_assoc_preview_image_file(article, _args) do
    article
    |> put_assoc(:preview_image_file, nil)
  end
end
