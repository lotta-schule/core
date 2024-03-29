defmodule Lotta.Repo do
  use Ecto.Repo,
    otp_app: :lotta,
    adapter: Ecto.Adapters.Postgres

  @dialyzer {:nowarn_function, rollback: 1}

  @impl true
  def prepare_query(_operation, query, opts) do
    prefix = get_prefix()

    if opts[:prefix] || is_nil(prefix) do
      {query, opts}
    else
      {query, Keyword.put(opts, :prefix, prefix)}
    end
  end

  def build_prefixed_assoc(%{__struct__: _schema} = struct, assoc, attributes \\ %{}) do
    Ecto.put_meta(
      Ecto.build_assoc(struct, assoc, attributes),
      prefix: Ecto.get_meta(struct, :prefix)
    )
  end

  def put_prefix(prefix) do
    Process.put(:current_tenant_prefix, prefix)
  end

  def get_prefix() do
    Process.get(:current_tenant_prefix)
  end

  def with_new_dynamic_repo(fun) do
    config =
      Application.get_env(:lotta, __MODULE__)
      |> Keyword.put(:name, nil)
      |> Keyword.put(:pool_size, 2)
      |> Keyword.delete(:pool)

    {:ok, pid} = start_link(config)

    try do
      put_dynamic_repo(pid)
      fun.(pid)
    after
      stop(1000)
      put_dynamic_repo(Repo)
    end
  end
end
