defmodule Api.Accounts.UserEnrollmentToken do
  @moduledoc """
    Ecto Schema for user enrollment tokens.
    A UserEnrollmentToken is a token a user enters in order to be granted permission to enter a group.
    If a GroupEnrollmentToken is a lock, then the UserEnrollmentToken is the key.
  """

  use Ecto.Schema

  alias Api.Accounts.User

  schema "users_enrollment_tokens" do
    field :enrollment_token, :string

    belongs_to :user, User

    timestamps()
  end
end
