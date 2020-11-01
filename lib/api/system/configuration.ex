defmodule Api.System.Configuration do
  @moduledoc """
    Ecto Schema for system configuration
  """

  alias Api.Accounts.File

  use Ecto.Schema

  @primary_key false
  schema "configuration" do
    field :name, :string
    field :string_value, :string
    field :json_value, :map

    belongs_to :file_value, File

    timestamps()
  end

  @type t :: %__MODULE__{name: String.t()}

  @type value :: File.t() | String.t() | map()
end