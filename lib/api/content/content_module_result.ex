defmodule Api.Content.ContentModuleResult do
  @moduledoc """
    Ecto Schema for content module results
  """

  use Ecto.Schema

  schema "content_module_results" do
    field :result, :map

    belongs_to :content_module, Api.Content.ContentModule
    belongs_to :user, Api.Accounts.User

    timestamps()
  end
end
