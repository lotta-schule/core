defmodule Lotta.Accounts.Permissions do
  @moduledoc """
  This module provides methods helping finding if a user has certain permissions.
  """

  alias Lotta.Repo
  alias Lotta.Accounts.{User, UserGroup}
  alias Lotta.Storage.{Directory, File}
  alias Lotta.Messages.{Conversation, Message}
  alias Lotta.Content.Article

  @doc """
  Wether a given user is an author or the author of a given article, directory or file

  Returns true or false
  """
  @doc since: "2.0.0"

  @spec author?(User.t(), Article.t() | Directory.t() | File.t() | Message.t()) :: boolean

  def author?(%User{} = user, %Article{} = article) do
    article
    |> Repo.preload(:users)
    |> Map.get(:users)
    |> Enum.any?(fn u -> u.id == user.id end)
  end

  def author?(%User{id: user_id}, %Directory{} = directory) do
    user_id == directory.user_id
  end

  def author?(%User{id: user_id}, %File{} = file) do
    user_id == file.user_id
  end

  def author?(%User{id: user_id}, %Message{} = message) do
    user_id == message.user_id
  end

  def author?(nil, _), do: false

  @doc """
  Wether a given user has read-access to a given object.
  """
  @doc since: "2.2.0"
  @spec can_read?(User.t() | nil, Article.t() | Directory.t() | Conversation.t()) :: boolean()
  def can_read?(user, object)

  def can_read?(user, %Article{} = article) do
    can_write?(user, article) ||
      (fn ->
         groups =
           article
           |> Repo.preload(:groups)
           |> Map.get(:groups, [])

         Enum.empty?(groups) || user_is_in_groups_list?(user, groups)
       end).()
  end

  def can_read?(user, %Directory{} = directory) do
    author?(user, directory) || is_nil(directory.user_id)
  end

  def can_read?(user, %File{} = file) do
    file =
      file
      |> Repo.preload(:parent_directory)

    author?(user, file) || can_read?(user, file.parent_directory)
  end

  def can_read?(user, %Conversation{} = conversation) do
    conversation = Repo.preload(conversation, [:users, :groups])

    Enum.any?(conversation.users, &(&1.id == user.id)) ||
      user_is_in_groups_list?(user, conversation.groups)
  end

  @doc """
  Wether a given user has write-access to a given object.
  """
  @doc since: "2.2.0"
  @spec can_write?(User.t(), Article.t() | Directory.t()) :: boolean()
  def can_write?(user, object)

  def can_write?(%User{is_admin?: true}, %Article{}), do: true
  def can_write?(%User{} = user, %Article{} = article), do: author?(user, article)

  def can_write?(%User{} = user, %Directory{} = directory) do
    author?(user, directory) || (user.is_admin? && is_nil(directory.user_id))
  end

  def can_write?(user, %File{} = file) do
    file =
      file
      |> Repo.preload(:parent_directory)

    author?(user, file) || can_write?(user, file.parent_directory)
  end

  def can_write?(nil, _target), do: false

  @doc """
  Wether a given user is member in a given set of groups or group ids.

  Returns true or false
  """
  @doc since: "2.2.0"

  @spec user_is_in_groups_list?(User.t() | nil, [UserGroup.t() | pos_integer()]) :: boolean

  def user_is_in_groups_list?(%User{all_groups: user_groups}, groups) when length(groups) > 0 do
    user_group_ids =
      user_groups
      |> Enum.map(& &1.id)

    groups
    |> Enum.map(fn
      %UserGroup{id: id} ->
        id

      assume_id when is_bitstring(assume_id) ->
        String.to_integer(assume_id)

      assume_id ->
        assume_id
    end)
    |> Enum.any?(&Enum.member?(user_group_ids, &1))
  end

  def user_is_in_groups_list?(_, _), do: false
end
