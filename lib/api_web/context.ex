defmodule ApiWeb.Context do
  @behaviour Plug

  import Plug.Conn

  alias Api.{Guardian, Accounts, Tenants, Repo}

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    %{context: Map.merge(
      get_user_context(conn),
      get_tenant_context(conn)
    )}
  end

  defp get_user_context(conn) do
    authorization_header = get_req_header(conn, "authorization")
    with ["Bearer " <> token] <- authorization_header do
      {:ok, current_user, _claims} = Guardian.resource_from_token(token)
      %{
        current_user: Repo.get(Accounts.User, current_user.id)
          |> Repo.preload([:groups, :avatar_image_file])
      }
    else
      _ -> %{}
    end
  end

  defp get_tenant_context(conn) do
    tenant_header = get_req_header(conn, "tenant")
    with ["slug:" <> slug] <- tenant_header do
      %{tenant: Tenants.get_tenant_by_slug!(slug)}
    else
      _ -> Tenants.get_tenant_by_slug!("ehrenberg") # TODO: remove this aweful hard-coded string. Add Domain support
    end
  end
end