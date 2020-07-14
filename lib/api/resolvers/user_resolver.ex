defmodule Api.UserResolver do
  @moduledoc """
  GraphQL Resolver Module for finding, updating and deleting users.
  Takes care of login and registration, as well as password recovery functionality.
  """

  require Logger

  alias Api.Repo
  alias Ecto.NoResultsError
  alias Api.Accounts
  alias Api.Accounts.{AuthHelper, User}
  alias Api.Queue.EmailPublisher
  alias ApiWeb.ErrorHelpers

  def resolve_name(user, _args, %{context: context}) do
    cond do
      context[:current_user] && context.current_user.id == user.id ->
        {:ok, user.name}

      context[:current_user] && context[:tenant] &&
          User.is_admin?(context.current_user, context.tenant) ->
        {:ok, user.name}

      user.hide_full_name ->
        {:ok, user.name}

      true ->
        {:ok, nil}
    end
  end

  def resolve_email(user, _args, %{context: context}) do
    cond do
      context[:current_user] && context.current_user.id == String.to_integer(user.id) ->
        {:ok, user.email}

      context[:current_user] && context[:tenant] &&
          User.is_admin?(context.current_user, context.tenant) ->
        {:ok, user.email}

      true ->
        {:error, "Die Email des Nutzers ist geheim."}
    end
  end

  def resolve_is_blocked(user, _args, %{context: %{tenant: tenant}}) do
    {:ok, User.is_blocked?(user, tenant)}
  end

  def resolve_is_blocked(_user, _args, _context), do: {:ok, false}

  def get_current(_args, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end

  def get_current(_args, _info) do
    {:ok, nil}
  end

  def resolve_groups(user, _args, %{context: %{tenant: tenant}}) do
    {:ok, User.get_groups(user, tenant)}
  end

  def resolve_groups(user, _args, _context), do: {:ok, User.get_groups(user)}

  def resolve_assigned_groups(user, _args, %{context: %{tenant: tenant}}) do
    {:ok, User.get_assigned_groups(user, tenant)}
  end

  def resolve_enrollment_tokens(user, _args, _info) do
    user = Repo.preload(user, :enrollment_tokens)

    tokens =
      user.enrollment_tokens
      |> Enum.map(& &1.enrollment_token)

    {:ok, tokens}
  end

  def all_with_groups(_args, %{context: %{tenant: tenant} = context}) do
    case context[:current_user] && User.is_admin?(context.current_user, tenant) do
      true -> {:ok, Accounts.list_users_with_groups(tenant.id)}
      _ -> {:error, "Nur Administrator dürfen auf Benutzer auflisten."}
    end
  end

  def search(%{searchtext: searchtext}, %{context: %{tenant: tenant} = context}) do
    cond do
      !context[:current_user] || !User.is_admin?(context.current_user, tenant) ->
        {:error, "Nur Administrator dürfen auf Benutzer auflisten."}

      String.length(searchtext) >= 2 ->
        Accounts.search_user(searchtext, tenant)

      true ->
        {:ok, []}
    end
  end

  def get(%{id: id}, %{context: %{tenant: tenant} = context}) do
    if context[:current_user] && User.is_admin?(context.current_user, tenant) do
      try do
        {:ok, Accounts.get_user!(String.to_integer(id))}
      rescue
        NoResultsError -> {:ok, nil}
      end
    else
      {:error, "Nur Administrator dürfen auf Benutzer auflisten."}
    end
  end

  def register(%{user: user_params} = args, %{context: context}) do
    user_params =
      case context do
        %{tenant: tenant} ->
          user_params
          |> Map.put(:tenant_id, tenant.id)
          |> Map.put(
            :enrollment_tokens,
            case args do
              %{group_key: group_key} -> [group_key]
              _ -> []
            end
          )

        _ ->
          user_params
      end

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        case context do
          %{tenant: tenant} ->
            EmailPublisher.send_registration_email(tenant, user)

          _ ->
            EmailPublisher.send_registration_email(user)
        end

        {:ok, %{sign_in_user: user}}

      {:error, error} ->
        {:error,
         [
           message: "Registrierung fehlgeschlagen.",
           details: ErrorHelpers.extract_error_details(error)
         ]}
    end
  end

  def login(%{username: username, password: password}, %{context: %{tenant: tenant}}) do
    with {:ok, user} <- AuthHelper.login_with_username_pass(username, password),
         :ok <- AuthHelper.check_if_blocked(user, tenant) do
      {:ok, %{sign_in_user: user}}
    end
  end

  def login(%{username: username, password: password}, _info) do
    case AuthHelper.login_with_username_pass(username, password) do
      {:ok, user} ->
        {:ok, %{sign_in_user: user}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def logout(_args, _info) do
    {:ok, %{sign_out_user: true}}
  end

  def request_password_reset(%{email: email}, %{context: %{tenant: tenant}}) do
    token =
      :crypto.strong_rand_bytes(32)
      |> Base.url_encode64(padding: false)
      |> URI.encode()

    case Accounts.request_password_reset_token(email, token) do
      {:ok, user} ->
        Logger.info("user request password request - send mail to #{email}")
        EmailPublisher.send_request_password_reset_email(tenant, user, email, token)

      error ->
        try do
          Honeybadger.notify(error, %{tenant: tenant, email: email})
          Logger.error("Error setting request password reset token")
          Logger.error(inspect(error))
        rescue
          e in RuntimeError ->
            Logger.error(inspect(e))
        end
    end

    {:ok, true}
  end

  def reset_password(%{email: email, token: token, password: password}, _info) do
    with {:ok, user} <- Accounts.find_user_by_reset_token(email, token),
         {:ok, user} <- Accounts.update_password(user, password) do
      {:ok, %{sign_in_user: user}}
    else
      error ->
        if error, do: Logger.warn(inspect(error))
        {:error, "Die Seite ist nicht mehr gültig. Starte den Vorgang erneut."}
    end
  end

  def set_user_groups(%{id: id, group_ids: group_ids}, %{
        context: %{current_user: current_user, tenant: tenant}
      }) do
    case User.is_admin?(current_user, tenant) do
      true ->
        groups =
          group_ids
          |> Enum.map(fn group_id ->
            try do
              Accounts.get_user_group!(String.to_integer(group_id))
            rescue
              NoResultsError -> nil
            end
          end)
          |> Enum.filter(fn group -> !is_nil(group) && group.tenant_id == tenant.id end)

        try do
          Accounts.get_user!(String.to_integer(id))
          |> Accounts.set_user_groups(tenant, groups)
        rescue
          NoResultsError ->
            {:error, "Nutzer mit der id #{id} nicht gefunden."}
        end

      false ->
        {:error, "Nur Administratoren dürfen Benutzern Gruppen zuweisen."}
    end
  end

  def update_profile(%{user: user_params}, %{context: %{current_user: current_user}}) do
    case Accounts.update_user(current_user, user_params) do
      {:ok, user} ->
        {:ok, user}

      {:error, error} ->
        {:error,
         [
           message: "Speichern fehlgeschlagen.",
           details: ErrorHelpers.extract_error_details(error)
         ]}
    end
  end

  def update_profile(_args, _info), do: {:error, "Du bist nicht angemeldet."}

  def update_password(%{current_password: password, new_password: new_password}, %{
        context: %{current_user: %{email: email}}
      }) do
    with {:ok, user} <- AuthHelper.login_with_username_pass(email, password),
         {:ok, user} <- Accounts.update_password(user, new_password) do
      {:ok, user}
    else
      {:error, message} when is_binary(message) ->
        {:error, message}

      {:error, error} ->
        {:error,
         [
           message: "Passwort ändern fehlgeschlagen.",
           details: ErrorHelpers.extract_error_details(error)
         ]}
    end
  end

  def set_user_blocked(%{id: id, is_blocked: is_blocked}, %{context: %{tenant: tenant} = context}) do
    case context[:current_user] && User.is_admin?(context.current_user, tenant) do
      true ->
        try do
          Accounts.get_user!(String.to_integer(id))
          |> Accounts.set_user_blocked(tenant, is_blocked)
        rescue
          NoResultsError ->
            {:error, "Nutzer mit der id #{id} nicht gefunden."}
        end

      false ->
        {:error, "Nur Administratoren dürfen Benutzer blocken."}
    end
  end
end
