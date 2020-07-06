defmodule Api.SearchResolverTest do
  @moduledoc """
    Test Module for SearchResolver
  """

  use ApiWeb.ConnCase
  alias Api.Content

  setup do
    Api.Repo.Seeder.seed()
    Elasticsearch.delete(Api.Elasticsearch.Cluster, "*")
    :timer.sleep(200)
    Elasticsearch.Index.hot_swap(Api.Elasticsearch.Cluster, "articles")

    web_tenant = Api.Tenants.get_tenant_by_slug!("web")
    admin = Api.Repo.get_by!(Api.Accounts.User, email: "alexis.rinaldoni@lotta.schule")
    lehrer = Api.Repo.get_by!(Api.Accounts.User, email: "eike.wiewiorra@lotta.schule")
    user = Api.Repo.get_by!(Api.Accounts.User, email: "doro@lotta.schule")

    {:ok, admin_jwt, _} =
      Api.Guardian.encode_and_sign(admin, %{email: admin.email, name: admin.name})

    {:ok, lehrer_jwt, _} =
      Api.Guardian.encode_and_sign(lehrer, %{email: lehrer.email, name: lehrer.name})

    {:ok, user_jwt, _} = Api.Guardian.encode_and_sign(user, %{email: user.email, name: user.name})

    {:ok,
     %{
       web_tenant: web_tenant,
       admin_account: admin,
       admin_jwt: admin_jwt,
       lehrer_account: lehrer,
       lehrer_jwt: lehrer_jwt,
       user_account: user,
       user_jwt: user_jwt
     }}
  end

  describe "search query" do
    @query """
    query Search($searchText: String!){
      search(searchText: $searchText) {
        title
        preview
      }
    }
    """

    test "search for public articles should return them" do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> get("/api", query: @query, variables: %{searchText: "Nipple Jesus"})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "search" => [
                   %{
                     "preview" =>
                       "Das Theaterstück „Nipple Jesus“, welches am 08.02.2019 im Museum der Bildenden Künste aufgeführt wurde, hat bei mir noch lange nach der Aufführung große Aufmerksamkeit hinterlassen.",
                     "title" => "„Nipple Jesus“- eine extreme Erfahrung"
                   },
                   %{"preview" => "Hallo hallo hallo", "title" => "And the oskar goes to ..."},
                   %{
                     "preview" =>
                       "Zweimal Silber für die Mannschaften des Christian-Gottfried-Ehrenberg-Gymnasium Delitzsch beim Landesfinale \"Jugend trainiert für Europa\" im Volleyball. Nach beherztem Kampf im Finale unterlegen ...",
                     "title" => "Landesfinale Volleyball WK IV"
                   },
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 1"},
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 2"},
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 3"}
                 ]
               }
             }
    end

    test "search for restricted articles should not returne them when user is not in the right group",
         %{user_jwt: user_jwt} do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> get("/api",
          query: @query,
          variables: %{
            searchText:
              "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten."
          }
        )
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "search" => [
                   %{"preview" => "Hallo hallo hallo", "title" => "And the oskar goes to ..."},
                   %{
                     "preview" =>
                       "Zweimal Silber für die Mannschaften des Christian-Gottfried-Ehrenberg-Gymnasium Delitzsch beim Landesfinale \"Jugend trainiert für Europa\" im Volleyball. Nach beherztem Kampf im Finale unterlegen ...",
                     "title" => "Landesfinale Volleyball WK IV"
                   },
                   %{
                     "preview" =>
                       "Das Theaterstück „Nipple Jesus“, welches am 08.02.2019 im Museum der Bildenden Künste aufgeführt wurde, hat bei mir noch lange nach der Aufführung große Aufmerksamkeit hinterlassen.",
                     "title" => "„Nipple Jesus“- eine extreme Erfahrung"
                   },
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 1"},
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 2"},
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 3"}
                 ]
               }
             }
    end

    test "search for a restricted article should be returned when user is in the right groupe", %{
      lehrer_jwt: lehrer_jwt
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
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

    test "search for a restricted article should be returned when user is admin", %{
      admin_jwt: admin_jwt
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api",
          query: @query,
          variables: %{
            searchText:
              "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten."
          }
        )
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "search" => [
                   %{
                     "preview" =>
                       "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten. Wir beglückwünschen die Sieger und haben unseren Sieger gesondert gefeiert.",
                     "title" => "Der Podcast zum WB 2"
                   },
                   %{"preview" => "Hallo hallo hallo", "title" => "And the oskar goes to ..."},
                   %{
                     "preview" =>
                       "Zweimal Silber für die Mannschaften des Christian-Gottfried-Ehrenberg-Gymnasium Delitzsch beim Landesfinale \"Jugend trainiert für Europa\" im Volleyball. Nach beherztem Kampf im Finale unterlegen ...",
                     "title" => "Landesfinale Volleyball WK IV"
                   },
                   %{
                     "preview" =>
                       "Singen, Schauspielern, Instrumente Spielen - Die Kerndisziplinen von Klienkunst waren auch diese Jahr beim Vorausscheid am 14. Februar vertreten. Wir mischten uns unter die Kandidaten, Techniker und die Jury.",
                     "title" => "Der Vorausscheid"
                   },
                   %{
                     "preview" =>
                       "Das Theaterstück „Nipple Jesus“, welches am 08.02.2019 im Museum der Bildenden Künste aufgeführt wurde, hat bei mir noch lange nach der Aufführung große Aufmerksamkeit hinterlassen.",
                     "title" => "„Nipple Jesus“- eine extreme Erfahrung"
                   },
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 1"},
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 2"},
                   %{"preview" => "Lorem ipsum dolor sit amet.", "title" => "Beitrag Projekt 3"},
                   %{
                     "preview" => "Lorem ipsum dolor sit amet.",
                     "title" => "Beitrag Projekt 4 - nur für Lehrer"
                   },
                   %{
                     "preview" => "Lorem ipsum dolor sit amet.",
                     "title" => "Beitrag Projekt 4 - nur für Schüler"
                   },
                   %{
                     "preview" => "Lorem ipsum dolor sit amet.",
                     "title" => "Beitrag Projekt 5 - nur für Lehrer"
                   },
                   %{
                     "preview" => "Lorem ipsum dolor sit amet.",
                     "title" => "Beitrag Projekt 5 - nur für Schüler"
                   }
                 ]
               }
             }
    end

    test "updated article should be indexed" do
      {:ok, article} =
        Api.Content.Article
        |> Api.Repo.get_by!(title: "Beitrag Projekt 1")
        |> Content.update_article(%{title: "Neuer Artikel nur für die Suche"})

      {:ok, %{"_source" => %{"title" => title}}} =
        Elasticsearch.get(Api.Elasticsearch.Cluster, "/articles/_doc/#{article.id}")

      assert title == "Neuer Artikel nur für die Suche"
    end

    test "deleted article should be deleted from index" do
      {:ok, %{id: id}} =
        Api.Content.Article
        |> Api.Repo.get_by!(title: "Beitrag Projekt 1")
        |> Content.delete_article()

      {result, _} = Elasticsearch.get(Api.Elasticsearch.Cluster, "/articles/_doc/#{id}")

      assert result == :error
    end
  end
end