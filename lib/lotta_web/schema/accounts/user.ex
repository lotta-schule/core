defmodule LottaWeb.Schema.Accounts.User do
  @moduledoc false

  use Absinthe.Schema.Notation

  input_object :register_user_params do
    field :name, :string
    field :nickname, :string
    field :hide_full_name, :boolean
    field :email, :string
  end

  input_object :update_user_params do
    field :name, :string
    field :class, :string
    field :nickname, :string
    field :hide_full_name, :boolean
    field :avatar_image_file, :select_file_input
    field :enrollment_tokens, list_of(:string)
  end

  input_object :select_user_input do
    field :id, :id
  end

  object :authresult do
    field :access_token, :string
    field :refresh_token, :string
  end

  object :user do
    field :id, :id
    field :inserted_at, :datetime
    field :updated_at, :datetime
    field :last_seen, :datetime, resolve: &LottaWeb.UserResolver.resolve_last_seen/3
    field :name, :string, resolve: &LottaWeb.UserResolver.resolve_name/3
    field :class, :string
    field :nickname, :string
    field :email, :string, resolve: &LottaWeb.UserResolver.resolve_email/3
    field :hide_full_name, :boolean
    field :has_changed_default_password, :boolean

    field :unread_messages, :integer, resolve: &LottaWeb.UserResolver.resolve_unread_messages/3

    field :avatar_image_file, :file,
      resolve: Absinthe.Resolution.Helpers.dataloader(Lotta.Storage)

    field :articles, list_of(:article),
      resolve: Absinthe.Resolution.Helpers.dataloader(Lotta.Content)

    field :groups, list_of(:user_group), resolve: &LottaWeb.UserResolver.resolve_groups/3

    field :assigned_groups, list_of(:user_group),
      resolve: &LottaWeb.UserResolver.resolve_assigned_groups/3

    field :enrollment_tokens, list_of(:string),
      resolve: &LottaWeb.UserResolver.resolve_enrollment_tokens/3
  end
end
