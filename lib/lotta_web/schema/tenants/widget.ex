defmodule LottaWeb.Schema.Tenants.Widget do
  @moduledoc false

  use Absinthe.Schema.Notation

  enum :widget_type do
    value(:calendar, as: "calendar")
    value(:schedule, as: "schedule")
    value(:tagcloud, as: "tagcloud")
    value(:iframe, as: "iframe")
  end

  object :widget do
    field :id, :id
    field :title, :string
    field :type, :widget_type
    field :configuration, :json

    field :icon_image_file, :file, resolve: Absinthe.Resolution.Helpers.dataloader(Lotta.Storage)

    field :groups, list_of(:user_group),
      resolve: &LottaWeb.UserGroupResolver.resolve_model_groups/2
  end

  input_object :widget_input do
    field :title, non_null(:string)
    field :groups, list_of(:select_user_group_input)
    field :icon_image_file, :select_file_input
    field :configuration, :json
  end

  input_object :select_widget_input do
    field :id, :id
  end
end
