defmodule LottaWeb.SearchResolverTest do
  @moduledoc false

  use LottaWeb.ConnCase

  import Ecto.Query

  alias LottaWeb.Auth.AccessToken
  alias Lotta.{Content, Repo, Tenants}
  alias Lotta.Accounts.User
  alias Lotta.Content.Article
  alias Lotta.Elasticsearch.Cluster
  alias Lotta.Tenants.Category

  @prefix "tenant_test"

  setup do
    tenant = Tenants.get_tenant_by_prefix(@prefix)

    Elasticsearch.delete(Cluster, "*")
    :timer.sleep(500)
    Elasticsearch.Index.hot_swap(Cluster, "articles")
    :timer.sleep(500)

    admin =
      Repo.one!(
        from(u in User, where: u.email == ^"alexis.rinaldoni@lotta.schule"),
        prefix: @prefix
      )

    lehrer =
      Repo.one!(
        from(u in User, where: u.email == ^"eike.wiewiorra@lotta.schule"),
        prefix: @prefix
      )

    user =
      Repo.one!(
        from(u in User, where: u.email == ^"doro@lotta.schule"),
        prefix: @prefix
      )

    article =
      Repo.one!(
        from(a in Article,
          where: a.title == ^"Beitrag Projekt 1"
        ),
        prefix: @prefix
      )

    {:ok, admin_jwt, _} = AccessToken.encode_and_sign(admin)

    {:ok, lehrer_jwt, _} = AccessToken.encode_and_sign(lehrer)

    {:ok, user_jwt, _} = AccessToken.encode_and_sign(user)

    {:ok,
     %{
       admin_account: admin,
       admin_jwt: admin_jwt,
       lehrer_account: lehrer,
       lehrer_jwt: lehrer_jwt,
       user_account: user,
       user_jwt: user_jwt,
       article: article,
       tenant: tenant
     }}
  end

  describe "search query" do
    @query """
    query Search($searchText: String!, $options: SearchOptions){
      search(searchText: $searchText, options: $options) {
        title
        preview
      }
    }
    """

    test "search for public articles should return them" do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:test")
        |> get("/api", query: @query, variables: %{searchText: "Nipple Jesus"})
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => results
               }
             } = res

      assert Enum.any?(
               results,
               &(Map.get(&1, "title") == "???Nipple Jesus???- eine extreme Erfahrung")
             )
    end

    test "search for restricted articles should not return them when user is not in the right group",
         %{user_jwt: user_jwt} do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:test")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> get("/api",
          query: @query,
          variables: %{
            searchText:
              "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten."
          }
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => results
               }
             } = res

      refute Enum.any?(
               results,
               &(Map.get(&1, "title") == "Der Podcast zum WB 2")
             )
    end

    test "search for a restricted article should list it in reuslts when user is in the right groupe",
         %{
           lehrer_jwt: lehrer_jwt
         } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:test")
        |> put_req_header("authorization", "Bearer #{lehrer_jwt}")
        |> get("/api",
          query: @query,
          variables: %{
            searchText:
              "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten."
          }
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => results
               }
             } = res

      assert Enum.any?(results, fn %{"title" => title} -> title == "Der Podcast zum WB 2" end)
    end

    test "search for a restricted article should list it in results when user is admin", %{
      admin_jwt: admin_jwt
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:test")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api",
          query: @query,
          variables: %{
            searchText:
              "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten."
          }
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => searchresults
               }
             } = res

      assert Enum.any?(searchresults, fn result ->
               result == %{
                 "preview" =>
                   "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten. Wir begl??ckw??nschen die Sieger und haben unseren Sieger gesondert gefeiert.",
                 "title" => "Der Podcast zum WB 2"
               }
             end)
    end

    test "search restricted to category should only list results from that category", %{
      admin_jwt: jwt,
      tenant: t
    } do
      category =
        Repo.one!(
          from(c in Category,
            where: c.title == ^"Projekt"
          ),
          prefix: t.prefix
        )

      res =
        build_conn()
        |> put_req_header("tenant", "slug:test")
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> get("/api",
          query: @query,
          variables: %{
            searchText: "Vorausscheid Kunst",
            options: %{category_id: category.id}
          }
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => results
               }
             } = res

      assert Enum.all?(results, fn %{"title" => title} ->
               article =
                 Repo.one!(
                   from(a in Article, where: a.title == ^title),
                   prefix: t.prefix
                 )

               article.category_id == category.id
             end)
    end

    test "passing category_id: null to config should be valid" do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:test")
        |> get("/api",
          query: @query,
          variables: %{
            searchText: "Nipple Jesus",
            options: %{category_id: nil}
          }
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => results
               }
             } = res

      assert Enum.any?(
               results,
               &(Map.get(&1, "title") == "???Nipple Jesus???- eine extreme Erfahrung")
             )
    end

    test "updated article should be indexed", %{tenant: t, article: article} do
      Content.update_article(article, %{title: "Neuer Artikel nur f??r die Suche"})

      {:ok, %{"_source" => %{"title" => title}}} =
        Elasticsearch.get(Cluster, "/articles/_doc/#{t.id}--#{article.id}")

      assert title == "Neuer Artikel nur f??r die Suche"
    end

    test "deleted article should be deleted from index", %{tenant: t, article: article} do
      Content.delete_article(article)

      {result, _} = Elasticsearch.get(Cluster, "/articles/_doc/#{t.id}--#{article.id}")

      assert result == :error
    end
  end
end
