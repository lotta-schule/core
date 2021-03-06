defmodule LottaWeb.Schema.Middleware.EnsureUserIsAuthenticated do
  @moduledoc false

  @behaviour Absinthe.Middleware

  alias LottaWeb.Context

  @doc false

  def call(
        %{context: %Context{current_user: %{id: _id}}} = resolution,
        _config
      ),
      do: resolution

  def call(resolution, _config) do
    resolution
    |> Absinthe.Resolution.put_result({:error, "Du musst angemeldet sein um das zu tun."})
  end
end
