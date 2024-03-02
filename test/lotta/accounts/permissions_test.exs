defmodule Lotta.Accounts.PermissionsTest do
  @moduledoc false

  use Lotta.DataCase

  import Lotta.Accounts.Permissions

  alias Lotta.Accounts.{User, UserGroup}
  alias Lotta.Content.Article

  @prefix "tenant_test"

  setup do
    # And this is a big TODO!
    # I did not know better when I wrote this, but the import from
    # LottaWeb really is not a good idea. I think we should find another
    # way around caching these values, one that belongs into the same context
    # and which we do not rely on being there despite being from somewhere else.

    admin =
      from(u in User, where: u.email == ^"alexis.rinaldoni@lotta.schule")
      |> Repo.one!(prefix: @prefix)
      # This should be superfluous
      |> LottaWeb.Context.set_virtual_user_fields()

    lehrer =
      from(u in User, where: u.email == ^"eike.wiewiorra@lotta.schule")
      |> Repo.one!(prefix: @prefix)
      # This should be superfluous
      |> LottaWeb.Context.set_virtual_user_fields()

    schueler =
      from(u in User, where: u.email == ^"billy@lotta.schule")
      |> Repo.one!(prefix: @prefix)
      # This should be superfluous
      |> LottaWeb.Context.set_virtual_user_fields()

    eike_article =
      from(a in Article, where: a.title == "And the oskar goes to ...")
      |> Repo.one!(prefix: @prefix)

    lehrer_article =
      from(a in Article, where: a.title == "Der Vorausscheid")
      |> Repo.one!(prefix: @prefix)

    admin_group =
      from(g in UserGroup, where: g.name == "Administration") |> Repo.one!(prefix: @prefix)

    lehrer_group = from(g in UserGroup, where: g.name == "Lehrer") |> Repo.one!(prefix: @prefix)

    schueler_group =
      from(g in UserGroup, where: g.name == "Schüler") |> Repo.one!(prefix: @prefix)

    {:ok,
     %{
       admin: admin,
       lehrer: lehrer,
       schueler: schueler,
       eike_article: eike_article,
       lehrer_article: lehrer_article,
       admin_group: admin_group,
       lehrer_group: lehrer_group,
       schueler_group: schueler_group
     }}
  end

  describe "Permissions: articles" do
    test "is_author?/2", %{
      eike_article: article,
      lehrer_article: lehrer_article,
      admin: admin,
      lehrer: lehrer,
      schueler: schueler
    } do
      # Eike ist author of the article
      assert not is_author?(admin, article)
      assert is_author?(lehrer, article)
      assert not is_author?(schueler, article)

      # No one is author of the article
      assert not is_author?(admin, lehrer_article)
      assert not is_author?(lehrer, lehrer_article)
      assert not is_author?(lehrer, lehrer_article)
    end

    test "user can write?/2 his own article", %{lehrer: lehrer, eike_article: article} do
      assert can_write?(lehrer, article)
    end

    test "user cannot write?/2 someone else's article", %{
      schueler: schueler,
      eike_article: article
    } do
      assert not can_write?(schueler, article)
    end

    test "admin can write?/2 someone else's article", %{admin: admin, eike_article: article} do
      assert can_write?(admin, article)
    end

    test "user cannot write?/2 an article which is targeted at his group", %{
      lehrer: lehrer,
      lehrer_article: article
    } do
      assert not can_write?(lehrer, article)
    end

    test "lehrer can read?/2 his own published article", %{lehrer: lehrer, eike_article: article} do
      assert can_read?(lehrer, article)
    end

    test "lehrer can read?/2 his own unpublished article", %{
      lehrer: lehrer,
      eike_article: article
    } do
      assert can_read?(lehrer, Map.put(article, :published, false))
    end

    test "admin can read?/2 user's published article", %{admin: admin, eike_article: article} do
      assert can_read?(admin, article)
    end

    test "admin can read?/2 user's unpublished article", %{admin: admin, eike_article: article} do
      assert can_read?(admin, Map.put(article, :published, false))
    end

    test "schueler can read?/2 lehrers published article", %{
      schueler: schueler,
      eike_article: article
    } do
      assert can_read?(schueler, article)
    end

    test "schueler cannot read?/2 lehrers unpublished article", %{
      schueler: schueler,
      eike_article: article
    } do
      assert not can_read?(schueler, Map.put(article, :published, false))
    end

    test "lehrer can read?/2 article published for lehrer-group", %{
      lehrer: lehrer,
      lehrer_article: article
    } do
      assert can_read?(lehrer, article)
    end

    test "lehrer cannot read?/2 unpublished article for lehrer-group", %{
      lehrer: lehrer,
      lehrer_article: article
    } do
      assert not can_read?(lehrer, Map.put(article, :published, false))
    end

    test "schueler cannot read?/2 article published for lehrer-group", %{
      schueler: schueler,
      lehrer_article: article
    } do
      assert not can_read?(schueler, article)
    end

    test "schueler cannot read?/2 article unpublished article for lehrer-group", %{
      schueler: schueler,
      lehrer_article: article
    } do
      assert not can_read?(schueler, Map.put(article, :published, false))
    end
  end

  describe "Permissions" do
    test "user_is_in_groups_list?/2", %{
      admin: admin,
      lehrer: lehrer,
      schueler: schueler,
      admin_group: admin_group,
      lehrer_group: lehrer_group,
      schueler_group: schueler_group
    } do
      assert user_is_in_groups_list?(admin, [admin_group, lehrer_group])
      assert user_is_in_groups_list?(lehrer, [lehrer_group])
      assert user_is_in_groups_list?(schueler, [schueler_group])
      assert not user_is_in_groups_list?(lehrer, [admin_group])
      assert not user_is_in_groups_list?(schueler, [lehrer_group])
    end
  end
end
